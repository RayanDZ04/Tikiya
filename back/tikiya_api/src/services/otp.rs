use chrono::{Duration, Utc};
use rand::Rng;
use serde_json::json;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::error::ApiError;
use crate::state::AppState;

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Generate a cryptographically-random 6-digit OTP string.
fn generate_otp() -> String {
    let mut rng = rand::thread_rng();
    format!("{:06}", rng.gen_range(0..1_000_000))
}

/// SHA-256 hex digest of the OTP code.
fn hash_otp(code: &str) -> String {
    let mut h = Sha256::new();
    h.update(code.as_bytes());
    format!("{:x}", h.finalize())
}

// ─── Public API ───────────────────────────────────────────────────────────────

/// Issue a new OTP for `user_id` (invalidates any previous pending OTP),
/// stores its hash in DB, and emails the code via Resend.
///
/// `email` is where the code is sent; `name` is used in the email body.
pub async fn send_otp(
    state: &AppState,
    user_id: Uuid,
    email: &str,
    name: Option<&str>,
) -> Result<(), ApiError> {
    let code = generate_otp();
    let code_hash = hash_otp(&code);
    let expires_at = Utc::now() + Duration::minutes(state.config.otp_ttl_minutes);

    // Delete any existing pending OTP for this user to respect the unique index.
    sqlx::query!("DELETE FROM email_otps WHERE user_id = $1 AND NOT used", user_id)
        .execute(&state.db.pool)
        .await?;

    sqlx::query!(
        "INSERT INTO email_otps (user_id, code_hash, expires_at) VALUES ($1, $2, $3)",
        user_id,
        code_hash,
        expires_at,
    )
    .execute(&state.db.pool)
    .await?;

    send_via_resend(state, email, name, &code).await?;

    tracing::info!(user_id = %user_id, "otp.sent");
    Ok(())
}

/// Verify the OTP code entered by the user.
///
/// Returns `Ok(())` on success; marks the OTP used and sets `email_verified = true` on the user.
/// Returns `Err(ApiError::Validation)` with a message on every failure case.
pub async fn verify_otp(state: &AppState, user_id: Uuid, code: &str) -> Result<(), ApiError> {
    let code_hash = hash_otp(code);

    let row = sqlx::query!(
        r#"
        SELECT id, code_hash, expires_at, attempts, used
        FROM email_otps
        WHERE user_id = $1 AND NOT used
        ORDER BY created_at DESC
        LIMIT 1
        "#,
        user_id,
    )
    .fetch_optional(&state.db.pool)
    .await?;

    let row = match row {
        Some(r) => r,
        None => {
            tracing::warn!(user_id = %user_id, "otp.verify.no_pending");
            return Err(ApiError::Validation("Aucun code en attente. Demandez-en un nouveau.".into()));
        }
    };

    // Expiry check
    if row.expires_at < Utc::now() {
        tracing::warn!(user_id = %user_id, "otp.verify.expired");
        return Err(ApiError::Validation("Code expiré. Veuillez en demander un nouveau.".into()));
    }

    // Attempt limit check
    if row.attempts >= state.config.otp_max_attempts {
        tracing::warn!(user_id = %user_id, attempts = row.attempts, "otp.verify.max_attempts");
        return Err(ApiError::Validation(
            "Trop de tentatives. Veuillez demander un nouveau code.".into(),
        ));
    }

    // Increment attempt counter before comparing (prevents brute-force even if constant-time compare fails)
    sqlx::query!(
        "UPDATE email_otps SET attempts = attempts + 1 WHERE id = $1",
        row.id,
    )
    .execute(&state.db.pool)
    .await?;

    // Constant-time comparison via SHA-256 already reduces timing leaks
    if row.code_hash != code_hash {
        tracing::warn!(user_id = %user_id, "otp.verify.wrong_code");
        let remaining = state.config.otp_max_attempts - row.attempts - 1;
        return Err(ApiError::Validation(format!(
            "Code incorrect. {} tentative(s) restante(s).",
            remaining.max(0)
        )));
    }

    // Mark OTP used
    sqlx::query!("UPDATE email_otps SET used = TRUE WHERE id = $1", row.id)
        .execute(&state.db.pool)
        .await?;

    // Mark user's email as verified
    sqlx::query!(
        "UPDATE users SET email_verified = TRUE WHERE id = $1",
        user_id,
    )
    .execute(&state.db.pool)
    .await?;

    tracing::info!(user_id = %user_id, "otp.verify.success");
    Ok(())
}

// ─── Resend HTTP helper ───────────────────────────────────────────────────────

async fn send_via_resend(
    state: &AppState,
    to: &str,
    name: Option<&str>,
    code: &str,
) -> Result<(), ApiError> {
    let api_key = &state.config.resend_api_key;
    if api_key.is_empty() {
        tracing::warn!("otp.resend.no_api_key — skipping email in dev mode");
        tracing::info!(otp_code = %code, "otp.dev_mode_code"); // visible in logs only
        return Ok(());
    }

    let greeting = name.map(|n| format!("Bonjour {n},")).unwrap_or_else(|| "Bonjour,".into());
    let ttl = state.config.otp_ttl_minutes;

    let html = format!(
        r#"<div style="font-family:sans-serif;max-width:480px;margin:auto">
  <h2 style="color:#0B1C3E">Vérification de votre compte Tikiya!</h2>
  <p>{greeting}</p>
  <p>Votre code de vérification est :</p>
  <div style="font-size:36px;font-weight:bold;letter-spacing:10px;color:#00ACC1;padding:16px 0">{code}</div>
  <p style="color:#666">Ce code est valable pendant <strong>{ttl} minutes</strong>.</p>
  <p style="color:#999;font-size:12px">Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
</div>"#
    );

    let body = json!({
        "from": state.config.resend_from,
        "to": [to],
        "subject": format!("[Tikiya!] Votre code de vérification : {code}"),
        "html": html,
    });

    let res = state
        .http_client
        .post("https://api.resend.com/emails")
        .bearer_auth(api_key)
        .json(&body)
        .send()
        .await
        .map_err(|e| {
            tracing::error!(error = %e, "otp.resend.request_failed");
            ApiError::Internal
        })?;

    if !res.status().is_success() {
        let status = res.status();
        let text = res.text().await.unwrap_or_default();
        tracing::error!(status = %status, body = %text, "otp.resend.api_error");
        return Err(ApiError::Internal);
    }

    tracing::info!(to = %to, "otp.resend.sent");
    Ok(())
}
