use axum::{extract::State, http::HeaderMap, Json};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::Deserialize;

use crate::{error::ApiError, models::User, state::AppState};

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
) -> Result<Json<User>, ApiError> {
    let auth = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;

    let token = auth.strip_prefix("Bearer ").ok_or(ApiError::Unauthorized)?;

    let claims = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(state.config.jwt_secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| ApiError::Unauthorized)?
    .claims;

    // Load user and check role
    let user = sqlx::query_as::<_, User>(
        "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at FROM users WHERE id = $1",
    )
    .bind(claims.sub)
    .fetch_one(&state.db.pool)
    .await?;

    if user.role != "admin" {
        return Err(ApiError::Unauthorized);
    }

    Ok(Json(user))
}
