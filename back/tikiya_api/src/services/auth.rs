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
        let (secret, secret_hash, refresh_exp) = self.generate_refresh_secret()?;
        let session_id = self.persist_session(user, &secret_hash, refresh_exp).await?;
        let refresh_token = format!("{}.{}", session_id, secret);

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

    fn generate_refresh_secret(&self) -> Result<(String, String, chrono::DateTime<Utc>), ApiError> {
        let expires_at = Utc::now() + Duration::days(REFRESH_TOKEN_TTL_DAYS);
        let mut rng = OsRng;
        let mut bytes = [0u8; 64];
        rng.fill_bytes(&mut bytes);
        let secret = URL_SAFE_NO_PAD.encode(bytes);

        let salt = SaltString::generate(&mut rng);
        let hash = self
            .argon2
            .hash_password(secret.as_bytes(), &salt)
            .map_err(|err| {
                tracing::error!(?err, "auth.refresh.hash_failed");
                ApiError::Internal
            })?
            .to_string();

        Ok((secret, hash, expires_at))
    }

    async fn persist_session(
        &self,
        user: &User,
        refresh_hash: &str,
        expires_at: chrono::DateTime<Utc>,
    ) -> Result<Uuid, ApiError> {
        let id = sqlx::query_scalar::<_, Uuid>(
            "INSERT INTO sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3) RETURNING id",
        )
            .bind(user.id)
            .bind(refresh_hash)
            .bind(expires_at)
            .fetch_one(&self.state.db.pool)
            .await?;

        Ok(id)
    }

    pub async fn refresh(&self, payload: RefreshRequest) -> Result<AuthTokens, ApiError> {
        let (session_id, secret) = parse_refresh_token(&payload.refresh_token)?;

        #[derive(sqlx::FromRow)]
        struct SessionRow {
            id: Uuid,
            user_id: Uuid,
            token_hash: String,
            expires_at: chrono::DateTime<Utc>,
            revoked_at: Option<chrono::DateTime<Utc>>,
        }

        let session = sqlx::query_as::<_, SessionRow>(
            "SELECT id, user_id, token_hash, expires_at, revoked_at FROM sessions WHERE id = $1",
        )
        .bind(session_id)
        .fetch_optional(&self.state.db.pool)
        .await?
        .ok_or(ApiError::Unauthorized)?;

        if session.revoked_at.is_some() || session.expires_at <= Utc::now() {
            return Err(ApiError::Unauthorized);
        }

        let parsed = PasswordHash::new(&session.token_hash).map_err(|err| {
            tracing::error!(?err, "auth.refresh.hash_parse_failed");
            ApiError::Internal
        })?;

        self.argon2
            .verify_password(secret.as_bytes(), &parsed)
            .map_err(|_| ApiError::Unauthorized)?;

        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at, failed_attempts, lockout_until FROM users WHERE id = $1",
        )
        .bind(session.user_id)
        .fetch_one(&self.state.db.pool)
        .await?;

        // Issue new tokens and rotate session hash
        let access_token = self.generate_access_token(&user)?;
        let (new_secret, new_hash, new_exp) = self.generate_refresh_secret()?;
        let refresh_token = format!("{}.{}", session.id, new_secret);

        sqlx::query("UPDATE sessions SET token_hash = $1, expires_at = $2 WHERE id = $3")
            .bind(new_hash)
            .bind(new_exp)
            .bind(session.id)
            .execute(&self.state.db.pool)
            .await?;

        Ok(AuthTokens {
            access_token,
            refresh_token,
        })
    }

    pub async fn logout(&self, payload: LogoutRequest) -> Result<(), ApiError> {
        let (session_id, secret) = parse_refresh_token(&payload.refresh_token)?;

        let row = sqlx::query_as::<_, (String, chrono::DateTime<Utc>, Option<chrono::DateTime<Utc>>)>(
            "SELECT token_hash, expires_at, revoked_at FROM sessions WHERE id = $1",
        )
        .bind(session_id)
        .fetch_optional(&self.state.db.pool)
        .await?
        .ok_or(ApiError::Unauthorized)?;

        let (token_hash, expires_at, revoked_at) = row;
        if revoked_at.is_some() || expires_at <= Utc::now() {
            return Err(ApiError::Unauthorized);
        }

        let parsed = PasswordHash::new(&token_hash).map_err(|err| {
            tracing::error!(?err, "auth.logout.hash_parse_failed");
            ApiError::Internal
        })?;

        self.argon2
            .verify_password(secret.as_bytes(), &parsed)
            .map_err(|_| ApiError::Unauthorized)?;

        sqlx::query("UPDATE sessions SET revoked_at = NOW() WHERE id = $1")
            .bind(session_id)
            .execute(&self.state.db.pool)
            .await?;

        Ok(())
    }
}

fn parse_refresh_token(token: &str) -> Result<(Uuid, &str), ApiError> {
    let (sid, secret) = token.split_once('.').ok_or(ApiError::Unauthorized)?;
    let session_id = Uuid::parse_str(sid).map_err(|_| ApiError::Unauthorized)?;
    if secret.is_empty() {
        return Err(ApiError::Unauthorized);
    }
    Ok((session_id, secret))
}
