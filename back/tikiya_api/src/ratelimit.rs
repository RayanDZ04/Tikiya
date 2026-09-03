//! Distributed per-IP rate limiting backed by Redis.
//!
//! `tower_governor` (see http.rs) enforces a per-process burst limit, which is
//! fine on a single instance but multiplies by N when the API runs as N replicas
//! behind a load balancer. This middleware puts the real ceiling in Redis so the
//! limit is shared across every replica.
//!
//! Fail-open by design: if Redis is unreachable, requests are allowed rather than
//! taking the whole API down — the in-memory governor still provides a floor.

use std::net::IpAddr;

use axum::{
    extract::{ConnectInfo, State},
    http::{Request, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
};
use std::net::SocketAddr;

use crate::state::AppState;

/// Fixed-window counter: at most `limit` requests per `window_secs` per IP.
const WINDOW_SECS: usize = 60;

fn window_limit(state: &AppState) -> u64 {
    // Reuse the per-second config as a per-minute ceiling (× window), giving a
    // generous but bounded distributed cap. Kept separate from the governor's
    // burst so the two layers don't have to agree.
    (state.config.rate_limit_per_second as u64) * (WINDOW_SECS as u64)
}

fn client_ip<B>(req: &Request<B>, trust_proxy: bool) -> Option<IpAddr> {
    if trust_proxy {
        if let Some(fwd) = req.headers().get("x-forwarded-for") {
            if let Ok(s) = fwd.to_str() {
                if let Some(first) = s.split(',').next() {
                    if let Ok(ip) = first.trim().parse::<IpAddr>() {
                        return Some(ip);
                    }
                }
            }
        }
    }
    req.extensions()
        .get::<ConnectInfo<SocketAddr>>()
        .map(|ci| ci.0.ip())
}

/// Core fixed-window limiter. `prefix` isolates independent budgets (global vs
/// auth), `window` is the bucket length, `limit` the max hits per window per IP.
/// Fail-open on any Redis error.
async fn enforce(
    state: &AppState,
    req: Request<axum::body::Body>,
    next: Next,
    prefix: &str,
    window: usize,
    limit: u64,
) -> Response {
    let Some(mut conn) = state.redis.clone() else {
        return next.run(req).await; // distributed limiting disabled (dev)
    };

    let ip = match client_ip(&req, state.config.trust_proxy_headers) {
        Some(ip) => ip,
        None => return next.run(req).await, // can't identify client, don't block
    };

    let bucket = chrono::Utc::now().timestamp() as usize / window;
    let key = format!("{}:{}:{}", prefix, ip, bucket);

    // INCR returns the new counter value. Set the TTL only on the first hit of
    // the window (n == 1) so the window is fixed, not sliding.
    let count: Result<i64, _> = redis::cmd("INCR").arg(&key).query_async(&mut conn).await;
    let n = match count {
        Ok(n) => {
            if n == 1 {
                let _: Result<(), _> = redis::cmd("EXPIRE")
                    .arg(&key)
                    .arg(window)
                    .query_async(&mut conn)
                    .await;
            }
            n
        }
        Err(e) => {
            tracing::error!(error = %e, "ratelimit.redis.error");
            return next.run(req).await; // fail open — a Redis outage must not down the API
        }
    };

    if n as u64 > limit {
        tracing::warn!(ip = %ip, count = n, prefix = prefix, "ratelimit.blocked");
        (
            StatusCode::TOO_MANY_REQUESTS,
            "Trop de requêtes, réessayez dans un instant.",
        )
            .into_response()
    } else {
        next.run(req).await
    }
}

/// Global per-IP limit applied to every route.
pub async fn redis_rate_limit(
    State(state): State<AppState>,
    req: Request<axum::body::Body>,
    next: Next,
) -> Response {
    let limit = window_limit(&state);
    enforce(&state, req, next, "rl", WINDOW_SECS, limit).await
}

/// Much stricter per-IP limit for authentication endpoints (login, register,
/// email OTP). Blunts credential-stuffing / OTP-guessing / signup floods that
/// the generous global limit would let through.
const AUTH_WINDOW_SECS: usize = 300; // 5 minutes
const AUTH_MAX_PER_WINDOW: u64 = 15; // 15 attempts / 5 min / IP

pub async fn auth_rate_limit(
    State(state): State<AppState>,
    req: Request<axum::body::Body>,
    next: Next,
) -> Response {
    enforce(&state, req, next, "rl_auth", AUTH_WINDOW_SECS, AUTH_MAX_PER_WINDOW).await
}
