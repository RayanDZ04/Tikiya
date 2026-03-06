use crate::config::AppConfig;
use crate::db::Db;

#[derive(Clone)]
pub struct AppState {
    pub db: Db,
    pub config: AppConfig,
    /// Shared HTTP client — reuses TCP connection pools for Chargily, Google, etc.
    pub http_client: reqwest::Client,
}
