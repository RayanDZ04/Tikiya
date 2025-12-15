use argon2::password_hash::{
    rand_core::{OsRng, RngCore},
    PasswordHash, PasswordHasher, PasswordVerifier, SaltString,
};
use argon2::Argon2;
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};
use chrono::{Duration, Utc};
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::Serialize;
use uuid::Uuid;
use futures_util::StreamExt;

use crate::dto::{AuthResponse, AuthTokens, LoginRequest, LogoutRequest, RefreshRequest, RegisterRequest, UserResponse};
use crate::error::ApiError;
use crate::models::User;
use crate::state::AppState;

const ACCESS_TOKEN_TTL_MINUTES: i64 = 15;
const REFRESH_TOKEN_TTL_DAYS: i64 = 30;

pub struct AuthService {
    pub(crate) state: AppState,
    argon2: Argon2<'static>,
}

#[derive(Debug, Serialize)]
struct Claims {
    sub: Uuid,
    email: String,
    exp: usize,
    iat: usize,
    aud: String,
    iss: String,
}

impl AuthService {
    pub fn new(state: AppState) -> Self {
        Self {
            state,
            argon2: Argon2::default(),
        }
    }

    pub async fn register(&self, payload: RegisterRequest) -> Result<AuthResponse, ApiError> {
        let password_hash = self.hash_password(&payload.password)?;

        let user = sqlx::query_as::<_, User>(
            "INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email, password_hash, role, oauth_provider, oauth_subject, created_at, failed_attempts, lockout_until"
        )
        .bind(&payload.email)
        .bind(password_hash)
        .fetch_one(&self.state.db.pool)
        .await?;

        let tokens = self.issue_tokens(&user).await?;

        tracing::info!(user_id = %user.id, email = %user.email, "auth.register.success");

        Ok(AuthResponse {
            user: UserResponse::from(&user),
            tokens,
        })
    }

    pub async fn login(&self, payload: LoginRequest) -> Result<AuthResponse, ApiError> {
        let user = self
            .find_user_by_email(&payload.email)
            .await?
            .ok_or(ApiError::Unauthorized)?;

        // DB-backed lockout check
        if let Some(until) = user.lockout_until {
            if until > Utc::now() {
                tracing::warn!(email = %payload.email, "auth.login.locked_out_db");
                return Err(ApiError::Unauthorized);
            }
        }

        let hash = user
            .password_hash
            .as_deref()
            .ok_or(ApiError::Unauthorized)?;

        let parsed = PasswordHash::new(hash).map_err(|err| {
            tracing::error!(?err, "auth.login.hash_parse_failed");
            ApiError::Internal
        })?;

        if self
            .argon2
            .verify_password(payload.password.as_bytes(), &parsed)
            .is_err()
        {
            tracing::warn!(email = %payload.email, "auth.login.invalid_password");
            // Increment failed attempts and set lockout if threshold reached
            let attempts = user.failed_attempts + 1;
            let mut lockout_until: Option<chrono::DateTime<Utc>> = None;
            if attempts >= 5 {
                lockout_until = Some(Utc::now() + Duration::minutes(15));
            }
            sqlx::query("UPDATE users SET failed_attempts = $1, lockout_until = $2 WHERE id = $3")
                .bind(attempts)
                .bind(lockout_until)
                .bind(user.id)
                .execute(&self.state.db.pool)
                .await?;
            return Err(ApiError::Unauthorized);
        }

        // Reset failed attempts on success
        sqlx::query("UPDATE users SET failed_attempts = 0, lockout_until = NULL WHERE id = $1")
            .bind(user.id)
            .execute(&self.state.db.pool)
            .await?;

        let tokens = self.issue_tokens(&user).await?;

        tracing::info!(user_id = %user.id, email = %user.email, "auth.login.success");

        Ok(AuthResponse {
            user: UserResponse::from(&user),
            tokens,
        })
    }

    async fn find_user_by_email(&self, email: &str) -> Result<Option<User>, ApiError> {
        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at, failed_attempts, lockout_until FROM users WHERE email = $1"
        )
        .bind(email)
        .fetch_optional(&self.state.db.pool)
        .await?;

