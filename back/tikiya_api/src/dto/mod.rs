use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::models::{User, Event};

#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 8, max = 128))]
    pub password: String,
    pub role: Option<String>,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub company: Option<String>,
    pub phone: Option<String>,
    pub website: Option<String>,
}

#[derive(Debug, Deserialize, Validate, Clone)]
pub struct LoginRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 8, max = 128))]
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub role: String,
    pub created_at: DateTime<Utc>,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub username: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AuthTokens {
    pub access_token: String,
    pub refresh_token: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct RefreshRequest {
    #[validate(length(min = 1))]
    pub refresh_token: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct LogoutRequest {
    #[validate(length(min = 1))]
    pub refresh_token: String,
}
#[derive(Debug, Deserialize, Validate)]
pub struct ChangePasswordRequest {
    #[validate(length(min = 8, max = 128))]
    pub current_password: String,
    #[validate(length(min = 8, max = 128))]
    pub new_password: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct ChangeEmailRequest {
    #[validate(length(min = 8, max = 128))]
    pub current_password: String,
    #[validate(email)]
    pub new_email: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct ChangeUsernameRequest {
    #[validate(length(min = 2, max = 50))]
    pub username: String,
}
#[derive(Debug, Deserialize, Validate, Clone)]
pub struct OrganizerNeedsRequest {
    #[validate(length(min = 1, max = 120))]
    pub first_name: String,
    #[validate(length(min = 1, max = 120))]
    pub last_name: String,
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 3, max = 64))]
    pub phone: String,
    #[validate(length(min = 1, max = 255))]
    pub instagram: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: UserResponse,
    pub tokens: AuthTokens,
    pub email_verified: bool,
}

#[derive(Debug, Deserialize, Validate)]
pub struct VerifyEmailRequest {
    #[validate(length(min = 6, max = 6))]
    pub code: String,
}

#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub message: String,
}

impl From<&User> for UserResponse {
    fn from(user: &User) -> Self {
        Self {
            id: user.id,
            email: user.email.clone(),
            role: user.role.clone(),
            created_at: user.created_at,
            first_name: user.first_name.clone(),
            last_name: user.last_name.clone(),
            username: user.username.clone(),
        }
    }
}

// ─── Events ───────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize, Validate)]
pub struct CreateEventRequest {
    #[validate(length(min = 1, max = 255))]
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    /// RFC3339 datetime string e.g. "2026-06-15T20:00:00Z"
    #[validate(length(min = 1))]
    pub event_date: String,
    pub price: Option<f64>,
    pub capacity: Option<i32>,
    pub cover_url: Option<String>,
    /// musique | culture | divertissement
    pub category: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateEventRequest {
    #[validate(length(min = 1, max = 255))]
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    #[validate(length(min = 1))]
    pub event_date: String,
    pub price: Option<f64>,
    pub capacity: Option<i32>,
    pub cover_url: Option<String>,
    pub category: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct EventResponse {
    pub id: Uuid,
    pub organizer_id: Uuid,
    pub title: String,
    pub description: String,
    pub location: String,
    pub event_date: DateTime<Utc>,
    pub price: f64,
    pub capacity: i32,
    pub cover_url: Option<String>,
    pub category: String,
    pub created_at: DateTime<Utc>,
}

impl From<Event> for EventResponse {
    fn from(e: Event) -> Self {
        Self {
            id: e.id,
            organizer_id: e.organizer_id,
            title: e.title,
            description: e.description,
            location: e.location,
            event_date: e.event_date,
            price: e.price,
            capacity: e.capacity,
            cover_url: e.cover_url,
            category: e.category,
            created_at: e.created_at,
        }
    }
}

