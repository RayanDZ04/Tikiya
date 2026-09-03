//! CAPTCHA verification via Cloudflare Turnstile.
//!
//! Gated by config: when `CAPTCHA_SECRET` is empty the check is disabled and
//! `verify` returns true (dev/test make no external calls). When set,
//! registration must include a token that this verifies server-side.

use serde::Deserialize;

use crate::state::AppState;

#[derive(Deserialize)]
struct SiteverifyResponse {
    success: bool,
}

/// Returns true if the token is valid (or if CAPTCHA is disabled).
/// Fails closed on a network error only when CAPTCHA is enabled.
pub async fn verify(state: &AppState, token: Option<&str>) -> bool {
    if state.config.captcha_secret.is_empty() {
        return true; // disabled
    }

    let token = match token {
        Some(t) if !t.trim().is_empty() => t,
        _ => return false, // enabled but no token → reject
    };

    let resp = state
        .http_client
        .post("https://challenges.cloudflare.com/turnstile/v0/siteverify")
        .form(&[
            ("secret", state.config.captcha_secret.as_str()),
            ("response", token),
        ])
        .send()
        .await;

    match resp {
        Ok(r) => match r.json::<SiteverifyResponse>().await {
            Ok(body) => body.success,
            Err(e) => {
                tracing::error!(error = %e, "captcha.parse_failed");
                false
            }
        },
        Err(e) => {
            tracing::error!(error = %e, "captcha.request_failed");
            false // fail closed when the check is enabled
        }
    }
}
