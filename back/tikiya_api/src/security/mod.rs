pub mod oauth_state;

use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::Deserialize;
use uuid::Uuid;

use crate::error::ApiError;
use crate::state::AppState;

/// Axum extractor that validates the Bearer JWT and extracts the authenticated user ID.
///
/// Usage in handlers:
/// ```rust
/// pub async fn my_handler(auth: AuthUser, ...) -> ... {
///     let user_id = auth.user_id;
/// }
/// ```
#[derive(Debug, Clone)]
pub struct AuthUser {
    pub user_id: Uuid,
}

#[derive(Deserialize)]
struct JwtClaims {
    sub: Uuid,
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = ApiError;

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
        let auth = parts
            .headers
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
        Ok(AuthUser { user_id: data.claims.sub })
    }
}
