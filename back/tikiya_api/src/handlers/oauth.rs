use axum::{extract::{Query, State}, Json};
use serde::Deserialize;

use crate::error::ApiError;
use crate::services::oauth::OAuthService;
use crate::state::AppState;

#[derive(Deserialize)]
pub struct StartQuery {
    state: Option<String>,
    code_challenge: Option<String>,
    code_challenge_method: Option<String>,
}

#[derive(serde::Serialize)]
pub struct AuthUrlResponse {
    url: String,
}

pub async fn google_start(State(state): State<AppState>, Query(q): Query<StartQuery>) -> Result<Json<AuthUrlResponse>, ApiError> {
    let svc = OAuthService::new(state);
    let url = svc.google_auth_url(
        q.state.as_deref().unwrap_or("state"),
        q.code_challenge.as_deref(),
        q.code_challenge_method.as_deref(),
    ).map_err(|_| ApiError::Internal)?;
    Ok(Json(AuthUrlResponse { url: url.to_string() }))
}

#[derive(Deserialize)]
pub struct CallbackQuery {
    code: String,
    _state: Option<String>,
    code_verifier: Option<String>,
}

pub async fn google_callback(State(state): State<AppState>, Query(q): Query<CallbackQuery>) -> Result<axum::Json<crate::dto::AuthResponse>, ApiError> {
    let svc = OAuthService::new(state);
    let resp = svc.google_callback(&q.code, q.code_verifier.as_deref()).await?;
    Ok(Json(resp))
}
