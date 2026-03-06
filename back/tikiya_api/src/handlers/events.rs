use axum::{
    extract::{Path, State},
    Json,
};
use chrono::DateTime;
use uuid::Uuid;
use validator::Validate;

use crate::dto::{CreateEventRequest, UpdateEventRequest, EventResponse};
use crate::error::ApiError;
use crate::models::Event;
use crate::security::AuthUser;
use crate::state::AppState;

// ─── Handlers ─────────────────────────────────────────────────────────────────

/// GET /events  — tous les événements (public, pour les participants)
pub async fn list_all(
    State(state): State<AppState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Result<Json<Vec<EventResponse>>, ApiError> {
    let limit: i64 = params
        .get("limit")
        .and_then(|v| v.parse().ok())
        .unwrap_or(50)
        .min(200);
    let offset: i64 = params
        .get("page")
        .and_then(|v| v.parse::<i64>().ok())
        .unwrap_or(0)
        .max(0)
        * limit;

    let rows = if let Some(cat) = params.get("category") {
        sqlx::query_as::<_, Event>(
            "SELECT * FROM events WHERE category = $1 ORDER BY event_date ASC LIMIT $2 OFFSET $3",
        )
        .bind(cat)
        .bind(limit)
        .bind(offset)
        .fetch_all(&state.db.pool)
        .await?
    } else {
        sqlx::query_as::<_, Event>(
            "SELECT * FROM events ORDER BY event_date ASC LIMIT $1 OFFSET $2",
        )
        .bind(limit)
        .bind(offset)
        .fetch_all(&state.db.pool)
        .await?
    };

    Ok(Json(rows.into_iter().map(EventResponse::from).collect()))
}

/// GET /events/my  — événements de l'organisateur connecté
pub async fn list_mine(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<EventResponse>>, ApiError> {
    let user_id = auth.user_id;

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
    auth: AuthUser,
    Json(payload): Json<CreateEventRequest>,
) -> Result<Json<EventResponse>, ApiError> {
    let user_id = auth.user_id;

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
            (organizer_id, title, description, location, event_date, price, capacity, cover_url, category)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
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
    .bind(payload.category.as_deref().unwrap_or("musique"))
    .fetch_one(&state.db.pool)
    .await?;

    tracing::info!(event_id = %event.id, organizer_id = %user_id, "event.created");
    Ok(Json(EventResponse::from(event)))
}

/// DELETE /events/:id  — supprimer son événement
pub async fn delete_event(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(event_id): Path<Uuid>,
) -> Result<(), ApiError> {
    let user_id = auth.user_id;

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

/// PUT /events/:id  — modifier son événement
pub async fn update_event(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(event_id): Path<Uuid>,
    Json(payload): Json<UpdateEventRequest>,
) -> Result<Json<EventResponse>, ApiError> {
    let user_id = auth.user_id;

    payload.validate().map_err(|e| ApiError::Validation(e.to_string()))?;

    let event_date = DateTime::parse_from_rfc3339(&payload.event_date)
        .map_err(|_| ApiError::Validation("event_date must be RFC3339".into()))?
        .with_timezone(&chrono::Utc);

    let event = sqlx::query_as::<_, Event>(
        r#"UPDATE events SET
            title = $1,
            description = $2,
            location = $3,
            event_date = $4,
            price = $5,
            capacity = $6,
            cover_url = $7,
            category = $8
           WHERE id = $9 AND organizer_id = $10
           RETURNING *"#,
    )
    .bind(&payload.title)
    .bind(payload.description.as_deref().unwrap_or(""))
    .bind(payload.location.as_deref().unwrap_or(""))
    .bind(event_date)
    .bind(payload.price.unwrap_or(0.0))
    .bind(payload.capacity.unwrap_or(0))
    .bind(&payload.cover_url)
    .bind(payload.category.as_deref().unwrap_or("musique"))
    .bind(event_id)
    .bind(user_id)
    .fetch_optional(&state.db.pool)
    .await?
    .ok_or(ApiError::NotFound)?;

    tracing::info!(event_id = %event.id, "event.updated");
    Ok(Json(EventResponse::from(event)))
}
