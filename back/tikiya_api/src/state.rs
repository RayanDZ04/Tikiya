use crate::config::AppConfig;
use crate::db::Db;
use crate::storage::Storage;

#[derive(Clone)]
pub struct AppState {
    pub db: Db,
    pub config: AppConfig,
    /// Shared HTTP client — reuses TCP connection pools for Chargily, Google, etc.
    pub http_client: reqwest::Client,
    /// Shared Redis connection for distributed rate limiting across API replicas.
    /// `None` when REDIS_URL is unset (single-instance dev mode).
    pub redis: Option<redis::aio::ConnectionManager>,
    /// File storage backend (local disk in dev, S3/MinIO in production).
    pub storage: Storage,
}
