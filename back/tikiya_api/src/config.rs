use std::env;

#[derive(Clone, Debug)]
pub struct AppConfig {
    pub port: u16,
    pub allowed_origins: Vec<String>,
    pub database_url: String,
    pub database_pool_max: u32,
    pub http_request_timeout_secs: u64,
    pub http_concurrency_limit: usize,
    pub http_max_body_bytes: usize,
    pub rate_limit_per_second: u32,
    pub rate_limit_burst: u32,
    pub trust_proxy_headers: bool,
    pub http_hsts_enabled: bool,
    pub jwt_secret: String,
    pub jwt_issuer: String,
    pub jwt_audience: String,
    pub payment_url_hmac_secret: String,
    pub google_client_id: String,
    pub google_client_secret: String,
    pub google_redirect_uri: String,
    pub smtp_host: String,
    pub smtp_port: u16,
    pub smtp_username: String,
    pub smtp_password: String,
    pub smtp_from: String,
    pub organizer_needs_to_email: String,
    pub public_base_url: String,
    pub chargily_api_key: String,
    pub chargily_base_url: String,
    pub access_token_ttl_minutes: i64,
    pub resend_api_key: String,
    pub resend_from: String,
    pub otp_ttl_minutes: i64,
    pub otp_max_attempts: i32,
    pub upload_max_file_bytes: usize,
    pub upload_quota_bytes_per_user: i64,
    pub redis_url: String,
    pub pwned_check_enabled: bool,
    pub captcha_secret: String,
    pub s3_endpoint: String,
    pub s3_bucket: String,
    pub s3_access_key: String,
    pub s3_secret_key: String,
    pub s3_region: String,
}

