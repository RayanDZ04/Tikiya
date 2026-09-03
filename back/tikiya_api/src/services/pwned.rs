//! Breached-password check via HaveIBeenPwned's range API (k-anonymity).
//!
//! Only the first 5 hex chars of the password's SHA-1 are sent to the API; the
//! full hash never leaves the server. Fail-open: if the API is unreachable the
//! password is accepted (availability over a best-effort check).
//!
//! Gated by config: disabled unless `PWNED_CHECK_ENABLED=true`, so tests and
//! offline/dev runs make no external calls.

use sha1::{Digest, Sha1};

use crate::state::AppState;

/// Returns true if `password` appears in a known breach corpus.
/// Returns false on any error (fail-open) or when the check is disabled.
pub async fn is_breached(state: &AppState, password: &str) -> bool {
    if !state.config.pwned_check_enabled {
        return false;
    }

    let mut hasher = Sha1::new();
    hasher.update(password.as_bytes());
    let digest = hasher.finalize();
    let hash_hex = digest.iter().fold(String::new(), |mut s, b| {
        use std::fmt::Write;
        let _ = write!(s, "{:02X}", b);
        s
    });
    let (prefix, suffix) = hash_hex.split_at(5);

    let url = format!("https://api.pwnedpasswords.com/range/{prefix}");
    let resp = match state
        .http_client
        .get(&url)
        .header("Add-Padding", "true")
        .send()
        .await
    {
        Ok(r) => r,
        Err(e) => {
            tracing::warn!(error = %e, "pwned.request_failed — allowing (fail-open)");
            return false;
        }
    };

    let body = match resp.text().await {
        Ok(b) => b,
        Err(e) => {
            tracing::warn!(error = %e, "pwned.read_failed — allowing (fail-open)");
            return false;
        }
    };

    // Each line is "SUFFIX:count". A count > 0 for our suffix means breached.
    for line in body.lines() {
        if let Some((line_suffix, count)) = line.split_once(':') {
            if line_suffix.eq_ignore_ascii_case(suffix) {
                let n: u64 = count.trim().parse().unwrap_or(0);
                return n > 0;
            }
        }
    }
    false
}
