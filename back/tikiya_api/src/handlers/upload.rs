use axum::{
    extract::{Multipart, State},
    Json,
};
use serde::Serialize;
use tokio::fs;
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
    let _user_id = auth.user_id;

    fs::create_dir_all("uploads")
        .await
        .map_err(|_| ApiError::Internal)?;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|_| ApiError::Validation("multipart invalide".into()))?
    {
        let content_type = field.content_type().unwrap_or("image/jpeg").to_string();
        let ext = match content_type.as_str() {
            "image/png" => "png",
            "image/webp" => "webp",
            "image/gif" => "gif",
            _ => "jpg",
        };

        let data = field
            .bytes()
            .await
            .map_err(|_| ApiError::Validation("lecture fichier échouée".into()))?;

        if data.is_empty() {
            continue;
        }

        let filename = format!("{}.{}", Uuid::new_v4(), ext);
        fs::write(format!("uploads/{filename}"), &data)
            .await
            .map_err(|_| ApiError::Internal)?;

        let url = format!("{}/files/{}", state.config.public_base_url, filename);
        tracing::info!(filename = %filename, "upload.saved");
        return Ok(Json(UploadResponse { url }));
    }

    Err(ApiError::Validation("aucun fichier fourni".into()))
}
