use axum::{body::Bytes, extract::State, http::HeaderMap, response::Html, Json};
use serde::{Deserialize, Serialize};
use sha2::Sha512;
use uuid::Uuid;

use crate::error::ApiError;
use crate::security::AuthUser;
use crate::state::AppState;

/// Signs `sig` in success redirect URLs to prevent forging paid tickets.
fn sign_ticket_url(ticket_id: Uuid, secret: &str) -> String {
    use hmac::{Hmac, Mac};
    type HmacSha256 = Hmac<sha2::Sha256>;
    let mut mac = HmacSha256::new_from_slice(secret.as_bytes()).expect("HMAC key");
    mac.update(ticket_id.as_bytes());
    let bytes = mac.finalize().into_bytes();
    bytes[..16].iter().fold(String::new(), |mut s, b| {
        use std::fmt::Write;
        let _ = write!(s, "{:02x}", b);
        s
    })
}

/// Verifies the Chargily webhook HMAC-SHA512 signature.
fn verify_chargily_signature(payload: &[u8], signature: &str, api_key: &str) -> bool {
    use hmac::{Hmac, Mac};
    type HmacSha512 = Hmac<Sha512>;
    let mut mac = match HmacSha512::new_from_slice(api_key.as_bytes()) {
        Ok(m) => m,
        Err(_) => return false,
    };
    mac.update(payload);
    let result = mac.finalize().into_bytes();
    let expected: String = result.iter().fold(String::new(), |mut s, b| {
        use std::fmt::Write;
        let _ = write!(s, "{:02x}", b);
        s
    });
    expected.len() == signature.len()
        && expected.bytes().zip(signature.bytes()).all(|(a, b)| a == b)
}


// ─── Request / Response DTOs ─────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct CreateCheckoutRequest {
    pub event_id: Uuid,
    /// "edahabia" | "cib"  (default: "edahabia")
    #[serde(default = "default_pm")]
    pub payment_method: String,
}

fn default_pm() -> String {
    "edahabia".to_string()
}

#[derive(Serialize)]
pub struct CreateCheckoutResponse {
    pub ticket_id: Uuid,
    pub checkout_url: String,
}

// ─── Chargily API types ───────────────────────────────────────────────────────

#[derive(Serialize)]
struct ChargilyCheckoutBody {
    amount: i64,
    currency: &'static str,
    payment_method: String,
    success_url: String,
    failure_url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    webhook_endpoint: Option<String>,
    locale: &'static str,
    description: String,
    metadata: ChargilyMeta,
}

#[derive(Serialize)]
struct ChargilyMeta {
    ticket_id: String,
    event_id: String,
    user_id: String,
}

#[derive(Deserialize)]
struct ChargilyCheckoutResponse {
    checkout_url: String,
}

