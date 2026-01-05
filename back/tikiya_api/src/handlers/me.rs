use axum::{extract::State, http::HeaderMap, Json};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::Deserialize;

use crate::{dto::UserResponse, error::ApiError, state::AppState};

#[derive(Debug, Deserialize)]
struct JwtClaims {
    sub: uuid::Uuid,
    _email: String,
    _exp: usize,
    _iat: usize,
    _aud: String,
    _iss: String,
}

pub async fn admin_me(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<UserResponse>, ApiError> {
    let auth = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;

    let token = auth.strip_prefix("Bearer ").ok_or(ApiError::Unauthorized)?;

    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_audience(std::slice::from_ref(&state.config.jwt_audience));
    validation.set_issuer(std::slice::from_ref(&state.config.jwt_issuer));

    let claims = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(state.config.jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|_| ApiError::Unauthorized)?
    .claims;

    // Load user and check role
    #[derive(sqlx::FromRow)]
    struct MeRow {
        id: uuid::Uuid,
        email: String,
        role: String,
        created_at: chrono::DateTime<chrono::Utc>,
    }

    let user = sqlx::query_as::<_, MeRow>(
        "SELECT id, email, role, created_at FROM users WHERE id = $1",
    )
    .bind(claims.sub)
    .fetch_one(&state.db.pool)
    .await?;

    if user.role != "admin" {
        return Err(ApiError::Unauthorized);
    }

    Ok(Json(UserResponse {
        id: user.id,
        email: user.email,
        role: user.role,
        created_at: user.created_at,
    }))
}
