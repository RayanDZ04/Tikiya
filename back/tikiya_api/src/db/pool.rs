use sqlx::{postgres::PgPoolOptions, PgPool};
use std::time::Duration;

#[derive(Clone)]
pub struct Db {
    pub pool: PgPool,
}

impl Db {
    pub async fn connect_with_max(database_url: &str, max: u32) -> anyhow::Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(max)
            .acquire_timeout(Duration::from_secs(5))
            .idle_timeout(Duration::from_secs(60))
            .max_lifetime(Duration::from_secs(30 * 60))
            .connect(database_url)
            .await?;
        Ok(Self { pool })
    }

    pub async fn ping(&self) -> anyhow::Result<()> {
        sqlx::query_scalar::<_, i32>("SELECT 1")
            .fetch_one(&self.pool)
            .await?;
        Ok(())
    }
}