// ─── POST /payments/checkout ──────────────────────────────────────────────────
pub async fn create_checkout(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<CreateCheckoutRequest>,
) -> Result<Json<CreateCheckoutResponse>, ApiError> {
    let user_id = auth.user_id;

    // Atomic capacity + per-user limit check inside a DB transaction.
    // SELECT FOR UPDATE locks the event row, preventing concurrent oversells.
    let mut tx = state.db.pool.begin().await?;

    #[derive(sqlx::FromRow)]
    struct EventRow {
        title: String,
        price: f64,
        capacity: i32,
    }

    let event = sqlx::query_as::<_, EventRow>(
        "SELECT title, COALESCE(price, 0.0) AS price, COALESCE(capacity, 0) AS capacity \
         FROM events WHERE id = $1 FOR UPDATE",
    )
    .bind(req.event_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(ApiError::from)?
    .ok_or(ApiError::NotFound)?;

    // Chargily requires integer DZD (whole number)
    let amount = (event.price as i64).max(100); // minimum 100 DZD

    // Enforce 5-ticket limit per participant per event
    let existing: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM tickets WHERE event_id = $1 AND user_id = $2 AND status NOT IN ('failed','canceled')",
    )
    .bind(req.event_id)
    .bind(user_id)
    .fetch_one(&mut *tx)
    .await
    .map_err(ApiError::from)?;

    if existing >= 5 {
        let _ = tx.rollback().await;
        return Err(ApiError::Validation(
            "Vous ne pouvez pas acheter plus de 5 billets pour le même événement.".to_string(),
        ));
    }

    // Enforce event capacity (0 = unlimited)
    if event.capacity > 0 {
        let total_sold: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM tickets WHERE event_id = $1 AND status NOT IN ('failed','canceled')",
        )
        .bind(req.event_id)
        .fetch_one(&mut *tx)
        .await
        .map_err(ApiError::from)?;

        if total_sold >= event.capacity as i64 {
            let _ = tx.rollback().await;
            return Err(ApiError::Validation("Cet événement est complet.".into()));
        }
    }

    // Create a pending ticket record first so we have an ID for metadata
    let ticket_id: Uuid = sqlx::query_scalar(
        "INSERT INTO tickets (event_id, user_id, checkout_id, status, amount, currency, payment_method)
         VALUES ($1, $2, gen_random_uuid()::text, 'pending', $3, 'dzd', $4)
         RETURNING id",
    )
    .bind(req.event_id)
    .bind(user_id)
    .bind(amount as i32)
    .bind(&req.payment_method)
    .fetch_one(&mut *tx)
    .await
    .map_err(ApiError::from)?;

    tx.commit().await.map_err(ApiError::from)?;

    let base = &state.config.public_base_url;
    // Only send webhook if the base URL is publicly reachable (not localhost / 10.x)
    let is_local = base.contains("localhost")
        || base.contains("127.0.0.1")
        || base.contains("10.0.2.2");
    let webhook = if is_local {
        None
    } else {
        Some(format!("{}/payments/webhook", base))
    };

    // Sign the success URL to prevent anyone from marking tickets paid arbitrarily
    let sig = sign_ticket_url(ticket_id, &state.config.jwt_secret);
    let body = ChargilyCheckoutBody {
        amount,
        currency: "dzd",
        payment_method: req.payment_method.clone(),
        success_url: format!("{}/payments/success?ticket={}&sig={}", base, ticket_id, sig),
        failure_url: format!("{}/payments/failure?ticket={}", base, ticket_id),
        webhook_endpoint: webhook,
        locale: "fr",
        description: format!("Billet – {}", event.title),
        metadata: ChargilyMeta {
            ticket_id: ticket_id.to_string(),
            event_id: req.event_id.to_string(),
            user_id: user_id.to_string(),
        },
    };

    if state.config.chargily_api_key.is_empty() {
        tracing::warn!("CHARGILY_API_KEY not set – returning mock checkout URL");
        sqlx::query("UPDATE tickets SET checkout_id = $1 WHERE id = $2")
            .bind(format!("mock-{}", ticket_id))
            .bind(ticket_id)
            .execute(&state.db.pool)
            .await?;

        return Ok(Json(CreateCheckoutResponse {
            ticket_id,
            checkout_url: format!("https://pay.chargily.dz/test/mock/{}", ticket_id),
        }));
    }

    let chargily_resp = state
        .http_client
        .post(format!("{}/checkouts", state.config.chargily_base_url))
        .bearer_auth(&state.config.chargily_api_key)
        .json(&body)
        .send()
        .await
        .map_err(|e| {
            tracing::error!(error = ?e, "chargily.request.failed");
            ApiError::ServiceUnavailable
        })?;

    if !chargily_resp.status().is_success() {
        let status = chargily_resp.status();
        let text = chargily_resp.text().await.unwrap_or_default();
        tracing::error!(status = %status, body = %text, "chargily.error");
        return Err(ApiError::ServiceUnavailable);
    }

    let chargily_data: ChargilyCheckoutResponse = chargily_resp.json().await.map_err(|e| {
        tracing::error!(error = ?e, "chargily.parse.failed");
        ApiError::Internal
    })?;

    // Update checkout_id with the real Chargily ID (extracted from URL)
    let checkout_id = chargily_data
        .checkout_url
        .rsplit('/')
        .nth(1) // …/checkouts/{id}/pay
        .unwrap_or("unknown")
        .to_string();

    sqlx::query("UPDATE tickets SET checkout_id = $1 WHERE id = $2")
        .bind(&checkout_id)
        .bind(ticket_id)
        .execute(&state.db.pool)
        .await?;

    Ok(Json(CreateCheckoutResponse {
        ticket_id,
        checkout_url: chargily_data.checkout_url,
    }))
}

