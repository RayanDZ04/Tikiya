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

use crate::dto::{AuthResponse, AuthTokens, LoginRequest, RegisterRequest, UserResponse};
use crate::error::ApiError;
use crate::models::User;
use crate::state::AppState;

const ACCESS_TOKEN_TTL_MINUTES: i64 = 15;
const REFRESH_TOKEN_TTL_DAYS: i64 = 30;

pub struct AuthService {
    state: AppState,
    argon2: Argon2<'static>,
}

#[derive(Debug, Serialize)]
struct Claims {
    sub: Uuid,
    email: String,
    exp: usize,
    iat: usize,
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
            "INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email, password_hash, role, oauth_provider, oauth_subject, created_at"
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
            return Err(ApiError::Unauthorized);
        }

        let tokens = self.issue_tokens(&user).await?;

        tracing::info!(user_id = %user.id, email = %user.email, "auth.login.success");

        Ok(AuthResponse {
            user: UserResponse::from(&user),
            tokens,
        })
    }

    async fn find_user_by_email(&self, email: &str) -> Result<Option<User>, ApiError> {
        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, password_hash, role, oauth_provider, oauth_subject, created_at FROM users WHERE email = $1"
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

    async fn issue_tokens(&self, user: &User) -> Result<AuthTokens, ApiError> {
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
}
