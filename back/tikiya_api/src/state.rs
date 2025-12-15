use crate::config::AppConfig;
use crate::db::Db;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Instant;

#[derive(Clone)]
pub struct AppState {
    pub db: Db,
    pub config: AppConfig,
    pub failed_logins: Arc<Mutex<HashMap<String, (u32, Option<Instant>)>>>,
    pub ip_failures: Arc<Mutex<HashMap<String, (u32, Option<Instant>)>>>,
}
