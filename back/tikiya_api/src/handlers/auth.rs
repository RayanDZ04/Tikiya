use axum::{extract::{State, ConnectInfo}, Json};
use serde::Deserialize;
use std::net::SocketAddr;
use crate::dto::AuthTokens;
use validator::Validate;

use crate::dto::{AuthResponse, LoginRequest, LogoutRequest, RefreshRequest, RegisterRequest};
use crate::error::ApiError;
use crate::services::auth::AuthService;
use crate::services::oauth::OAuthService;
use crate::services::otp;
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

    // Bot defence: verify the CAPTCHA token (no-op unless CAPTCHA_SECRET is set).
    if !crate::services::captcha::verify(&state, payload.captcha_token.as_deref()).await {
        return Err(ApiError::Validation(
            "Vérification anti-robot échouée. Réessayez.".into(),
        ));
    }

    // Reject passwords known to be compromised in public breaches (fail-open,
    // no-op unless PWNED_CHECK_ENABLED is set).
    if crate::services::pwned::is_breached(&state, &payload.password).await {
        return Err(ApiError::Validation(
            "Ce mot de passe apparaît dans une fuite de données connue. Choisissez-en un autre.".into(),
        ));
    }

    let service = AuthService::new(state.clone());
    let first_name = payload.first_name.clone();
    let company = payload.company.clone();
    let response = service.register(payload).await?;

    // Use first_name if available, otherwise fall back to company name (organizers)
    let display_name = first_name.or(company);

    // Send OTP to verify the email address (fire; log error but do not fail registration)
    if let Err(e) = otp::send_otp(&state, response.user.id, &response.user.email, display_name.as_deref()).await {
        tracing::error!(user_id = %response.user.id, error = ?e, "register.otp.send_failed");
    }

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
    let client = &state.http_client;
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
    Ok(Json(AuthResponse { email_verified: user.email_verified, user: crate::dto::UserResponse::from(&user), tokens }))
}
