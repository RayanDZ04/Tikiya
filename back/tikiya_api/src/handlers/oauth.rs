use axum::{extract::{Query, State}, Json};
use serde::Deserialize;

use crate::error::ApiError;
use crate::security::oauth_state;
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
    let signed_state = oauth_state::mint_state(&state.config.jwt_secret, q.state.as_deref())?;
    let svc = OAuthService::new(state);
    let url = svc.google_auth_url(
        &signed_state,
        q.code_challenge.as_deref(),
        q.code_challenge_method.as_deref(),
    ).map_err(|_| ApiError::Internal)?;
    Ok(Json(AuthUrlResponse { url: url.to_string() }))
}

#[derive(Deserialize)]
pub struct CallbackQuery {
    code: String,
    state: Option<String>,
    code_verifier: Option<String>,
}

pub async fn google_callback(State(state): State<AppState>, Query(q): Query<CallbackQuery>) -> Result<axum::Json<crate::dto::AuthResponse>, ApiError> {
    let state_str = q.state.as_deref().ok_or(ApiError::Unauthorized)?;
    oauth_state::verify_state(&state.config.jwt_secret, state_str)?;
    let svc = OAuthService::new(state);
    let resp = svc.google_callback(&q.code, q.code_verifier.as_deref()).await?;
    Ok(Json(resp))
}
