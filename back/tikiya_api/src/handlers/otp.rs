use axum::{extract::State, Json};
use validator::Validate;

use crate::dto::{MessageResponse, VerifyEmailRequest};
use crate::error::ApiError;
use crate::security::AuthUser;
use crate::services::otp;
use crate::state::AppState;

/// POST /email/verify
///
/// Verifies the OTP code entered by the authenticated user.
/// Returns 200 on success, or a descriptive error on failure.
pub async fn verify_email(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<VerifyEmailRequest>,
) -> Result<Json<MessageResponse>, ApiError> {
    payload
        .validate()
        .map_err(|e| ApiError::Validation(e.to_string()))?;

    otp::verify_otp(&state, auth.user_id, &payload.code).await?;

    Ok(Json(MessageResponse {
        message: "Email vérifié avec succès.".into(),
    }))
}

/// POST /email/resend
///
/// Resends an OTP to the authenticated user's email address.
/// Rate-limited at the route level; also implicitly throttled by the OTP service
/// (deletes the old pending code before inserting a new one).
pub async fn resend_otp(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<MessageResponse>, ApiError> {
    // Fetch user email
    let row = sqlx::query!(
        "SELECT email, email_verified FROM users WHERE id = $1",
        auth.user_id,
    )
    .fetch_optional(&state.db.pool)
    .await?
    .ok_or(ApiError::Unauthorized)?;

    if row.email_verified {
        return Err(ApiError::Conflict("Email déjà vérifié.".into()));
    }

    otp::send_otp(&state, auth.user_id, &row.email, None).await?;

    Ok(Json(MessageResponse {
        message: "Un nouveau code a été envoyé à votre adresse email.".into(),
    }))
}
