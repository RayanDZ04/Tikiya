use axum::{
    extract::{Multipart, State},
    http::HeaderMap,
    Json,
};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use tokio::fs;
use uuid::Uuid;

use crate::error::ApiError;
use crate::state::AppState;

#[derive(Debug, Deserialize)]
struct JwtClaims {
    sub: Uuid,
}

fn extract_user(headers: &HeaderMap, state: &AppState) -> Result<Uuid, ApiError> {
    let auth = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;
    let token = auth.strip_prefix("Bearer ").ok_or(ApiError::Unauthorized)?;
    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_audience(std::slice::from_ref(&state.config.jwt_audience));
    validation.set_issuer(std::slice::from_ref(&state.config.jwt_issuer));
    let data = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(state.config.jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|_| ApiError::Unauthorized)?;
    Ok(data.claims.sub)
}

#[derive(Serialize)]
pub struct UploadResponse {
    pub url: String,
}

/// POST /upload  — upload an image (authenticated)
/// Returns: { "url": "http://.../files/<uuid>.jpg" }
pub async fn upload_file(
    State(state): State<AppState>,
    headers: HeaderMap,
    mut multipart: Multipart,
) -> Result<Json<UploadResponse>, ApiError> {
    let _user_id = extract_user(&headers, &state)?;

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
