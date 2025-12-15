use axum::{routing::post, Router};

use crate::handlers::{self, auth::logout, auth::refresh, auth::google_mobile};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/register", post(handlers::register))
        .route("/login", post(handlers::login))
    .route("/auth/google/mobile", post(google_mobile))
        .route("/refresh", post(refresh))
        .route("/logout", post(logout))
}
