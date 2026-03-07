use axum::{routing::get, Router};

use crate::handlers::admin::{get_stats, get_users, get_events, get_activity, get_daily_stats};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/admin/stats",       get(get_stats))
        .route("/admin/users",       get(get_users))
        .route("/admin/events",      get(get_events))
        .route("/admin/activity",    get(get_activity))
        .route("/admin/daily-stats", get(get_daily_stats))
}