        Ok(user)
    }

    fn hash_password(&self, password: &str) -> Result<String, ApiError> {
        let salt = SaltString::generate(&mut OsRng);
        Ok(self
            .argon2
            .hash_password(password.as_bytes(), &salt)?
            .to_string())
    }

    pub async fn issue_tokens(&self, user: &User) -> Result<AuthTokens, ApiError> {
        let access_token = self.generate_access_token(user)?;
        let (refresh_token, refresh_hash, refresh_exp) = self.generate_refresh_token()?;

        self.persist_session(user, &refresh_hash, refresh_exp)
            .await?;

        Ok(AuthTokens {
            access_token,
            refresh_token,
        })
    }

    fn generate_access_token(&self, user: &User) -> Result<String, ApiError> {
        let now = Utc::now();
        let exp = now + Duration::minutes(ACCESS_TOKEN_TTL_MINUTES);
        let claims = Claims {
            sub: user.id,
            email: user.email.clone(),
            iat: now.timestamp() as usize,
            exp: exp.timestamp() as usize,
            aud: self.state.config.jwt_audience.clone(),
            iss: self.state.config.jwt_issuer.clone(),
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.state.config.jwt_secret.as_bytes()),
        )
        .map_err(|err| {
            tracing::error!(?err, "auth.token.encode_failed");
            ApiError::Internal
        })
    }

    fn generate_refresh_token(&self) -> Result<(String, String, chrono::DateTime<Utc>), ApiError> {
        let expires_at = Utc::now() + Duration::days(REFRESH_TOKEN_TTL_DAYS);
        let mut rng = OsRng;
        let mut bytes = [0u8; 64];
        rng.fill_bytes(&mut bytes);
        let token = URL_SAFE_NO_PAD.encode(bytes);

        let salt = SaltString::generate(&mut rng);
        let hash = self
            .argon2
            .hash_password(token.as_bytes(), &salt)
            .map_err(|err| {
                tracing::error!(?err, "auth.refresh.hash_failed");
                ApiError::Internal
            })?
            .to_string();

        Ok((token, hash, expires_at))
    }

    async fn persist_session(
        &self,
        user: &User,
        refresh_hash: &str,
        expires_at: chrono::DateTime<Utc>,
    ) -> Result<(), ApiError> {
        sqlx::query("INSERT INTO sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3)")
            .bind(user.id)
            .bind(refresh_hash)
            .bind(expires_at)
            .execute(&self.state.db.pool)
            .await?;

        Ok(())
    }

    pub async fn refresh(&self, payload: RefreshRequest) -> Result<AuthTokens, ApiError> {
        // Load candidate sessions and verify against provided refresh token
        #[derive(sqlx::FromRow)]
        struct SessionRow {
            id: i64,
            user_id: Uuid,
            token_hash: String,
            _expires_at: chrono::DateTime<Utc>,
        }

        let mut matched: Option<SessionRow> = None;
        let mut rows = sqlx::query_as::<_, SessionRow>(
            "SELECT id, user_id, token_hash, expires_at FROM sessions WHERE expires_at > NOW()",
        )
        .fetch(&self.state.db.pool);

        while let Some(res) = rows.next().await {
            let row = res.map_err(|e| {
                tracing::error!(?e, "auth.refresh.query_failed");
                ApiError::Internal
            })?;
            if let Ok(parsed) = PasswordHash::new(&row.token_hash) {
                if self
                    .argon2
                    .verify_password(payload.refresh_token.as_bytes(), &parsed)
                    .is_ok()
                {
                    matched = Some(row);
                    break;
                }
            }
        }

        let session = matched.ok_or(ApiError::Unauthorized)?;

        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at, failed_attempts, lockout_until FROM users WHERE id = $1",
        )
        .bind(session.user_id)
        .fetch_one(&self.state.db.pool)
        .await?;

        // Issue new tokens and rotate session hash
        let access_token = self.generate_access_token(&user)?;
        let (new_refresh, new_hash, new_exp) = self.generate_refresh_token()?;

        sqlx::query("UPDATE sessions SET token_hash = $1, expires_at = $2 WHERE id = $3")
            .bind(new_hash)
            .bind(new_exp)
            .bind(session.id)
            .execute(&self.state.db.pool)
            .await?;

        Ok(AuthTokens {
            access_token,
            refresh_token: new_refresh,
        })
    }

    pub async fn logout(&self, payload: LogoutRequest) -> Result<(), ApiError> {
        // Find session by verifying hash, then delete it
        #[derive(sqlx::FromRow)]
        struct SessionRow {
            id: i64,
            token_hash: String,
        }

        let mut target_id: Option<i64> = None;
        let mut rows = sqlx::query_as::<_, SessionRow>(
            "SELECT id, token_hash FROM sessions WHERE expires_at > NOW()",
        )
        .fetch(&self.state.db.pool);

        while let Some(res) = rows.next().await {
            let row = res.map_err(|e| {
                tracing::error!(?e, "auth.logout.query_failed");
                ApiError::Internal
            })?;
            if let Ok(parsed) = PasswordHash::new(&row.token_hash) {
                if self
                    .argon2
                    .verify_password(payload.refresh_token.as_bytes(), &parsed)
                    .is_ok()
                {
                    target_id = Some(row.id);
                    break;
                }
            }
        }

        let id = target_id.ok_or(ApiError::Unauthorized)?;

        sqlx::query("DELETE FROM sessions WHERE id = $1")
            .bind(id)
            .execute(&self.state.db.pool)
            .await?;

        Ok(())
    }
}
