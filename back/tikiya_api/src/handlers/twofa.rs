//! Two-factor authentication (TOTP) management for the logged-in user.
//!
//! Flow: `setup` generates a secret and returns an otpauth:// URL (the client
//! renders the QR). `enable` verifies a first code and turns 2FA on. `disable`
//! verifies a code and turns it off. Login enforcement lives in the auth service.

use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};
use totp_rs::{Algorithm, Secret, TOTP};

use crate::error::ApiError;
use crate::security::AuthUser;
use crate::state::AppState;

/// Builds a TOTP instance from a base32 secret for the given account label.
pub fn build_totp(secret_b32: &str, account: &str) -> Result<TOTP, ApiError> {
    let bytes = Secret::Encoded(secret_b32.to_string())
        .to_bytes()
        .map_err(|_| ApiError::Internal)?;
    TOTP::new(
        Algorithm::SHA1,
        6,
        1,
        30,
        bytes,
        Some("Tikiya".to_string()),
        account.to_string(),
    )
    .map_err(|_| ApiError::Internal)
}

#[derive(Serialize)]
pub struct SetupResponse {
    /// otpauth:// URL to load into an authenticator app (render as QR client-side).
    pub otpauth_url: String,
    /// The raw base32 secret, for manual entry.
    pub secret: String,
}

/// POST /me/2fa/setup — generate a pending secret (not yet enabled).
pub async fn setup(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<SetupResponse>, ApiError> {
    #[derive(sqlx::FromRow)]
    struct Row { email: String, totp_enabled: bool }
    let row = sqlx::query_as::<_, Row>("SELECT email, totp_enabled FROM users WHERE id = $1")
        .bind(auth.user_id)
        .fetch_one(&state.db.pool)
        .await?;

    if row.totp_enabled {
        return Err(ApiError::Validation("La 2FA est déjà activée.".into()));
    }

    let secret_b32 = Secret::generate_secret().to_encoded().to_string();
    let totp = build_totp(&secret_b32, &row.email)?;
    let otpauth_url = totp.get_url();

    // Store as pending (enabled stays false until a code is confirmed).
    sqlx::query("UPDATE users SET totp_secret = $1, totp_enabled = FALSE WHERE id = $2")
        .bind(&secret_b32)
        .bind(auth.user_id)
        .execute(&state.db.pool)
        .await?;

    Ok(Json(SetupResponse { otpauth_url, secret: secret_b32 }))
}

#[derive(Deserialize)]
pub struct CodeRequest {
    pub code: String,
}

/// POST /me/2fa/enable — confirm the pending secret with a first valid code.
pub async fn enable(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CodeRequest>,
) -> Result<axum::http::StatusCode, ApiError> {
    #[derive(sqlx::FromRow)]
    struct Row { email: String, totp_secret: Option<String>, totp_enabled: bool }
    let row = sqlx::query_as::<_, Row>(
        "SELECT email, totp_secret, totp_enabled FROM users WHERE id = $1",
    )
    .bind(auth.user_id)
    .fetch_one(&state.db.pool)
    .await?;

    if row.totp_enabled {
        return Err(ApiError::Validation("La 2FA est déjà activée.".into()));
    }
    let secret = row.totp_secret.ok_or_else(|| {
        ApiError::Validation("Commencez par /me/2fa/setup.".into())
    })?;

    let totp = build_totp(&secret, &row.email)?;
    if !totp.check_current(&payload.code).map_err(|_| ApiError::Internal)? {
        return Err(ApiError::Validation("Code 2FA invalide.".into()));
    }

    sqlx::query("UPDATE users SET totp_enabled = TRUE WHERE id = $1")
        .bind(auth.user_id)
        .execute(&state.db.pool)
        .await?;

    crate::services::audit::record(
        &state, Some(auth.user_id), "2fa.enabled", Some("user"),
        Some(&auth.user_id.to_string()), None, None,
    )
    .await;
    Ok(axum::http::StatusCode::NO_CONTENT)
}

/// POST /me/2fa/disable — turn 2FA off after verifying a current code.
pub async fn disable(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<CodeRequest>,
) -> Result<axum::http::StatusCode, ApiError> {
    #[derive(sqlx::FromRow)]
    struct Row { email: String, totp_secret: Option<String>, totp_enabled: bool }
    let row = sqlx::query_as::<_, Row>(
        "SELECT email, totp_secret, totp_enabled FROM users WHERE id = $1",
    )
    .bind(auth.user_id)
    .fetch_one(&state.db.pool)
    .await?;

    if !row.totp_enabled {
        return Err(ApiError::Validation("La 2FA n'est pas activée.".into()));
    }
    let secret = row.totp_secret.ok_or(ApiError::Internal)?;
    let totp = build_totp(&secret, &row.email)?;
    if !totp.check_current(&payload.code).map_err(|_| ApiError::Internal)? {
        return Err(ApiError::Validation("Code 2FA invalide.".into()));
    }

    sqlx::query("UPDATE users SET totp_secret = NULL, totp_enabled = FALSE WHERE id = $1")
        .bind(auth.user_id)
        .execute(&state.db.pool)
        .await?;

    crate::services::audit::record(
        &state, Some(auth.user_id), "2fa.disabled", Some("user"),
        Some(&auth.user_id.to_string()), None, None,
    )
    .await;
    Ok(axum::http::StatusCode::NO_CONTENT)
}
