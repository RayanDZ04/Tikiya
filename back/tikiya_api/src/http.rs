use axum::{
    extract::State,
    http::{HeaderName, HeaderValue, Method, Request, StatusCode},
    routing::get,
    Router,
};
use std::time::Duration;
use tower_http::{
    cors::{AllowOrigin, CorsLayer},
    trace::TraceLayer,
};

use crate::routes;
use crate::state::AppState;

pub fn build_router(state: AppState) -> Router {
    let cors = build_cors(&state.config.allowed_origins);

    let trace = TraceLayer::new_for_http().make_span_with(|req: &Request<_>| {
        let method = req.method().as_str();
        let uri = req.uri().path();
        let id = simple_id(method, uri);
        tracing::info_span!("request", method = %method, uri = %uri, request_id = %id)
    });

    Router::new()
        .route("/health", get(|| async { "OK" }))
        .route("/ready", get(ready))
        .merge(routes::auth::router())
        .with_state(state)
        .layer(trace)
        .layer(cors)
}

fn build_cors(allowed_origins: &[String]) -> CorsLayer {
    let origins = AllowOrigin::list(
        allowed_origins
            .iter()
            .filter_map(|o| HeaderValue::from_str(o).ok()),
    );

    CorsLayer::new()
        .allow_origin(origins)
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers([
            HeaderName::from_static("content-type"),
            HeaderName::from_static("authorization"),
        ])
        .expose_headers([HeaderName::from_static("etag")])
        .max_age(Duration::from_secs(60))
}

fn simple_id(method: &str, uri: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut h = DefaultHasher::new();
    method.hash(&mut h);
    uri.hash(&mut h);
    format!("{:x}", h.finish())
}

async fn ready(State(state): State<AppState>) -> (StatusCode, &'static str) {
    match state.db.ping().await {
        Ok(_) => (StatusCode::OK, "READY"),
        Err(_) => (StatusCode::SERVICE_UNAVAILABLE, "UNAVAILABLE"),
    }
}
