use axum::http::Uri;
use serde::{Deserialize, Serialize};
use std::time::Duration;

use crate::dto::{AuthResponse, UserResponse};
use crate::error::ApiError;
use crate::models::User;
use crate::services::auth::AuthService;
use crate::state::AppState;

const GOOGLE_AUTH_URL: &str = "https://accounts.google.com/o/oauth2/v2/auth";
const GOOGLE_TOKEN_URL: &str = "https://oauth2.googleapis.com/token";
const GOOGLE_USERINFO_URL: &str = "https://openidconnect.googleapis.com/v1/userinfo";

#[derive(Debug, Deserialize)]
struct GoogleTokenResponse {
    access_token: String,
    _expires_in: i64,
    _token_type: String,
    _id_token: Option<String>,
    _refresh_token: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct GoogleUserInfo {
    pub sub: String,
    pub email: String,
    pub _email_verified: bool,
    pub _given_name: Option<String>,
    pub _family_name: Option<String>,
}

pub struct OAuthService {
    state: AppState,
    client: reqwest::Client,
}

impl OAuthService {
    pub fn new(state: AppState) -> Self {
        let client = reqwest::Client::builder()
            .user_agent("tikiya-api/1.0")
            .connect_timeout(Duration::from_secs(5))
            .timeout(Duration::from_secs(10))
            .build()
            .expect("reqwest client");
        Self { state, client }
    }

    pub fn google_auth_url(&self, state_str: &str, code_challenge: Option<&str>, code_challenge_method: Option<&str>) -> Result<Uri, ApiError> {
        let mut url = format!(
            "{}?client_id={}&redirect_uri={}&response_type=code&scope=openid%20email%20profile&state={}&access_type=offline&prompt=consent",
            GOOGLE_AUTH_URL,
            urlencoding::encode(&self.state.config.google_client_id),
            urlencoding::encode(&self.state.config.google_redirect_uri),
            urlencoding::encode(state_str)
        );
        if let Some(chal) = code_challenge {
            let method = code_challenge_method.unwrap_or("S256");
            url.push_str(&format!("&code_challenge={}&code_challenge_method={}", urlencoding::encode(chal), method));
        }
        url.parse::<Uri>().map_err(|_| ApiError::Internal)
    }

    pub async fn google_callback(&self, code: &str, code_verifier: Option<&str>) -> Result<AuthResponse, ApiError> {
        let token = self.exchange_code_for_token(code, code_verifier).await?;
        let userinfo = self.fetch_google_userinfo(&token.access_token).await?;

        let user = self.upsert_oauth_user(&userinfo).await?;

        let auth = AuthService::new(self.state.clone());
        let tokens = auth.issue_tokens(&user).await?;

        Ok(AuthResponse { user: UserResponse::from(&user), tokens })
    }

    async fn exchange_code_for_token(&self, code: &str, code_verifier: Option<&str>) -> Result<GoogleTokenResponse, ApiError> {
        #[derive(Serialize)]
        struct Body<'a> {
            code: &'a str,
            client_id: &'a str,
            client_secret: &'a str,
            redirect_uri: &'a str,
            grant_type: &'a str,
            #[serde(skip_serializing_if = "Option::is_none")]
            code_verifier: Option<&'a str>,
        }
        let body = Body {
            code,
            client_id: &self.state.config.google_client_id,
            client_secret: &self.state.config.google_client_secret,
            redirect_uri: &self.state.config.google_redirect_uri,
            grant_type: "authorization_code",
            code_verifier,
        };

        let res = self
            .client
            .post(GOOGLE_TOKEN_URL)
            .form(&body)
            .send()
            .await
            .map_err(|e| {
                tracing::error!(error = ?e, "google.token.request_failed");
                ApiError::Internal
            })?;

        if !res.status().is_success() {
            let status = res.status();
            let text = res.text().await.unwrap_or_default();
            tracing::warn!(status = %status, body = %text, "google.token.exchange_failed");
            return Err(ApiError::Unauthorized);
        }

        res.json::<GoogleTokenResponse>().await.map_err(|e| {
            tracing::error!(error = ?e, "google.token.parse_failed");
            ApiError::Internal
        })
    }

    async fn fetch_google_userinfo(&self, access_token: &str) -> Result<GoogleUserInfo, ApiError> {
        let res = self
            .client
            .get(GOOGLE_USERINFO_URL)
            .bearer_auth(access_token)
            .send()
            .await
            .map_err(|e| {
                tracing::error!(error = ?e, "google.userinfo.request_failed");
                ApiError::Internal
            })?;

        if !res.status().is_success() {
            let status = res.status();
            let text = res.text().await.unwrap_or_default();
            tracing::warn!(status = %status, body = %text, "google.userinfo_failed");
            return Err(ApiError::Unauthorized);
        }

        res.json::<GoogleUserInfo>().await.map_err(|e| {
            tracing::error!(error = ?e, "google.userinfo.parse_failed");
            ApiError::Internal
        })
    }

    pub async fn upsert_oauth_user(&self, info: &GoogleUserInfo) -> Result<User, ApiError> {
        // Try existing by provider+subject
        if let Some(existing) = sqlx::query_as::<_, User>(
            "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at FROM users WHERE oauth_provider = 'google' AND oauth_subject = $1"
        )
        .bind(&info.sub)
        .fetch_optional(&self.state.db.pool)
        .await? {
            return Ok(existing);
        }

        if let Some(existing_by_email) = sqlx::query_as::<_, User>(
            "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at FROM users WHERE email = $1"
        )
        .bind(&info.email)
        .fetch_optional(&self.state.db.pool)
        .await? {
            let updated = sqlx::query_as::<_, User>(
                "UPDATE users SET oauth_provider = 'google', oauth_subject = $1 WHERE id = $2 RETURNING id, email, password_hash, role, oauth_provider, oauth_subject, created_at"
            )
            .bind(&info.sub)
            .bind(existing_by_email.id)
            .fetch_one(&self.state.db.pool)
            .await?;
            return Ok(updated);
        }

        let created = sqlx::query_as::<_, User>(
            "INSERT INTO users (email, oauth_provider, oauth_subject, role) VALUES ($1, 'google', $2, 'client') RETURNING id, email, password_hash, role, oauth_provider, oauth_subject, created_at"
        )
        .bind(&info.email)
        .bind(&info.sub)
        .fetch_one(&self.state.db.pool)
        .await?;

        Ok(created)
    }
}
