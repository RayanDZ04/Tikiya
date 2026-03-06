use axum::{routing::{get, put}, Router};

use crate::handlers::me::{admin_me, change_password, change_email, change_username};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/me/admin", get(admin_me))
        .route("/me/password", put(change_password))
        .route("/me/email", put(change_email))
        .route("/me/username", put(change_username))
}
