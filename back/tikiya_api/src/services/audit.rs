//! Append-only audit trail for sensitive actions.
//!
//! Fire-and-forget: a failure to write an audit row is logged but never blocks
//! or fails the underlying action (auditing must not break the feature).

use serde_json::Value;
use uuid::Uuid;

use crate::state::AppState;

/// Records one audit entry. Best-effort — errors are logged, not propagated.
pub async fn record(
    state: &AppState,
    actor_id: Option<Uuid>,
    action: &str,
    target_type: Option<&str>,
    target_id: Option<&str>,
    ip: Option<&str>,
    metadata: Option<Value>,
) {
    let res = sqlx::query(
        "INSERT INTO audit_log (actor_id, action, target_type, target_id, ip, metadata)
         VALUES ($1, $2, $3, $4, $5, $6)",
    )
    .bind(actor_id)
    .bind(action)
    .bind(target_type)
    .bind(target_id)
    .bind(ip)
    .bind(metadata)
    .execute(&state.db.pool)
    .await;

    if let Err(e) = res {
        tracing::error!(error = %e, action = action, "audit.write_failed");
    } else {
        tracing::info!(action = action, actor = ?actor_id, "audit.recorded");
    }
}
