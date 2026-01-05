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
    pub google_client_id: String,
    pub google_client_secret: String,
    pub google_redirect_uri: String,
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
            .unwrap_or(1024 * 1024);

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
        // Google OAuth config is optional; only required if you use Google endpoints
        let google_client_id = env::var("GOOGLE_CLIENT_ID").unwrap_or_default();
        let google_client_secret = env::var("GOOGLE_CLIENT_SECRET").unwrap_or_default();
        let google_redirect_uri = env::var("GOOGLE_REDIRECT_URI").unwrap_or_default();

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
            google_client_id,
            google_client_secret,
            google_redirect_uri,
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
