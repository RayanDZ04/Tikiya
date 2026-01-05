use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};
use hmac::{Hmac, Mac};
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use argon2::password_hash::rand_core::{OsRng, RngCore};

use crate::error::ApiError;

const STATE_TTL_SECS: i64 = 10 * 60;

#[derive(Debug, Serialize, Deserialize)]
struct StatePayload {
    ts: i64,
    nonce: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    client_state: Option<String>,
}

pub fn mint_state(jwt_secret: &str, client_state: Option<&str>) -> Result<String, ApiError> {
    let mut nonce_bytes = [0u8; 16];
    let mut rng = OsRng;
    rng.fill_bytes(&mut nonce_bytes);
    let nonce = URL_SAFE_NO_PAD.encode(nonce_bytes);

    let payload = StatePayload {
        ts: chrono::Utc::now().timestamp(),
        nonce,
        client_state: client_state.map(|s| s.to_string()),
    };

    let payload_json = serde_json::to_vec(&payload).map_err(|_| ApiError::Internal)?;
    let payload_b64 = URL_SAFE_NO_PAD.encode(&payload_json);

    let mut mac = Hmac::<Sha256>::new_from_slice(jwt_secret.as_bytes()).map_err(|_| ApiError::Internal)?;
    mac.update(payload_b64.as_bytes());
    let sig = mac.finalize().into_bytes();
    let sig_b64 = URL_SAFE_NO_PAD.encode(sig);

    Ok(format!("{}.{}", payload_b64, sig_b64))
}

pub fn verify_state(jwt_secret: &str, state: &str) -> Result<(), ApiError> {
    let (payload_b64, sig_b64) = state.split_once('.').ok_or(ApiError::Unauthorized)?;
    let sig = URL_SAFE_NO_PAD
        .decode(sig_b64)
        .map_err(|_| ApiError::Unauthorized)?;

    let mut mac = Hmac::<Sha256>::new_from_slice(jwt_secret.as_bytes()).map_err(|_| ApiError::Internal)?;
    mac.update(payload_b64.as_bytes());
    mac.verify_slice(&sig).map_err(|_| ApiError::Unauthorized)?;

    let payload_json = URL_SAFE_NO_PAD
        .decode(payload_b64)
        .map_err(|_| ApiError::Unauthorized)?;
    let payload: StatePayload = serde_json::from_slice(&payload_json).map_err(|_| ApiError::Unauthorized)?;

    let now = chrono::Utc::now().timestamp();
    if payload.ts + STATE_TTL_SECS < now {
        return Err(ApiError::Unauthorized);
    }

    Ok(())
}
