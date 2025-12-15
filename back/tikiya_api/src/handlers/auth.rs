use axum::{extract::{State, ConnectInfo}, Json};
use serde::Deserialize;
use std::net::SocketAddr;
use crate::dto::AuthTokens;
use std::time::{Duration, Instant};
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
    // Lockout check per email
    {
        let guard = state.failed_logins.lock().map_err(|_| ApiError::Internal)?;
        if let Some((_, Some(until))) = guard.get(&payload.email) {
            if Instant::now() < *until {
                tracing::warn!(email = %payload.email, "auth.login.locked_out");
                return Err(ApiError::Unauthorized);
            }
        }
    }

    // Rate limit per IP: 10 failures lock for 15 minutes
    {
        let ip = addr.ip().to_string();
        let guard = state.ip_failures.lock().map_err(|_| ApiError::Internal)?;
        if let Some((_, Some(until))) = guard.get(&ip) {
            if Instant::now() < *until {
                tracing::warn!(ip = %ip, "auth.login.ip_rate_limited");
                return Err(ApiError::Unauthorized);
            }
        }
    }

    let service = AuthService::new(state);
    match service.login(payload.clone()).await {
        Ok(response) => {
            // Reset failures on success
            let mut guard = service.state.failed_logins.lock().map_err(|_| ApiError::Internal)?;
            guard.remove(&payload.email);
            tracing::info!(ip = %addr.ip(), user_email = %response.user.email, "auth.login.response_success");
            Ok(Json(response))
        }
        Err(err) => {
            // Increment failures and apply lockout after 5
            let mut guard = service.state.failed_logins.lock().map_err(|_| ApiError::Internal)?;
            let entry = guard.entry(payload.email.clone()).or_insert((0, None));
            entry.0 += 1;
            if entry.0 >= 5 {
                entry.1 = Some(Instant::now() + Duration::from_secs(15 * 60));
            }

            // Increment per-IP failures and apply lockout after 10
            let ip = addr.ip().to_string();
            let mut ip_guard = service.state.ip_failures.lock().map_err(|_| ApiError::Internal)?;
            let ip_entry = ip_guard.entry(ip).or_insert((0, None));
            ip_entry.0 += 1;
            if ip_entry.0 >= 10 {
                ip_entry.1 = Some(Instant::now() + Duration::from_secs(15 * 60));
            }
            tracing::warn!(ip = %addr.ip(), email = %payload.email, "auth.login.response_error");
            Err(err)
        }
    }
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
    sub: String,
    email: Option<String>,
}

pub async fn google_mobile(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<GoogleMobileRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    tracing::info!(ip = %addr.ip(), "auth.google_mobile.request");
    let client = reqwest::Client::new();
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
    // Upsert user using OAuthService helper
    let oauth = OAuthService::new(state.clone());
    let user = oauth
        .upsert_oauth_user(&crate::services::oauth::GoogleUserInfo {
            sub: info.sub,
            email: info.email.unwrap_or_default(),
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
