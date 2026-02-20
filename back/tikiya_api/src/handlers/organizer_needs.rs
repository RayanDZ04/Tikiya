use axum::{extract::State, Json};
use serde::Serialize;
use validator::Validate;

use crate::dto::OrganizerNeedsRequest;
use crate::error::ApiError;
use crate::services::organizer_needs::send_organizer_needs_email;
use crate::state::AppState;

#[derive(Serialize)]
pub struct OrganizerNeedsResponse {
    pub ok: bool,
    pub message: &'static str,
}

pub async fn submit(
    State(state): State<AppState>,
    Json(payload): Json<OrganizerNeedsRequest>,
) -> Result<Json<OrganizerNeedsResponse>, ApiError> {
    payload
        .validate()
        .map_err(|err| ApiError::Validation(err.to_string()))?;

    send_organizer_needs_email(&state, &payload).await?;

    Ok(Json(OrganizerNeedsResponse {
        ok: true,
        message: "Formulaire envoyé",
    }))
}
