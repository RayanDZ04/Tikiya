use axum::{extract::State, http::HeaderMap, response::Html, Json};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::ApiError;
use crate::state::AppState;

const CHARGILY_TEST_URL: &str = "https://pay.chargily.net/test/api/v2";

// ─── JWT helper ───────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
struct JwtClaims {
    sub: Uuid,
}

fn extract_user(headers: &HeaderMap, state: &AppState) -> Result<Uuid, ApiError> {
    let auth = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::Unauthorized)?;
    let token = auth.strip_prefix("Bearer ").ok_or(ApiError::Unauthorized)?;
    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_audience(std::slice::from_ref(&state.config.jwt_audience));
    validation.set_issuer(std::slice::from_ref(&state.config.jwt_issuer));
    let data = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(state.config.jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|_| ApiError::Unauthorized)?;
    Ok(data.claims.sub)
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
    headers: HeaderMap,
    Json(req): Json<CreateCheckoutRequest>,
) -> Result<Json<CreateCheckoutResponse>, ApiError> {
    let user_id = extract_user(&headers, &state)?;

    // Fetch event price & title
    #[derive(sqlx::FromRow)]
    struct EventRow {
        title: String,
        price: f64,
        capacity: i32,
    }

    let event = sqlx::query_as::<_, EventRow>(
        "SELECT title, COALESCE(price, 0.0) AS price, COALESCE(capacity, 0) AS capacity FROM events WHERE id = $1",
    )
    .bind(req.event_id)
    .fetch_optional(&state.db.pool)
    .await?
    .ok_or(ApiError::NotFound)?;

    // Chargily requires integer DZD (whole number)
    let amount = (event.price as i64).max(100); // minimum 100 DZD

    // ── Enforce 5-ticket limit per participant per event ──────────────────────
    let existing: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM tickets WHERE event_id = $1 AND user_id = $2 AND status NOT IN ('failed','canceled')",
    )
    .bind(req.event_id)
    .bind(user_id)
    .fetch_one(&state.db.pool)
    .await?;

    if existing >= 5 {
        return Err(ApiError::Validation(
            "Vous ne pouvez pas acheter plus de 5 billets pour le même événement.".to_string(),
        ));
    }

    // Create a pending ticket record first so we have an ID for metadata
    // Use gen_random_uuid() as temporary checkout_id (unique placeholder)
    let ticket_id: Uuid = sqlx::query_scalar(
        "INSERT INTO tickets (event_id, user_id, checkout_id, status, amount, currency, payment_method)
         VALUES ($1, $2, gen_random_uuid()::text, 'pending', $3, 'dzd', $4)
         RETURNING id",
    )
    .bind(req.event_id)
    .bind(user_id)
    .bind(amount as i32)
    .bind(&req.payment_method)
    .fetch_one(&state.db.pool)
    .await?;

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

    let body = ChargilyCheckoutBody {
        amount,
        currency: "dzd",
        payment_method: req.payment_method.clone(),
        success_url: format!("{}/payments/success?ticket={}", base, ticket_id),
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
        // Dev fallback: update the placeholder checkout_id
        sqlx::query("UPDATE tickets SET checkout_id = $1 WHERE id = $2")
            .bind(format!("mock-{}", ticket_id))
            .bind(ticket_id)
            .execute(&state.db.pool)
            .await?;

        return Ok(Json(CreateCheckoutResponse {
            ticket_id,
            checkout_url: format!("https://pay.chargily.dz/test/mock/{}", ticket_id),
        }));    }

    let client = Client::new();
    let chargily_resp = client
        .post(format!("{}/checkouts", CHARGILY_TEST_URL))
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
    Json(payload): Json<ChargilyWebhookPayload>,
) -> Result<axum::http::StatusCode, ApiError> {
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
    headers: HeaderMap,
) -> Result<Json<Vec<TicketResponse>>, ApiError> {
    let user_id = extract_user(&headers, &state)?;

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
    headers: HeaderMap,
    axum::extract::Path(event_id): axum::extract::Path<Uuid>,
) -> Result<Json<EventTicketStats>, ApiError> {
    // Auth required (any logged-in user)
    let _user_id = extract_user(&headers, &state)?;

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

// ─── GET /payments/success  — redirect HTML → tikiya://payment/success ─────────
/// Chargily redirige le navigateur ici après un paiement réussi.
/// On marque directement le billet comme payé (utile en dev sans webhook).
pub async fn payment_success(
    State(state): State<AppState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Html<String> {
    let ticket_str = params.get("ticket").map(|s| s.as_str()).unwrap_or("");

    // Mark ticket as paid — Chargily only reaches this URL on actual success.
    if let Ok(ticket_id) = uuid::Uuid::parse_str(ticket_str) {
        let _ = sqlx::query(
            "UPDATE tickets SET status = 'paid', updated_at = now() WHERE id = $1 AND status = 'pending'",
        )
        .bind(ticket_id)
        .execute(&state.db.pool)
        .await;
    }

    Html(redirect_page(
        &format!("tikiya://payment/success?ticket={}", ticket_str),
        "Paiement confirmé",
        "Votre billet est prêt. Retour à l'application...",
        "#43A047",
        "✓",
    ))
}

// ─── GET /payments/failure  — redirect HTML → tikiya://payment/failure ─────────
pub async fn payment_failure(
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Html<String> {
    let ticket = params.get("ticket").map(|s| s.as_str()).unwrap_or("");
    Html(redirect_page(
        &format!("tikiya://payment/failure?ticket={}", ticket),
        "Paiement échoué",
        "Le paiement n'a pas abouti. Retour à l'application...",
        "#EF5350",
        "✗",
    ))
}

fn redirect_page(deep_link: &str, title: &str, message: &str, color: &str, icon: &str) -> String {
    format!(
        r#"<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{title}</title>
  <meta http-equiv="refresh" content="1;url={deep_link}" />
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
      background: #0B1C3E;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex; align-items: center; justify-content: center;
      min-height: 100vh;
    }}
    .card {{
      background: white;
      border-radius: 24px;
      padding: 40px 32px;
      text-align: center;
      max-width: 320px;
      width: 90%;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }}
    .icon {{
      width: 80px; height: 80px;
      background: {color}1a;
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 20px;
      font-size: 40px; color: {color};
    }}
    h1 {{ color: #0B1C3E; font-size: 20px; margin-bottom: 10px; }}
    p {{ color: #607D8B; font-size: 14px; line-height: 1.6; margin-bottom: 24px; }}
    a {{
      display: block; background: #0B1C3E; color: white;
      text-decoration: none; padding: 14px 24px;
      border-radius: 12px; font-weight: 700; font-size: 14px;
    }}
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">{icon}</div>
    <h1>{title}</h1>
    <p>{message}</p>
    <a href="{deep_link}">Retour à l'application</a>
  </div>
  <script>
    setTimeout(function() {{ window.location.href = "{deep_link}"; }}, 800);
  </script>
</body>
</html>"#
    )
}
