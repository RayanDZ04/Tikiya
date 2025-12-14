use axum::{extract::State, Json};
use validator::Validate;

use crate::dto::{AuthResponse, LoginRequest, RegisterRequest};
use crate::error::ApiError;
use crate::services::auth::AuthService;
use crate::state::AppState;

pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;

    let service = AuthService::new(state);
    let response = service.register(payload).await?;

    Ok(Json(response))
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;

    let service = AuthService::new(state);
    let response = service.login(payload).await?;

    Ok(Json(response))
}