impl AppConfig {
    pub fn from_env() -> Self {
        load_dotenv_if_exists();

        let port = env::var("PORT")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(8080);

        let allowed_origins = env::var("ORIGINS")
            .map(|v| {
                v.split(',')
                    .map(|s| s.trim().to_string())
                    .filter(|s| !s.is_empty())
                    .collect()
            })
            .unwrap_or_else(|_| {
                vec![
                    "http://localhost:3000".to_string(),
                    "http://127.0.0.1:3000".to_string(),
                ]
            });

        let database_url = must_env("DATABASE_URL");
        let database_pool_max = env::var("DATABASE_POOL_MAX")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(20);

        let http_request_timeout_secs = env::var("HTTP_REQUEST_TIMEOUT_SECS")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(15);

        let http_concurrency_limit = env::var("HTTP_CONCURRENCY_LIMIT")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or_else(|| (database_pool_max as usize).saturating_mul(4).max(8));

        let http_max_body_bytes = env::var("HTTP_MAX_BODY_BYTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(10 * 1024 * 1024); // 10 MB default (for image uploads)

        let rate_limit_per_second = env::var("RATE_LIMIT_PER_SECOND")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(20);

        let rate_limit_burst = env::var("RATE_LIMIT_BURST")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(40);

        let trust_proxy_headers = env::var("TRUST_PROXY_HEADERS")
            .ok()
            .map(|v| {
                let v = v.to_lowercase();
                v == "1" || v == "true" || v == "yes"
            })
            .unwrap_or(false);

        let http_hsts_enabled = env::var("HTTP_HSTS")
            .ok()
            .map(|v| {
                let v = v.to_lowercase();
                v == "1" || v == "true" || v == "yes"
            })
            .unwrap_or(false);

        let jwt_secret = must_env("JWT_SECRET");
        // Basic guardrails against weak defaults.
        let secret_trim = jwt_secret.trim();
        if secret_trim.len() < 32 || secret_trim.to_lowercase().contains("change-me") {
            panic!(
                "JWT_SECRET trop faible (min 32 chars et ne doit pas contenir 'change-me')"
            );
        }
        let jwt_issuer = env::var("JWT_ISSUER").unwrap_or_else(|_| "tikiya-api".to_string());
        let jwt_audience = env::var("JWT_AUDIENCE").unwrap_or_else(|_| "tikiya-clients".to_string());

        // Separate key from JWT_SECRET so a leak of one doesn't compromise the other.
        // Falls back to JWT_SECRET if unset, to avoid a hard break on existing deployments —
        // but a dedicated value should be set before going to production.
        let payment_url_hmac_secret = env::var("PAYMENT_URL_HMAC_SECRET")
            .unwrap_or_else(|_| jwt_secret.clone());
        if payment_url_hmac_secret == jwt_secret {
            tracing::warn!(
                "PAYMENT_URL_HMAC_SECRET non défini — réutilisation de JWT_SECRET (à corriger avant la prod)"
            );
        } else {
            let secret_trim = payment_url_hmac_secret.trim();
            if secret_trim.len() < 32 || secret_trim.to_lowercase().contains("change-me") {
                panic!(
                    "PAYMENT_URL_HMAC_SECRET trop faible (min 32 chars et ne doit pas contenir 'change-me')"
                );
            }
        }
        // Google OAuth config is optional; only required if you use Google endpoints
        let google_client_id = env::var("GOOGLE_CLIENT_ID").unwrap_or_default();
        let google_client_secret = env::var("GOOGLE_CLIENT_SECRET").unwrap_or_default();
        let google_redirect_uri = env::var("GOOGLE_REDIRECT_URI").unwrap_or_default();
        let smtp_host = env::var("SMTP_HOST").unwrap_or_default();
        let smtp_port = env::var("SMTP_PORT")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(587);
        let smtp_username = env::var("SMTP_USERNAME").unwrap_or_default();
        let smtp_password = env::var("SMTP_PASSWORD").unwrap_or_default();
        let smtp_from = env::var("SMTP_FROM").unwrap_or_else(|_| "noreply@tikiya.dz".to_string());
        let organizer_needs_to_email = env::var("ORGANIZER_NEEDS_TO_EMAIL")
            .unwrap_or_else(|_| "rayanbenhabiles9@gmail.com".to_string());
        let public_base_url = env::var("PUBLIC_BASE_URL")
            .unwrap_or_else(|_| format!("http://localhost:{}", port));
        let chargily_api_key = env::var("CHARGILY_API_KEY")
            .unwrap_or_else(|_| String::new());

        // CHARGILY_BASE_URL overrides everything; otherwise CHARGILY_ENV=prod uses live URL.
        let chargily_base_url = env::var("CHARGILY_BASE_URL").unwrap_or_else(|_| {
            match env::var("CHARGILY_ENV").as_deref() {
                Ok("prod") => "https://pay.chargily.net/api/v2".to_string(),
                _ => "https://pay.chargily.net/test/api/v2".to_string(),
            }
        });

        let access_token_ttl_minutes = env::var("ACCESS_TOKEN_TTL_MINUTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(60); // 60 min par défaut

        let resend_api_key = env::var("RESEND_API_KEY").unwrap_or_default();
        let resend_from = env::var("RESEND_FROM")
            .unwrap_or_else(|_| "Tikiya <noreply@tikiya.dz>".to_string());
        let otp_ttl_minutes = env::var("OTP_TTL_MINUTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(10);
        let otp_max_attempts = env::var("OTP_MAX_ATTEMPTS")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(5);

        let upload_max_file_bytes = env::var("UPLOAD_MAX_FILE_BYTES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(5 * 1024 * 1024); // 5 MB per file default

        let upload_quota_bytes_per_user = env::var("UPLOAD_QUOTA_BYTES_PER_USER")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(50 * 1024 * 1024); // 50 MB per user default

        // Empty = distributed rate limiting disabled (single-instance dev mode);
        // tower_governor's in-memory limiter still applies.
        let redis_url = env::var("REDIS_URL").unwrap_or_default();

        // Breached-password check (HaveIBeenPwned). Off by default so dev/tests
        // make no external calls; enable in production.
        let pwned_check_enabled = env::var("PWNED_CHECK_ENABLED")
            .map(|v| v == "true" || v == "1")
            .unwrap_or(false);

        // Cloudflare Turnstile secret. Empty = CAPTCHA disabled (dev/test);
        // when set, registration requires and verifies a captcha token.
        let captcha_secret = env::var("CAPTCHA_SECRET").unwrap_or_default();

        // Empty S3_BUCKET = local-disk storage (dev). Set all four for MinIO/S3.
        let s3_endpoint = env::var("S3_ENDPOINT").unwrap_or_default();
        let s3_bucket = env::var("S3_BUCKET").unwrap_or_default();
        let s3_access_key = env::var("S3_ACCESS_KEY").unwrap_or_default();
        let s3_secret_key = env::var("S3_SECRET_KEY").unwrap_or_default();
        let s3_region = env::var("S3_REGION").unwrap_or_else(|_| "us-east-1".to_string());

        Self {
            port,
            allowed_origins,
            database_url,
            database_pool_max,
            http_request_timeout_secs,
            http_concurrency_limit,
            http_max_body_bytes,
            rate_limit_per_second,
            rate_limit_burst,
            trust_proxy_headers,
            http_hsts_enabled,
            jwt_secret,
            jwt_issuer,
            jwt_audience,
            payment_url_hmac_secret,
            google_client_id,
            google_client_secret,
            google_redirect_uri,
            smtp_host,
            smtp_port,
            smtp_username,
            smtp_password,
            smtp_from,
            organizer_needs_to_email,
            public_base_url,
            chargily_api_key,
            chargily_base_url,
            access_token_ttl_minutes,
            resend_api_key,
            resend_from,
            otp_ttl_minutes,
            otp_max_attempts,
            upload_max_file_bytes,
            upload_quota_bytes_per_user,
            redis_url,
            pwned_check_enabled,
            captcha_secret,
            s3_endpoint,
            s3_bucket,
            s3_access_key,
            s3_secret_key,
            s3_region,
        }
    }
}

fn must_env(key: &str) -> String {
    match env::var(key) {
        Ok(v) if !v.trim().is_empty() => v,
        _ => panic!("Configuration manquante: {} (définir via env ou .env)", key),
    }
}

fn load_dotenv_if_exists() {
    use std::fs;
    if let Ok(content) = fs::read_to_string(".env") {
        for line in content.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            if let Some((k, v)) = line.split_once('=') {
                let key = k.trim();
                let val = v.trim().trim_matches('"');
                if std::env::var(key).is_err() {
                    std::env::set_var(key, val);
                }
            }
        }
    }
}
