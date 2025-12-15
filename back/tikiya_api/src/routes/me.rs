use axum::{routing::get, Router};

use crate::handlers::me::admin_me;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/me/admin", get(admin_me))
}
