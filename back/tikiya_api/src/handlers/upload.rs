use axum::{
    body::Bytes,
    extract::{Multipart, Path, State},
    http::{header, StatusCode},
    response::IntoResponse,
    Json,
};
use serde::Serialize;
use uuid::Uuid;

use crate::error::ApiError;
use crate::security::AuthUser;
use crate::state::AppState;

#[derive(Serialize)]
pub struct UploadResponse {
    pub url: String,
}

/// POST /upload  — upload an image (authenticated)
/// Returns: { "url": "http://.../files/<uuid>.jpg" }
pub async fn upload_file(
    State(state): State<AppState>,
    auth: AuthUser,
    mut multipart: Multipart,
) -> Result<Json<UploadResponse>, ApiError> {
    let user_id = auth.user_id;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|_| ApiError::Validation("multipart invalide".into()))?
    {
        let data = field
            .bytes()
            .await
            .map_err(|_| ApiError::Validation("lecture fichier échouée".into()))?;

        if data.is_empty() {
            continue;
        }

        if data.len() > state.config.upload_max_file_bytes {
            return Err(ApiError::Validation(format!(
                "Fichier trop volumineux (max {} Mo).",
                state.config.upload_max_file_bytes / (1024 * 1024)
            )));
        }

        // Determine the real file type from its bytes — never trust the
        // client-supplied Content-Type, which is what picks the extension
        // (and thus how it gets served) for a stored file.
        let ext = match infer::get(&data).map(|t| t.extension()) {
            Some("png") => "png",
            Some("webp") => "webp",
            Some("gif") => "gif",
            Some("jpg") => "jpg",
            _ => {
                return Err(ApiError::Validation(
                    "Type de fichier non supporté (jpg, png, webp, gif uniquement).".into(),
                ));
            }
        };

        // Per-user storage quota — uploads weren't tracked/attributed to a user at all before.
        let used: Option<i64> = sqlx::query_scalar("SELECT SUM(size_bytes) FROM uploads WHERE user_id = $1")
            .bind(user_id)
            .fetch_one(&state.db.pool)
            .await?;
        let used = used.unwrap_or(0);
        if used + data.len() as i64 > state.config.upload_quota_bytes_per_user {
            return Err(ApiError::Validation(format!(
                "Quota de stockage dépassé (max {} Mo par utilisateur).",
                state.config.upload_quota_bytes_per_user / (1024 * 1024)
            )));
        }

        let filename = format!("{}.{}", Uuid::new_v4(), ext);
        let size = data.len() as i64;
        state
            .storage
            .put(&filename, data)
            .await
            .map_err(|e| {
                tracing::error!(error = %e, "upload.store_failed");
                ApiError::Internal
            })?;

        sqlx::query("INSERT INTO uploads (user_id, filename, size_bytes) VALUES ($1, $2, $3)")
            .bind(user_id)
            .bind(&filename)
            .bind(size)
            .execute(&state.db.pool)
            .await?;

        let url = format!("{}/files/{}", state.config.public_base_url, filename);
        tracing::info!(filename = %filename, user_id = %user_id, "upload.saved");
        return Ok(Json(UploadResponse { url }));
    }

    Err(ApiError::Validation("aucun fichier fourni".into()))
}

/// GET /files/:filename — serves an uploaded file from the storage backend.
/// Replaces the previous ServeDir which only worked with local disk.
pub async fn serve_file(
    State(state): State<AppState>,
    Path(filename): Path<String>,
) -> Result<impl IntoResponse, StatusCode> {
    // Guard against path traversal: only a bare <uuid>.<ext> basename is valid.
    if filename.contains('/') || filename.contains('\\') || filename.contains("..") {
        return Err(StatusCode::BAD_REQUEST);
    }

    let data = state
        .storage
        .get(&filename)
        .await
        .map_err(|_| StatusCode::NOT_FOUND)?;

    let content_type = match filename.rsplit('.').next() {
        Some("png") => "image/png",
        Some("webp") => "image/webp",
        Some("gif") => "image/gif",
        _ => "image/jpeg",
    };

    Ok((
        [
            (header::CONTENT_TYPE, content_type),
            (header::CACHE_CONTROL, "public, max-age=31536000, immutable"),
        ],
        Bytes::from(data),
    ))
}
