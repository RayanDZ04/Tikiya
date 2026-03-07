use axum::{extract::{Query, State}, Json};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::error::ApiError;
use crate::security::AuthUser;
use crate::state::AppState;

// ─── Guard: admin only ────────────────────────────────────────────────────────
async fn require_admin(state: &AppState, user_id: Uuid) -> Result<(), ApiError> {
    #[derive(sqlx::FromRow)]
    struct RoleRow { role: String }
    let row = sqlx::query_as::<_, RoleRow>("SELECT role FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_one(&state.db.pool)
        .await?;
    if row.role != "admin" {
        return Err(ApiError::Unauthorized);
    }
    Ok(())
}

// ─── GET /admin/stats ─────────────────────────────────────────────────────────
#[derive(Serialize)]
pub struct AdminStats {
    pub total_users: i64,
    pub new_users_today: i64,
    pub total_tickets_sold: i64,
    pub active_events: i64,
    pub total_revenue_dzd: i64,
    pub pending_tickets: i64,
}

pub async fn get_stats(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<AdminStats>, ApiError> {
    require_admin(&state, auth.user_id).await?;

    #[derive(sqlx::FromRow)]
    struct Counts {
        total_users: i64,
        new_users_today: i64,
        total_tickets_sold: i64,
        active_events: i64,
        total_revenue_dzd: i64,
        pending_tickets: i64,
    }

    let row = sqlx::query_as::<_, Counts>(r#"
        SELECT
            (SELECT COUNT(*) FROM users)::bigint                           AS total_users,
            (SELECT COUNT(*) FROM users WHERE created_at >= NOW() - INTERVAL '1 day')::bigint AS new_users_today,
            (SELECT COUNT(*) FROM tickets WHERE status = 'paid')::bigint   AS total_tickets_sold,
            (SELECT COUNT(*) FROM events WHERE event_date >= NOW())::bigint AS active_events,
            (SELECT COALESCE(SUM(amount), 0) FROM tickets WHERE status = 'paid')::bigint AS total_revenue_dzd,
            (SELECT COUNT(*) FROM tickets WHERE status = 'pending')::bigint AS pending_tickets
    "#)
    .fetch_one(&state.db.pool)
    .await?;

    Ok(Json(AdminStats {
        total_users: row.total_users,
        new_users_today: row.new_users_today,
        total_tickets_sold: row.total_tickets_sold,
        active_events: row.active_events,
        total_revenue_dzd: row.total_revenue_dzd,
        pending_tickets: row.pending_tickets,
    }))
}

// ─── GET /admin/users ─────────────────────────────────────────────────────────
#[derive(Deserialize)]
pub struct PaginationQuery {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub search: Option<String>,
}

#[derive(Serialize, sqlx::FromRow)]
pub struct AdminUser {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub role: String,
    pub email_verified: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct AdminUsersResponse {
    pub users: Vec<AdminUser>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
}

pub async fn get_users(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<PaginationQuery>,
) -> Result<Json<AdminUsersResponse>, ApiError> {
    require_admin(&state, auth.user_id).await?;

    let page = q.page.unwrap_or(1).max(1);
    let limit = q.limit.unwrap_or(20).clamp(1, 100);
    let offset = (page - 1) * limit;

    let (users, total) = if let Some(search) = &q.search {
        let pattern = format!("%{}%", search.to_lowercase());
        let users = sqlx::query_as::<_, AdminUser>(
            "SELECT id, email, username, role, email_verified, created_at FROM users \
             WHERE LOWER(email) LIKE $1 OR LOWER(COALESCE(username,'')) LIKE $1 \
             ORDER BY created_at DESC LIMIT $2 OFFSET $3",
        )
        .bind(&pattern)
        .bind(limit)
        .bind(offset)
        .fetch_all(&state.db.pool)
        .await?;

        let total: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM users WHERE LOWER(email) LIKE $1 OR LOWER(COALESCE(username,'')) LIKE $1",
        )
        .bind(&pattern)
        .fetch_one(&state.db.pool)
        .await?;

        (users, total.0)
    } else {
        let users = sqlx::query_as::<_, AdminUser>(
            "SELECT id, email, username, role, email_verified, created_at FROM users \
             ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        )
        .bind(limit)
        .bind(offset)
        .fetch_all(&state.db.pool)
        .await?;

        let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM users")
            .fetch_one(&state.db.pool)
            .await?;

        (users, total.0)
    };

    Ok(Json(AdminUsersResponse { users, total, page, limit }))
}

// ─── GET /admin/events ────────────────────────────────────────────────────────
#[derive(Serialize)]
pub struct AdminEvent {
    pub id: Uuid,
    pub title: String,
    pub location: String,
    pub event_date: DateTime<Utc>,
    pub price: f64,
    pub capacity: i32,
    pub tickets_sold: i64,
    pub tickets_pending: i64,
    pub revenue_dzd: i64,
    pub created_at: DateTime<Utc>,
}

#[derive(sqlx::FromRow)]
struct AdminEventRow {
    id: Uuid,
    title: String,
    location: String,
    event_date: DateTime<Utc>,
    price: f64,
    capacity: i32,
    tickets_sold: Option<i64>,
    tickets_pending: Option<i64>,
    revenue_dzd: Option<i64>,
    created_at: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct AdminEventsResponse {
    pub events: Vec<AdminEvent>,
    pub total: i64,
}

pub async fn get_events(
    State(state): State<AppState>,
    auth: AuthUser,
    Query(q): Query<PaginationQuery>,
) -> Result<Json<AdminEventsResponse>, ApiError> {
    require_admin(&state, auth.user_id).await?;

    let page = q.page.unwrap_or(1).max(1);
    let limit = q.limit.unwrap_or(50).clamp(1, 200);
    let offset = (page - 1) * limit;

    let rows = sqlx::query_as::<_, AdminEventRow>(r#"
        SELECT
            e.id, e.title, e.location, e.event_date, e.price, e.capacity, e.created_at,
            COUNT(t.id) FILTER (WHERE t.status = 'paid')    AS tickets_sold,
            COUNT(t.id) FILTER (WHERE t.status = 'pending') AS tickets_pending,
            COALESCE(SUM(t.amount) FILTER (WHERE t.status = 'paid'), 0)::bigint AS revenue_dzd
        FROM events e
        LEFT JOIN tickets t ON t.event_id = e.id
        GROUP BY e.id
        ORDER BY e.event_date DESC
        LIMIT $1 OFFSET $2
    "#)
    .bind(limit)
    .bind(offset)
    .fetch_all(&state.db.pool)
    .await?;

    let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM events")
        .fetch_one(&state.db.pool)
        .await?;

    let events = rows.into_iter().map(|r| AdminEvent {
        id: r.id,
        title: r.title,
        location: r.location,
        event_date: r.event_date,
        price: r.price,
        capacity: r.capacity,
        tickets_sold: r.tickets_sold.unwrap_or(0),
        tickets_pending: r.tickets_pending.unwrap_or(0),
        revenue_dzd: r.revenue_dzd.unwrap_or(0),
        created_at: r.created_at,
    }).collect();

    Ok(Json(AdminEventsResponse { events, total: total.0 }))
}

// ─── GET /admin/activity ──────────────────────────────────────────────────────
#[derive(Serialize)]
pub struct ActivityItem {
    pub kind: String,      // "signup" | "ticket" | "event"
    pub label: String,
    pub sub: String,
    pub at: DateTime<Utc>,
}

pub async fn get_activity(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<ActivityItem>>, ApiError> {
    require_admin(&state, auth.user_id).await?;

    // Recent signups
    #[derive(sqlx::FromRow)]
    struct SignupRow { email: String, created_at: DateTime<Utc> }
    let signups = sqlx::query_as::<_, SignupRow>(
        "SELECT email, created_at FROM users ORDER BY created_at DESC LIMIT 5",
    )
    .fetch_all(&state.db.pool)
    .await?;

    // Recent ticket purchases
    #[derive(sqlx::FromRow)]
    struct TicketRow {
        user_email: String,
        event_title: String,
        amount: i32,
        created_at: DateTime<Utc>,
    }
    let tickets = sqlx::query_as::<_, TicketRow>(r#"
        SELECT u.email AS user_email, e.title AS event_title,
               t.amount, t.created_at
        FROM tickets t
        JOIN users u ON u.id = t.user_id
        JOIN events e ON e.id = t.event_id
        WHERE t.status = 'paid'
        ORDER BY t.created_at DESC
        LIMIT 5
    "#)
    .fetch_all(&state.db.pool)
    .await?;

    // Recent event creations
    #[derive(sqlx::FromRow)]
    struct EventRow { title: String, location: String, created_at: DateTime<Utc> }
    let events_created = sqlx::query_as::<_, EventRow>(
        "SELECT title, location, created_at FROM events ORDER BY created_at DESC LIMIT 5",
    )
    .fetch_all(&state.db.pool)
    .await?;

    let mut items: Vec<ActivityItem> = Vec::new();

    for s in signups {
        items.push(ActivityItem {
            kind: "signup".into(),
            label: format!("Nouveau compte : {}", s.email),
            sub: "Inscription".into(),
            at: s.created_at,
        });
    }
    for t in tickets {
        items.push(ActivityItem {
            kind: "ticket".into(),
            label: format!("{} — {} DZD", t.event_title, t.amount),
            sub: format!("Acheté par {}", t.user_email),
            at: t.created_at,
        });
    }
    for e in events_created {
        items.push(ActivityItem {
            kind: "event".into(),
            label: format!("Événement : {}", e.title),
            sub: e.location,
            at: e.created_at,
        });
    }

    items.sort_by(|a, b| b.at.cmp(&a.at));
    items.truncate(15);

    Ok(Json(items))
}

// ─── GET /admin/daily-stats ───────────────────────────────────────────────────
#[derive(Serialize, sqlx::FromRow)]
pub struct DayStats {
    pub date: String,
    pub signups: Option<i64>,
    pub tickets_sold: Option<i64>,
    pub revenue_dzd: Option<i64>,
}

pub async fn get_daily_stats(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<DayStats>>, ApiError> {
    require_admin(&state, auth.user_id).await?;

    let rows = sqlx::query_as::<_, DayStats>(r#"
        WITH days AS (
            SELECT generate_series(
                (NOW() - INTERVAL '29 days')::date,
                NOW()::date,
                '1 day'::interval
            )::date AS d
        )
        SELECT
            TO_CHAR(d, 'YYYY-MM-DD') AS date,
            COUNT(DISTINCT u.id)      AS signups,
            COUNT(DISTINCT CASE WHEN t.status = 'paid' THEN t.id END) AS tickets_sold,
            COALESCE(SUM(CASE WHEN t.status = 'paid' THEN t.amount ELSE 0 END), 0)::bigint AS revenue_dzd
        FROM days
        LEFT JOIN users u  ON u.created_at::date  = d
        LEFT JOIN tickets t ON t.created_at::date = d
        GROUP BY d
        ORDER BY d ASC
    "#)
    .fetch_all(&state.db.pool)
    .await?;

    Ok(Json(rows))
}
