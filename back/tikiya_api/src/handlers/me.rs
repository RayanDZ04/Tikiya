use argon2::password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString, rand_core::OsRng};
use argon2::Argon2;
use axum::{extract::State, Json};

use crate::security::AuthUser;
use crate::{dto::{UserResponse, ChangePasswordRequest, ChangeEmailRequest, ChangeUsernameRequest}, error::ApiError, state::AppState};

pub async fn admin_me(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<UserResponse>, ApiError> {
    let user_id = auth.user_id;

    #[derive(sqlx::FromRow)]
    struct MeRow {
        id: uuid::Uuid,
        email: String,
        role: String,
        created_at: chrono::DateTime<chrono::Utc>,
    }

    let user = sqlx::query_as::<_, MeRow>(
        "SELECT id, email, role, created_at FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db.pool)
    .await?;

    if user.role != "admin" {
        return Err(ApiError::Unauthorized);
    }

    Ok(Json(UserResponse {
        id: user.id,
        email: user.email,
        role: user.role,
        created_at: user.created_at,
    }))
}

/// PUT /me/password — change password (requires current password)
pub async fn change_password(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<ChangePasswordRequest>,
) -> Result<axum::http::StatusCode, ApiError> {
    // validate input lengths
    use validator::Validate;
    payload.validate().map_err(|e| ApiError::Validation(e.to_string()))?;

    let user_id = auth.user_id;

    #[derive(sqlx::FromRow)]
    struct PwRow { password_hash: Option<String> }

    let row = sqlx::query_as::<_, PwRow>(
        "SELECT password_hash FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db.pool)
    .await?;

    let hash_str = row.password_hash.ok_or(ApiError::Unauthorized)?;

    // Verify current password
    let current = payload.current_password.clone();
    let hash_for_check = hash_str.clone();
    let ok = tokio::task::spawn_blocking(move || {
        let parsed = PasswordHash::new(&hash_for_check).map_err(|_| ())?;
        Argon2::default()
            .verify_password(current.as_bytes(), &parsed)
            .map(|_| ()).map_err(|_| ())
    })
    .await
    .map_err(|_| ApiError::Internal)?
    .is_ok();

    if !ok {
        return Err(ApiError::Validation("Mot de passe actuel incorrect".into()));
    }

    // Hash new password
    let new_pw = payload.new_password.clone();
    let new_hash = tokio::task::spawn_blocking(move || {
        let salt = SaltString::generate(&mut OsRng);
        Argon2::default()
            .hash_password(new_pw.as_bytes(), &salt)
            .map(|h| h.to_string())
    })
    .await
    .map_err(|_| ApiError::Internal)??;

    sqlx::query("UPDATE users SET password_hash = $1 WHERE id = $2")
        .bind(new_hash)
        .bind(user_id)
        .execute(&state.db.pool)
        .await?;

    tracing::info!(user_id = %user_id, "me.change_password.success");
    Ok(axum::http::StatusCode::NO_CONTENT)
}

/// PUT /me/email — change email (requires current password)
pub async fn change_email(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<ChangeEmailRequest>,
) -> Result<axum::http::StatusCode, ApiError> {
    use validator::Validate;
    payload.validate().map_err(|e| ApiError::Validation(e.to_string()))?;

    let user_id = auth.user_id;

    #[derive(sqlx::FromRow)]
    struct UserRow { password_hash: Option<String> }

    let row = sqlx::query_as::<_, UserRow>(
        "SELECT password_hash FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db.pool)
    .await?;

    let hash_str = row.password_hash.ok_or(ApiError::Unauthorized)?;

    // Verify current password
    let current = payload.current_password.clone();
    let hash_for_check = hash_str.clone();
    let ok = tokio::task::spawn_blocking(move || {
        let parsed = PasswordHash::new(&hash_for_check).map_err(|_| ())?;
        Argon2::default()
            .verify_password(current.as_bytes(), &parsed)
            .map(|_| ()).map_err(|_| ())
    })
    .await
    .map_err(|_| ApiError::Internal)?
    .is_ok();

    if !ok {
        return Err(ApiError::Validation("Mot de passe incorrect".into()));
    }

    // Check email not already taken
    let existing: Option<(uuid::Uuid,)> = sqlx::query_as(
        "SELECT id FROM users WHERE email = $1",
    )
    .bind(&payload.new_email)
    .fetch_optional(&state.db.pool)
    .await?;

    if existing.is_some() {
        return Err(ApiError::Conflict("Cette adresse email est déjà utilisée".into()));
    }

    sqlx::query("UPDATE users SET email = $1 WHERE id = $2")
        .bind(&payload.new_email)
        .bind(user_id)
        .execute(&state.db.pool)
        .await?;

    tracing::info!(user_id = %user_id, new_email = %payload.new_email, "me.change_email.success");
    Ok(axum::http::StatusCode::NO_CONTENT)
}

/// PUT /me/username — change display username (no password required)
pub async fn change_username(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<ChangeUsernameRequest>,
) -> Result<axum::http::StatusCode, ApiError> {
    use validator::Validate;
    payload.validate().map_err(|e| ApiError::Validation(e.to_string()))?;

    let user_id = auth.user_id;

    sqlx::query("UPDATE users SET username = $1 WHERE id = $2")
        .bind(&payload.username)
        .bind(user_id)
        .execute(&state.db.pool)
        .await?;

    tracing::info!(user_id = %user_id, username = %payload.username, "me.change_username.success");
    Ok(axum::http::StatusCode::NO_CONTENT)
}
