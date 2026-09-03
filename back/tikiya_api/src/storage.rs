//! File storage abstraction: local disk in dev, S3/MinIO in production.
//!
//! Local disk stops working the moment the API runs as more than one replica
//! (each replica has its own disk), so anything horizontally scaled must use the
//! object-storage backend. The backend is chosen from config: an empty
//! `S3_BUCKET` means local disk.

use bytes::Bytes;
use object_store::{aws::AmazonS3Builder, path::Path as ObjectPath, ObjectStore};
use std::sync::Arc;
use tokio::fs;

use crate::config::AppConfig;

#[derive(Clone)]
pub enum Storage {
    Local { dir: String },
    S3 { store: Arc<dyn ObjectStore> },
}

impl Storage {
    /// Builds the storage backend from config. Falls back to local disk when
    /// `S3_BUCKET` is empty.
    pub fn from_config(cfg: &AppConfig) -> Result<Self, String> {
        if cfg.s3_bucket.is_empty() {
            return Ok(Storage::Local {
                dir: "uploads".to_string(),
            });
        }

        let mut builder = AmazonS3Builder::new()
            .with_bucket_name(&cfg.s3_bucket)
            .with_access_key_id(&cfg.s3_access_key)
            .with_secret_access_key(&cfg.s3_secret_key)
            .with_region(&cfg.s3_region)
            // MinIO uses path-style addressing, not the virtual-host style AWS defaults to.
            .with_virtual_hosted_style_request(false)
            .with_allow_http(true);

        if !cfg.s3_endpoint.is_empty() {
            builder = builder.with_endpoint(&cfg.s3_endpoint);
        }

        let store = builder
            .build()
            .map_err(|e| format!("s3 backend build failed: {e}"))?;
        Ok(Storage::S3 {
            store: Arc::new(store),
        })
    }

    /// Stores `data` under `filename`. Returns an error string on failure.
    pub async fn put(&self, filename: &str, data: Bytes) -> Result<(), String> {
        match self {
            Storage::Local { dir } => {
                fs::create_dir_all(dir).await.map_err(|e| e.to_string())?;
                fs::write(format!("{dir}/{filename}"), &data)
                    .await
                    .map_err(|e| e.to_string())
            }
            Storage::S3 { store } => {
                let path = ObjectPath::from(filename);
                store
                    .put(&path, data.into())
                    .await
                    .map(|_| ())
                    .map_err(|e| e.to_string())
            }
        }
    }

    /// Fetches the bytes stored under `filename`.
    pub async fn get(&self, filename: &str) -> Result<Bytes, String> {
        match self {
            Storage::Local { dir } => fs::read(format!("{dir}/{filename}"))
                .await
                .map(Bytes::from)
                .map_err(|e| e.to_string()),
            Storage::S3 { store } => {
                let path = ObjectPath::from(filename);
                let res = store.get(&path).await.map_err(|e| e.to_string())?;
                res.bytes().await.map_err(|e| e.to_string())
            }
        }
    }
}
