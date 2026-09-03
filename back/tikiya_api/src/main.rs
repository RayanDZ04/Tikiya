use std::net::SocketAddr;
use tracing_subscriber::prelude::*;
use tracing_subscriber::{fmt, EnvFilter};

mod config;
mod db;
mod dto;
mod error;
mod handlers;
mod http;
mod models;
mod ratelimit;
mod routes;
mod services;
mod state;
mod storage;
mod security;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_tracing();

    let cfg = config::AppConfig::from_env();
    let _config_in_use = (&cfg.database_url, &cfg.jwt_secret);

    // Connect DB
    let db = db::Db::connect_with_max(&cfg.database_url, cfg.database_pool_max).await?;
    tracing::info!("db.connected");

    // Run migrations automatically
    sqlx::migrate!("./migrations")
        .run(&db.pool)
        .await
        .map_err(|e| { tracing::error!(error = ?e, "migrations.failed"); e })?;
    tracing::info!("migrations.applied");

    tracing::info!(port = %cfg.port, origins = ?cfg.allowed_origins, "config.loaded");

    let http_client = reqwest::Client::builder()
        .user_agent("tikiya-api/1.0")
        .connect_timeout(std::time::Duration::from_secs(5))
        .timeout(std::time::Duration::from_secs(15))
        .build()
        .map_err(|e| { tracing::error!(error = ?e, "http_client.build_failed"); e })?;

    // Optional Redis connection for distributed rate limiting. A failure here is
    // non-fatal: the API still runs with only the in-memory governor.
    let redis = if cfg.redis_url.is_empty() {
        tracing::info!("redis.disabled — distributed rate limiting off (REDIS_URL unset)");
        None
    } else {
        match redis::Client::open(cfg.redis_url.clone()) {
            Ok(client) => match redis::aio::ConnectionManager::new(client).await {
                Ok(cm) => {
                    tracing::info!("redis.connected");
                    Some(cm)
                }
                Err(e) => {
                    tracing::error!(error = %e, "redis.connect_failed — continuing without distributed rate limiting");
                    None
                }
            },
            Err(e) => {
                tracing::error!(error = %e, "redis.client_failed — continuing without distributed rate limiting");
                None
            }
        }
    };

    let storage = storage::Storage::from_config(&cfg)
        .map_err(|e| { tracing::error!(error = %e, "storage.init_failed"); e })?;
    match &storage {
        storage::Storage::Local { .. } => tracing::info!("storage.local (uploads/)"),
        storage::Storage::S3 { .. } => tracing::info!(bucket = %cfg.s3_bucket, "storage.s3"),
    }

    let state = state::AppState {
        db,
        config: cfg.clone(),
        http_client,
        redis,
        storage,
    };

    let app = http::build_router(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], cfg.port));
    tracing::info!(%addr, "server.start");
    println!("Server listening on http://localhost:{}", cfg.port);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    Ok(())
}

fn init_tracing() {
    tracing_subscriber::registry()
        .with(EnvFilter::from_default_env())
        .with(fmt::layer().json().flatten_event(true))
        .init();
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };
    #[cfg(unix)]
    let terminate = async {
        use tokio::signal::unix::{signal, SignalKind};
        let mut sigterm =
            signal(SignalKind::terminate()).expect("failed to install SIGTERM handler");
        sigterm.recv().await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("server.shutdown");
}
