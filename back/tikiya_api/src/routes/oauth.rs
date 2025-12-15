use axum::{routing::get, Router};

use crate::handlers::oauth::{google_callback, google_start};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/auth/google", get(google_start))
        .route("/auth/google/callback", get(google_callback))
}