// ─── POST /payments/webhook ───────────────────────────────────────────────────
/// Chargily sends this when a checkout status changes.
/// Body: { id, entity, status, metadata: { ticket_id, ... }, ... }
#[derive(Debug, Deserialize)]
pub struct ChargilyWebhookPayload {
    pub id: String,
    pub status: String,
    pub payment_method: Option<String>,
    pub metadata: Option<serde_json::Value>,
}

pub async fn payment_webhook(
    State(state): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Result<axum::http::StatusCode, ApiError> {
    // HMAC-SHA512 signature check (Chargily Pay v2). Skipped in dev without API key.
    if !state.config.chargily_api_key.is_empty() {
        let sig = headers
            .get("signature")
            .and_then(|v| v.to_str().ok())
            .ok_or_else(|| {
                tracing::warn!("webhook.signature_missing");
                ApiError::Unauthorized
            })?;
        if !verify_chargily_signature(&body, sig, &state.config.chargily_api_key) {
            tracing::warn!(signature = %sig, "webhook.signature_invalid");
            return Err(ApiError::Unauthorized);
        }
    }

    let payload: ChargilyWebhookPayload = serde_json::from_slice(&body).map_err(|e| {
        tracing::error!(error = ?e, "webhook.parse_failed");
        ApiError::Validation("invalid webhook payload".into())
    })?;

    tracing::info!(checkout = %payload.id, status = %payload.status, "webhook.received");

    // Resolve ticket_id from metadata or directly from checkout_id column
    let ticket_id: Option<Uuid> = if let Some(meta) = &payload.metadata {
        meta.get("ticket_id")
            .and_then(|v| v.as_str())
            .and_then(|s| s.parse().ok())
    } else {
        None
    };

    let updated = if let Some(tid) = ticket_id {
        sqlx::query(
            "UPDATE tickets SET status = $1, payment_method = COALESCE($2, payment_method), updated_at = now()
             WHERE id = $3",
        )
        .bind(&payload.status)
        .bind(payload.payment_method.as_deref())
        .bind(tid)
        .execute(&state.db.pool)
        .await?
        .rows_affected()
    } else {
        // Fall back to checkout_id
        sqlx::query(
            "UPDATE tickets SET status = $1, payment_method = COALESCE($2, payment_method), updated_at = now()
             WHERE checkout_id = $3",
        )
        .bind(&payload.status)
        .bind(payload.payment_method.as_deref())
        .bind(&payload.id)
        .execute(&state.db.pool)
        .await?
        .rows_affected()
    };

    tracing::info!(rows_affected = updated, "webhook.processed");
    Ok(axum::http::StatusCode::OK)
}

// ─── GET /payments/my ────────────────────────────────────────────────────────
/// Returns the list of tickets for the current user.
#[derive(sqlx::FromRow, Serialize)]
pub struct TicketResponse {
    pub id: Uuid,
    pub event_id: Uuid,
    pub checkout_id: String,
    pub status: String,
    pub amount: i32,
    pub currency: String,
    pub payment_method: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

pub async fn my_tickets(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<TicketResponse>>, ApiError> {
    let user_id = auth.user_id;

    let tickets = sqlx::query_as::<_, TicketResponse>(
        "SELECT id, event_id, checkout_id, status, amount, currency, payment_method, created_at
         FROM tickets WHERE user_id = $1 ORDER BY created_at DESC",
    )
    .bind(user_id)
    .fetch_all(&state.db.pool)
    .await?;

    Ok(Json(tickets))
}

// ─── GET /payments/event/:event_id — count paid tickets (organisateur) ────────
#[derive(Serialize)]
pub struct EventTicketStats {
    pub event_id: Uuid,
    pub sold: i64,
    pub revenue: i64,
}

pub async fn event_ticket_stats(
    State(state): State<AppState>,
    auth: AuthUser,
    axum::extract::Path(event_id): axum::extract::Path<Uuid>,
) -> Result<Json<EventTicketStats>, ApiError> {
    // Auth required (any logged-in user)
    let _user_id = auth.user_id;

    #[derive(sqlx::FromRow)]
    struct Row {
        sold: Option<i64>,
        revenue: Option<i64>,
    }

    let row = sqlx::query_as::<_, Row>(
        "SELECT COUNT(*) AS sold, COALESCE(SUM(amount), 0) AS revenue
         FROM tickets WHERE event_id = $1 AND status = 'paid'",
    )
    .bind(event_id)
    .fetch_one(&state.db.pool)
    .await?;

    Ok(Json(EventTicketStats {
        event_id,
        sold: row.sold.unwrap_or(0),
        revenue: row.revenue.unwrap_or(0),
    }))
}

// ─── GET /payments/success  — HTML → intent:// → tikiya://payment/success ───────
/// Chargily redirige le navigateur ici après un paiement réussi.
/// On marque directement le billet comme payé (utile en dev sans webhook).
/// La page utilise le scheme intent:// (Android Chrome API) pour rouvrir l'app.
pub async fn payment_success(
    State(state): State<AppState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Html<String> {
    let ticket_str = params.get("ticket").cloned().unwrap_or_default();
    let sig = params.get("sig").cloned().unwrap_or_default();

    // Only mark as paid if the HMAC signature matches.
    // This prevents hitting /payments/success?ticket=<uuid> to forge a paid ticket.
    if let Ok(ticket_id) = uuid::Uuid::parse_str(&ticket_str) {
        let expected = sign_ticket_url(ticket_id, &state.config.jwt_secret);
        if sig == expected {
            let _ = sqlx::query(
                "UPDATE tickets SET status = 'paid', updated_at = now() WHERE id = $1 AND status = 'pending'",
            )
            .bind(ticket_id)
            .execute(&state.db.pool)
            .await;
        } else {
            tracing::warn!(ticket_id = %ticket_id, "payment_success.invalid_signature");
        }
    }

    Html(redirect_page(
        &format!("tikiya://payment/success?ticket={}", ticket_str),
        "Paiement confirmé",
        "Votre billet est prêt. Retour à l'application...",
        "#43A047",
        "✓",
    ))
}

// ─── GET /payments/failure  — HTML → intent:// → tikiya://payment/failure ────────
/// La page utilise le scheme intent:// (Android Chrome API) pour rouvrir l'app.
pub async fn payment_failure(
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Html<String> {
    let ticket = params.get("ticket").cloned().unwrap_or_default();
    Html(redirect_page(
        &format!("tikiya://payment/failure?ticket={}", ticket),
        "Paiement échoué",
        "Le paiement n'a pas abouti. Retour à l'application...",
        "#EF5350",
        "✗",
    ))
}

fn redirect_page(deep_link: &str, title: &str, message: &str, color: &str, _icon: &str) -> String {
    let intent_link = if let Some(path) = deep_link.strip_prefix("tikiya://") {
        format!("intent://{}#Intent;scheme=tikiya;package=com.tikiya;end", path)
    } else {
        deep_link.to_string()
    };
    let is_success = color == "#43A047";

    // Build confetti HTML separately (no format! conflict)
    let confetti_html = if is_success {
        let palette = ["#00ACC1","#43A047","#FFD600","#ffffff","#FF4081","#7C4DFF"];
        let mut out = String::from(r#"<div style="position:fixed;inset:0;pointer-events:none;overflow:hidden;z-index:0">"#);
        for i in 0..50usize {
            let c = palette[i % palette.len()];
            let left = (i * 1637 + 11) % 100;
            let dur  = 2200 + (i * 137 % 1800);
            let del  = (i * 83 % 1400) as f32 / 1000.0;
            let sz   = 6 + (i % 5);
            let anim = format!(
                "position:absolute;top:-12px;border-radius:3px;opacity:0;\
                 left:{left}%;width:{sz}px;height:{sz}px;background:{c};\
                 animation:fall {dur}ms ease-in {del}s forwards",
                left=left, sz=sz, c=c, dur=dur, del=del
            );
            out.push_str(&format!("<div style=\"{}\"></div>", anim));
        }
        out.push_str("</div>");
        out
    } else {
        String::new()
    };

    // SVG icons (static strings, no format args)
    let svg = if is_success {
        concat!(
            r#"<svg width="52" height="52" viewBox="0 0 52 52" fill="none">"#,
            r#"<circle cx="26" cy="26" r="25" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>"#,
            r#"<polyline id="ck" points="14,27 22,35 38,17" stroke="white" stroke-width="3.5""#,
            r#" stroke-linecap="round" stroke-linejoin="round" fill="none"#,
            r#" style="stroke-dasharray:42;stroke-dashoffset:42;animation:draw .5s ease .4s forwards"/>"#,
            r#"</svg>"#
        )
    } else {
        concat!(
            r#"<svg width="52" height="52" viewBox="0 0 52 52" fill="none">"#,
            r#"<circle cx="26" cy="26" r="25" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>"#,
            r#"<line x1="16" y1="16" x2="36" y2="36" stroke="white" stroke-width="3.5" stroke-linecap="round""#,
            r#" style="stroke-dasharray:28;stroke-dashoffset:28;animation:draw .35s ease .4s forwards"/>"#,
            r#"<line x1="36" y1="16" x2="16" y2="36" stroke="white" stroke-width="3.5" stroke-linecap="round""#,
            r#" style="stroke-dasharray:28;stroke-dashoffset:28;animation:draw .35s ease .6s forwards"/>"#,
            r#"</svg>"#
        )
    };

    let badge_label = if is_success { "CONFIRMÉ" } else { "REFUSÉ" };

    // Build HTML — CSS uses NO {placeholders}, all colors are hardcoded via pre-built strings
    let icon_bg   = color;
    let badge_bg  = color;
    let btn_bg    = color;
    let sep_color = color;
    let logo_em   = color;

    let mut html = String::new();
    html.push_str("<!DOCTYPE html>\n<html lang=\"fr\">\n<head>\n");
    html.push_str("  <meta charset=\"UTF-8\"/>\n");
    html.push_str("  <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"/>\n");
    html.push_str("  <title>Tikiya!</title>\n");
    html.push_str("  <style>\n");
    html.push_str("    *{margin:0;padding:0;box-sizing:border-box}\n");
    html.push_str("    html,body{height:100%;}\n");
    html.push_str("    body{\n");
    html.push_str("      font-family:system-ui,-apple-system,sans-serif;\n");
    html.push_str("      background:#0B1C3E;\n");
    html.push_str("      min-height:100%;\n");
    html.push_str("      display:flex;flex-direction:column;\n");
    html.push_str("      align-items:center;justify-content:space-between;\n");
    html.push_str("      padding:0 0 48px;\n");
    html.push_str("    }\n");
    html.push_str("    @keyframes draw{to{stroke-dashoffset:0;}}\n");
    html.push_str("    @keyframes pop{from{transform:scale(0.5);opacity:0;}to{transform:scale(1);opacity:1;}}\n");
    html.push_str("    @keyframes up{from{opacity:0;transform:translateY(18px);}to{opacity:1;transform:translateY(0);}}\n");
    html.push_str("    @keyframes fall{\n");
    html.push_str("      0%{opacity:1;transform:translateY(0) rotate(0deg);}\n");
    html.push_str("      100%{opacity:0;transform:translateY(105vh) rotate(600deg);}\n");
    html.push_str("    }\n");
    html.push_str("  </style>\n");
    html.push_str("</head>\n<body>\n\n");

    // Confetti
    html.push_str(&confetti_html);
    html.push('\n');

    // Top bar
    html.push_str(&format!(
        "  <div style=\"width:100%;padding:28px 28px 0;display:flex;align-items:center;justify-content:space-between;position:relative;z-index:1\">\n\
             <div style=\"font-size:22px;font-weight:800;color:#fff;letter-spacing:-0.3px\">Tikiya<em style=\"color:{logo_em};font-style:normal\">!</em></div>\n\
             <div style=\"font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:#0B1C3E;background:{badge_bg};padding:5px 13px;border-radius:20px\">{badge_label}</div>\n\
         </div>\n\n",
        logo_em=logo_em, badge_bg=badge_bg, badge_label=badge_label
    ));

    // Main center content
    html.push_str("  <div style=\"flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:0 32px;position:relative;z-index:1;text-align:center\">\n\n");

    // Icon ring
    html.push_str(&format!(
        "    <div style=\"width:96px;height:96px;border-radius:50%;background:{icon_bg};\
         display:flex;align-items:center;justify-content:center;\
         box-shadow:0 0 0 14px rgba(0,0,0,0.15);\
         margin-bottom:32px;\
         animation:pop .5s cubic-bezier(.34,1.56,.64,1) .1s both\">\n      {svg}\n    </div>\n\n",
        icon_bg=icon_bg, svg=svg
    ));

    // Title
    html.push_str(&format!(
        "    <h1 style=\"font-size:28px;font-weight:800;color:#ffffff;line-height:1.2;margin-bottom:12px;\
         animation:up .4s ease .3s both\">{title}</h1>\n",
        title=title
    ));

    // Subtitle
    html.push_str(&format!(
        "    <p style=\"font-size:15px;color:rgba(255,255,255,0.5);line-height:1.6;max-width:280px;\
         animation:up .4s ease .4s both\">{message}</p>\n",
        message=message
    ));

    // Separator
    html.push_str(&format!(
        "    <div style=\"width:48px;height:3px;border-radius:2px;background:{sep_color};\
         margin:28px 0;animation:up .4s ease .45s both\"></div>\n",
        sep_color=sep_color
    ));

    html.push_str("  </div>\n\n");

    // CTA block
    html.push_str(&format!(
        "  <div style=\"width:100%;max-width:360px;padding:0 28px;position:relative;z-index:1;animation:up .4s ease .5s both\">\n\
         <a href=\"{intent_link}\" style=\"display:block;width:100%;background:{btn_bg};color:#fff;\
         text-decoration:none;text-align:center;padding:18px 24px;border-radius:18px;\
         font-size:16px;font-weight:700;letter-spacing:0.3px\">Retour à l'application</a>\n\
         <p style=\"margin-top:14px;text-align:center;font-size:13px;color:rgba(255,255,255,0.3)\">\
         Redirection dans <b style=\"color:rgba(255,255,255,0.55)\"><span id=\"s\">5</span>s</b></p>\n\
         </div>\n\n",
        intent_link=intent_link, btn_bg=btn_bg
    ));

    // Script
    html.push_str(&format!(
        "<script>\n(function(){{\n\
           window.location.href=\"{link}\";\n\
           var n=5,e=document.getElementById(\"s\");\n\
           var t=setInterval(function(){{\n\
             n--;if(e)e.textContent=n;\n\
             if(n<=0){{clearInterval(t);window.location.href=\"{link}\";}}\n\
           }},1000);\n\
         }})();\n</script>\n",
        link=intent_link
    ));

    html.push_str("</body>\n</html>\n");
    html
}
