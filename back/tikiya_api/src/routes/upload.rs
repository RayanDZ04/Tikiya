use axum::{routing::post, Router};
use crate::handlers::upload::upload_file;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/upload", post(upload_file))
}
