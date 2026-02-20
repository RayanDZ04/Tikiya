use axum::{routing::post, Router};

use crate::handlers;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/orga-needs", post(handlers::organizer_needs::submit))
}
