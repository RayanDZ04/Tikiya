use axum::{
    routing::{delete, get, post},
    Router,
};

use crate::handlers::events::{create_event, delete_event, list_all, list_mine};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/events", get(list_all))
        .route("/events/my", get(list_mine))
        .route("/events", post(create_event))
        .route("/events/{id}", delete(delete_event))
}
