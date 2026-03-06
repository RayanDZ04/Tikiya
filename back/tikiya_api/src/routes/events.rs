use axum::{
    routing::{delete, get, post, put},
    Router,
};

use crate::handlers::events::{create_event, delete_event, list_all, list_mine, update_event};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/events", get(list_all))
        .route("/events/my", get(list_mine))
        .route("/events", post(create_event))
        .route("/events/{id}", delete(delete_event))
        .route("/events/{id}", put(update_event))
}
