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
mod routes;
mod services;
mod state;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_tracing();

    let cfg = config::AppConfig::from_env();
    let _config_in_use = (&cfg.database_url, &cfg.jwt_secret);

    // Connect DB
    let db = db::Db::connect(&cfg.database_url).await?;
    tracing::info!("db.connected");

    tracing::info!(port = %cfg.port, origins = ?cfg.allowed_origins, "config.loaded");

    let state = state::AppState {
        db,
        config: cfg.clone(),
    };

    let app = http::build_router(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], cfg.port));
    tracing::info!(%addr, "server.start");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app)
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
