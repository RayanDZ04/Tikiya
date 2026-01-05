use axum::{
    extract::State,
    extract::DefaultBodyLimit,
    error_handling::HandleErrorLayer,
    http::{HeaderName, HeaderValue, Method, Request, StatusCode},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use axum::middleware::{from_fn, from_fn_with_state, Next};
use std::time::Duration;
use axum::BoxError;
use tower::{ServiceBuilder, limit::ConcurrencyLimitLayer, load_shed::LoadShedLayer};
use tower_http::{
    cors::{AllowOrigin, CorsLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};
use axum::body::Body;
use uuid::Uuid;
use serde::Serialize;
use tower_governor::{
    governor::GovernorConfigBuilder,
    key_extractor::{PeerIpKeyExtractor, SmartIpKeyExtractor},
    GovernorLayer,
    GovernorError,
};

#[derive(Clone, Copy)]
struct ConfigurableIpKeyExtractor {
    trust_proxy_headers: bool,
}

impl tower_governor::key_extractor::KeyExtractor for ConfigurableIpKeyExtractor {
    type Key = std::net::IpAddr;

    fn extract<T>(&self, req: &Request<T>) -> Result<Self::Key, GovernorError> {
        if self.trust_proxy_headers {
            SmartIpKeyExtractor.extract(req)
        } else {
            PeerIpKeyExtractor.extract(req)
        }
    }
}

use crate::routes;
use crate::state::AppState;

pub fn build_router(state: AppState) -> Router {
    let hsts_enabled = state.config.http_hsts_enabled;
    let cors = build_cors(&state.config.allowed_origins);
    let timeout = TimeoutLayer::new(Duration::from_secs(state.config.http_request_timeout_secs));
    let concurrency = ConcurrencyLimitLayer::new(state.config.http_concurrency_limit);
    let body_limit = DefaultBodyLimit::max(state.config.http_max_body_bytes);

     // Global IP rate limiting (anti-bot / brute force). Configure via env.
    let conf = GovernorConfigBuilder::default()
        .per_second(state.config.rate_limit_per_second.into())
        .burst_size(state.config.rate_limit_burst)
        .key_extractor(ConfigurableIpKeyExtractor {
            trust_proxy_headers: state.config.trust_proxy_headers,
        })
        .finish()
        .expect("governor config");
    let governor = GovernorLayer {
        config: std::sync::Arc::new(conf),
    };

    let middleware = ServiceBuilder::new()
        .layer(HandleErrorLayer::<_, ()>::new(handle_layer_error))
        .layer(timeout)
        // If concurrency is saturated, reject immediately instead of holding connections.
        .layer(LoadShedLayer::new())
        .layer(concurrency)
        .layer(governor)
        .layer(body_limit);

    let trace = TraceLayer::new_for_http().make_span_with(|req: &Request<_>| {
        let method = req.method().as_str();
        let uri = req.uri().path();
        let id = req
            .headers()
            .get("x-request-id")
            .and_then(|v| v.to_str().ok())
            .unwrap_or("-");
        tracing::info_span!("request", method = %method, uri = %uri, request_id = %id)
    });

    Router::new()
        .route("/health", get(|| async { "OK" }))
        .route("/ready", get(ready))
        .merge(routes::auth::router())
        .merge(routes::me::router())
        .merge(routes::oauth::router())
        .with_state(state)
        .layer(middleware)
        .layer(from_fn_with_state(hsts_enabled, security_headers))
        .layer(cors)
        .layer(trace)
        .layer(from_fn(request_id))
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

async fn ready(State(state): State<AppState>) -> (StatusCode, &'static str) {
    match state.db.ping().await {
        Ok(_) => (StatusCode::OK, "READY"),
        Err(_) => (StatusCode::SERVICE_UNAVAILABLE, "UNAVAILABLE"),
    }
}

async fn request_id(mut req: Request<Body>, next: Next) -> impl axum::response::IntoResponse {
    let id = req
        .headers()
        .get("x-request-id")
        .and_then(|v| v.to_str().ok())
        .map(str::to_string)
        .unwrap_or_else(|| Uuid::new_v4().to_string());

    if req.headers().get("x-request-id").is_none() {
        if let Ok(hv) = HeaderValue::from_str(&id) {
            req.headers_mut().insert(HeaderName::from_static("x-request-id"), hv);
        }
    }

    let mut resp = next.run(req).await;
    if resp.headers().get("x-request-id").is_none() {
        if let Ok(hv) = HeaderValue::from_str(&id) {
            resp.headers_mut().insert(HeaderName::from_static("x-request-id"), hv);
        }
    }
    resp
}

#[derive(Serialize)]
struct LayerErrorBody {
    code: u16,
    message: &'static str,
    detail: Option<String>,
}

async fn handle_layer_error(err: BoxError) -> Response {
    if err.is::<tower::timeout::error::Elapsed>() {
        let status = StatusCode::REQUEST_TIMEOUT;
        let body = axum::Json(LayerErrorBody {
            code: status.as_u16(),
            message: "Request Timeout",
            detail: None,
        });
        return (status, body).into_response();
    }

    if err.is::<tower::load_shed::error::Overloaded>() {
        let status = StatusCode::SERVICE_UNAVAILABLE;
        let body = axum::Json(LayerErrorBody {
            code: status.as_u16(),
            message: "Server Busy",
            detail: None,
        });
        return (status, body).into_response();
    }

    tracing::error!(error = %err, "layer.error");
    let status = StatusCode::INTERNAL_SERVER_ERROR;
    let body = axum::Json(LayerErrorBody {
        code: status.as_u16(),
        message: "Internal Server Error",
        detail: None,
    });
    (status, body).into_response()
}

async fn security_headers(
    State(hsts_enabled): State<bool>,
    req: Request<Body>,
    next: Next,
) -> impl axum::response::IntoResponse {
    let mut resp = next.run(req).await;
    let headers = resp.headers_mut();
    headers.insert(
        HeaderName::from_static("x-frame-options"),
        HeaderValue::from_static("DENY"),
    );
    headers.insert(
        HeaderName::from_static("x-content-type-options"),
        HeaderValue::from_static("nosniff"),
    );
    headers.insert(
        HeaderName::from_static("referrer-policy"),
        HeaderValue::from_static("no-referrer"),
    );
    // Strict CSP compatible with modern web + mobile WebViews
    // - default-src self
    // - script-src self (no inline)
    // - style-src self
    // - img-src self data: https:
    // - connect-src self https: (API calls, OAuth)
    // - frame-ancestors none
    // - base-uri self
    headers.insert(
        HeaderName::from_static("content-security-policy"),
        HeaderValue::from_static(
            "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data: https:; connect-src 'self' https:; frame-ancestors 'none'; object-src 'none'; base-uri 'self'"
        ),
    );

    headers.insert(
        HeaderName::from_static("permissions-policy"),
        HeaderValue::from_static("geolocation=(), microphone=(), camera=()"),
    );

    // HSTS must only be enabled when served via HTTPS (usually at the reverse-proxy).
    // We gate it behind env to avoid breaking local HTTP.
    if hsts_enabled {
        headers.insert(
            HeaderName::from_static("strict-transport-security"),
            HeaderValue::from_static("max-age=31536000; includeSubDomains"),
        );
    }
    resp
}
