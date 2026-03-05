use axum::{
    routing::{get, post},
    Router,
};

use crate::handlers::payments::{
    create_checkout, event_ticket_stats, my_tickets, payment_failure, payment_success,
    payment_webhook,
};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/payments/checkout", post(create_checkout))
        .route("/payments/webhook", post(payment_webhook))
        .route("/payments/my", get(my_tickets))
        .route("/payments/event/{event_id}", get(event_ticket_stats))
        .route("/payments/success", get(payment_success))
        .route("/payments/failure", get(payment_failure))
}
