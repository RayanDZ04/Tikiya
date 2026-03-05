use axum::{
    extract::{Path, State},
    http::HeaderMap,
    Json,
};
use chrono::DateTime;
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

use crate::dto::{CreateEventRequest, EventResponse};
use crate::error::ApiError;
use crate::models::Event;
use crate::state::AppState;

// ─── JWT extraction helper ────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
struct JwtClaims {
    sub: Uuid,
    #[serde(default)]
    email: String,
}

fn extract_user(headers: &HeaderMap, state: &AppState) -> Result<Uuid, ApiError> {
    let auth = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;
    let token = auth.strip_prefix("Bearer ").ok_or(ApiError::Unauthorized)?;
    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_audience(std::slice::from_ref(&state.config.jwt_audience));
    validation.set_issuer(std::slice::from_ref(&state.config.jwt_issuer));
    let data = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(state.config.jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|_| ApiError::Unauthorized)?;
    Ok(data.claims.sub)
}

// ─── Handlers ─────────────────────────────────────────────────────────────────

/// GET /events  — tous les événements (public, pour les participants)
pub async fn list_all(
    State(state): State<AppState>,
) -> Result<Json<Vec<EventResponse>>, ApiError> {
    let rows = sqlx::query_as::<_, Event>(
        "SELECT * FROM events ORDER BY event_date ASC",
    )
    .fetch_all(&state.db.pool)
    .await?;

    Ok(Json(rows.into_iter().map(EventResponse::from).collect()))
}

/// GET /events/my  — événements de l'organisateur connecté
pub async fn list_mine(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<Vec<EventResponse>>, ApiError> {
    let user_id = extract_user(&headers, &state)?;

    let rows = sqlx::query_as::<_, Event>(
        "SELECT * FROM events WHERE organizer_id = $1 ORDER BY event_date ASC",
    )
    .bind(user_id)
    .fetch_all(&state.db.pool)
    .await?;

    Ok(Json(rows.into_iter().map(EventResponse::from).collect()))
}

/// POST /events  — créer un événement (organisateur)
pub async fn create_event(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<CreateEventRequest>,
) -> Result<Json<EventResponse>, ApiError> {
    let user_id = extract_user(&headers, &state)?;

    payload.validate().map_err(|e| ApiError::Validation(e.to_string()))?;

    // Vérifie que l'utilisateur est bien organisateur
    #[derive(sqlx::FromRow)]
    struct RoleRow { role: String }
    let r = sqlx::query_as::<_, RoleRow>("SELECT role FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(&state.db.pool)
        .await?
        .ok_or(ApiError::Unauthorized)?;
    if r.role != "organisateur" {
        return Err(ApiError::Unauthorized);
    }

    let event_date = DateTime::parse_from_rfc3339(&payload.event_date)
        .map_err(|_| ApiError::Validation("event_date must be RFC3339".into()))?
        .with_timezone(&chrono::Utc);

    let event = sqlx::query_as::<_, Event>(
        r#"INSERT INTO events
            (organizer_id, title, description, location, event_date, price, capacity, cover_url)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
           RETURNING *"#,
    )
    .bind(user_id)
    .bind(&payload.title)
    .bind(payload.description.as_deref().unwrap_or(""))
    .bind(payload.location.as_deref().unwrap_or(""))
    .bind(event_date)
    .bind(payload.price.unwrap_or(0.0))
    .bind(payload.capacity.unwrap_or(0))
    .bind(&payload.cover_url)
    .fetch_one(&state.db.pool)
    .await?;

    tracing::info!(event_id = %event.id, organizer_id = %user_id, "event.created");
    Ok(Json(EventResponse::from(event)))
}

/// DELETE /events/:id  — supprimer son événement
pub async fn delete_event(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(event_id): Path<Uuid>,
) -> Result<(), ApiError> {
    let user_id = extract_user(&headers, &state)?;

    let result = sqlx::query(
        "DELETE FROM events WHERE id = $1 AND organizer_id = $2",
    )
    .bind(event_id)
    .bind(user_id)
    .execute(&state.db.pool)
    .await?;

    if result.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    Ok(())
}
