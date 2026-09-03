use argon2::password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString, rand_core::OsRng};
use argon2::Argon2;
use axum::{extract::State, Json};

use crate::security::AuthUser;
use crate::{dto::{UserResponse, ChangePasswordRequest, ChangeEmailRequest, ChangeUsernameRequest, DeleteAccountRequest}, error::ApiError, state::AppState};

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
        first_name: None,
        last_name: None,
        username: None,
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

    // Reject new passwords found in known breaches (no-op unless enabled).
    if crate::services::pwned::is_breached(&state, &payload.new_password).await {
        return Err(ApiError::Validation(
            "Ce mot de passe apparaît dans une fuite de données connue. Choisissez-en un autre.".into(),
        ));
    }

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

    // A stolen refresh token shouldn't survive the user securing their account.
    crate::services::auth::revoke_all_sessions(&state.db.pool, user_id).await?;

    crate::services::audit::record(
        &state, Some(user_id), "password.changed", Some("user"),
        Some(&user_id.to_string()), None, None,
    )
    .await;
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

    crate::services::audit::record(
        &state, Some(user_id), "email.changed", Some("user"),
        Some(&user_id.to_string()), None, None,
    )
    .await;
    tracing::info!(user_id = %user_id, new_email = %payload.new_email, "me.change_email.success");
    Ok(axum::http::StatusCode::NO_CONTENT)
}

/// GET /me/export — exporte toutes les données personnelles (RGPD, droit à la
/// portabilité). Renvoie le profil, les événements et les tickets de l'utilisateur.
pub async fn export_me(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, ApiError> {
    let user_id = auth.user_id;

    let profile: serde_json::Value = sqlx::query_scalar(
        "SELECT to_jsonb(u) - 'password_hash'
         FROM (SELECT id, email, role, username, first_name, last_name,
                      email_verified, created_at
               FROM users WHERE id = $1) u",
    )
    .bind(user_id)
    .fetch_optional(&state.db.pool)
    .await?
    .ok_or(ApiError::NotFound)?;

    let events: serde_json::Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(to_jsonb(e)), '[]'::jsonb)
         FROM events e WHERE e.organizer_id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db.pool)
    .await?;

    let tickets: serde_json::Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
         FROM tickets t WHERE t.user_id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db.pool)
    .await?;

    crate::services::audit::record(
        &state, Some(user_id), "account.exported", Some("user"),
        Some(&user_id.to_string()), None, None,
    )
    .await;

    Ok(Json(serde_json::json!({
        "profile": profile,
        "events": events,
        "tickets": tickets,
    })))
}

/// DELETE /me — supprime définitivement le compte (RGPD, droit à l'effacement).
/// Exige le mot de passe actuel. La suppression cascade sur les événements,
/// tickets et sessions de l'utilisateur (contraintes ON DELETE CASCADE).
pub async fn delete_me(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(payload): Json<DeleteAccountRequest>,
) -> Result<axum::http::StatusCode, ApiError> {
    use validator::Validate;
    payload.validate().map_err(|e| ApiError::Validation(e.to_string()))?;

    let user_id = auth.user_id;

    #[derive(sqlx::FromRow)]
    struct PwRow { password_hash: Option<String> }
    let row = sqlx::query_as::<_, PwRow>("SELECT password_hash FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_one(&state.db.pool)
        .await?;
    let hash_str = row.password_hash.ok_or(ApiError::Unauthorized)?;

    let current = payload.current_password.clone();
    let ok = tokio::task::spawn_blocking(move || {
        let parsed = PasswordHash::new(&hash_str).map_err(|_| ())?;
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

    // Record the erasure BEFORE deleting so the trail survives (actor_id becomes
    // NULL via ON DELETE SET NULL, but target_id keeps the deleted user's id).
    crate::services::audit::record(
        &state, Some(user_id), "account.deleted", Some("user"),
        Some(&user_id.to_string()), None, None,
    )
    .await;

    sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(&state.db.pool)
        .await?;

    tracing::info!(user_id = %user_id, "me.delete.success");
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
