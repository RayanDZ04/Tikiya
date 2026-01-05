use axum::{extract::{State, ConnectInfo}, Json};
use serde::Deserialize;
use std::net::SocketAddr;
use crate::dto::AuthTokens;
use validator::Validate;

use crate::dto::{AuthResponse, LoginRequest, LogoutRequest, RefreshRequest, RegisterRequest};
use crate::error::ApiError;
use crate::services::auth::AuthService;
use crate::services::oauth::OAuthService;
use crate::state::AppState;

pub async fn register(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<RegisterRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    tracing::info!(ip = %addr.ip(), "auth.register.request");
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;

    let service = AuthService::new(state);
    let response = service.register(payload).await?;
    tracing::info!(ip = %addr.ip(), user_email = %response.user.email, "auth.register.response_success");

    Ok(Json(response))
}

pub async fn login(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    tracing::info!(ip = %addr.ip(), email = %payload.email, "auth.login.request");
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;
    let service = AuthService::new(state);
    let response = service.login(payload).await?;
    tracing::info!(ip = %addr.ip(), user_email = %response.user.email, "auth.login.response_success");
    Ok(Json(response))
}

pub async fn refresh(
    State(state): State<AppState>,
    Json(payload): Json<RefreshRequest>,
) -> Result<Json<AuthTokens>, ApiError> {
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;

    let service = AuthService::new(state);
    let tokens = service.refresh(payload).await?;

    Ok(Json(tokens))
}

pub async fn logout(
    State(state): State<AppState>,
    Json(payload): Json<LogoutRequest>,
) -> Result<(), ApiError> {
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;

    let service = AuthService::new(state);
    service.logout(payload).await
}

#[derive(Deserialize)]
pub struct GoogleMobileRequest {
    id_token: String,
}

#[derive(serde::Deserialize)]
struct TokenInfo {
    aud: String,
    iss: Option<String>,
    exp: Option<i64>,
    sub: String,
    email: Option<String>,
    email_verified: Option<String>,
}

pub async fn google_mobile(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<GoogleMobileRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    tracing::info!(ip = %addr.ip(), "auth.google_mobile.request");
    let client = reqwest::Client::builder()
        .user_agent("tikiya-api/1.0")
        .connect_timeout(std::time::Duration::from_secs(5))
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|_| ApiError::Internal)?;
    let res = client
        .get("https://oauth2.googleapis.com/tokeninfo")
        .query(&[("id_token", payload.id_token.clone())])
        .send()
        .await
        .map_err(|e| {
            tracing::error!(?e, "auth.google_mobile.tokeninfo_request_failed");
            ApiError::Internal
        })?;
    if !res.status().is_success() {
        let status = res.status();
        let text = res.text().await.unwrap_or_default();
        tracing::warn!(status = %status, body = %text, "auth.google_mobile.tokeninfo_failed");
        return Err(ApiError::Unauthorized);
    }
    let info: TokenInfo = res.json().await.map_err(|e| {
        tracing::error!(?e, "auth.google_mobile.tokeninfo_parse_failed");
        ApiError::Internal
    })?;
    if info.aud != state.config.google_client_id {
        tracing::warn!(expected = %state.config.google_client_id, got = %info.aud, "auth.google_mobile.audience_mismatch");
        return Err(ApiError::Unauthorized);
    }

    if let Some(iss) = info.iss.as_deref() {
        if iss != "https://accounts.google.com" && iss != "accounts.google.com" {
            tracing::warn!(got = %iss, "auth.google_mobile.issuer_mismatch");
            return Err(ApiError::Unauthorized);
        }
    }

    if let Some(exp) = info.exp {
        if exp <= chrono::Utc::now().timestamp() {
            tracing::warn!("auth.google_mobile.token_expired");
            return Err(ApiError::Unauthorized);
        }
    }

    let email = info.email.clone().unwrap_or_default();
    if email.trim().is_empty() {
        tracing::warn!("auth.google_mobile.missing_email");
        return Err(ApiError::Unauthorized);
    }

    if let Some(v) = info.email_verified.as_deref() {
        // tokeninfo returns strings like "true"/"false"
        if v != "true" {
            tracing::warn!(got = %v, "auth.google_mobile.email_not_verified");
            return Err(ApiError::Unauthorized);
        }
    }
    // Upsert user using OAuthService helper
    let oauth = OAuthService::new(state.clone());
    let user = oauth
        .upsert_oauth_user(&crate::services::oauth::GoogleUserInfo {
            sub: info.sub,
            email,
            _email_verified: true,
            _given_name: None,
            _family_name: None,
        })
        .await?;
    let auth = AuthService::new(state);
    let tokens = auth.issue_tokens(&user).await?;
    tracing::info!(ip = %addr.ip(), user_email = %user.email, "auth.google_mobile.response_success");
    Ok(Json(AuthResponse { user: crate::dto::UserResponse::from(&user), tokens }))
}
