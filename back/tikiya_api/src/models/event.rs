use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Event {
    pub id: Uuid,
    pub organizer_id: Uuid,
    pub title: String,
    pub description: String,
    pub location: String,
    pub event_date: DateTime<Utc>,
    pub price: f64,
    pub capacity: i32,
    pub cover_url: Option<String>,
    pub created_at: DateTime<Utc>,
}
