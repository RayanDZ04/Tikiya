use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ApiError {
    #[error("invalid data: {0}")]
    Validation(String),
    #[error("identifiants invalides")]
    Unauthorized,
    #[error("resource not found")]
    NotFound,
    #[error("conflict: {0}")]
    Conflict(String),
    #[error("service unavailable")]
    ServiceUnavailable,
    #[error("internal error")]
    Internal,
}

#[derive(Serialize)]
struct ErrorBody {
    code: u16,
    message: &'static str,
    detail: Option<String>,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message, detail) = match &self {
            ApiError::Validation(msg) => (
                StatusCode::BAD_REQUEST,
                "Validation Failed",
                Some(msg.clone()),
            ),
            ApiError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized", None),
            ApiError::NotFound => (StatusCode::NOT_FOUND, "Not Found", None),
            ApiError::Conflict(msg) => (StatusCode::CONFLICT, "Conflict", Some(msg.clone())),
            ApiError::ServiceUnavailable => (
                StatusCode::SERVICE_UNAVAILABLE,
                "Service Unavailable",
                None,
            ),
            ApiError::Internal => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Internal Server Error",
                None,
            ),
        };

        let body = Json(ErrorBody {
            code: status.as_u16(),
            message,
            detail,
        });
        (status, body).into_response()
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(e: sqlx::Error) -> Self {
        match e {
            sqlx::Error::PoolTimedOut | sqlx::Error::PoolClosed => ApiError::ServiceUnavailable,
            sqlx::Error::RowNotFound => ApiError::NotFound,
            sqlx::Error::Database(db_err) => {
                if db_err.code().map(|c| c == "23505").unwrap_or(false) {
                    ApiError::Conflict("duplicate entry".into())
                } else {
                    tracing::error!(error = %db_err, "sqlx database error");
                    ApiError::Internal
                }
            }
            other => {
                tracing::error!(error = ?other, "sqlx error");
                ApiError::Internal
            }
        }
    }
}

impl From<argon2::password_hash::Error> for ApiError {
    fn from(error: argon2::password_hash::Error) -> Self {
        tracing::error!(?error, "argon2 error");
        ApiError::Internal
    }
}
