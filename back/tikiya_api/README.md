# Tikiya API

Backend REST API for the ticketing application built with Axum, Tokio and SQLx. It exposes authentication endpoints (register/login) and service health probes that the upcoming web, Android and iOS clients will consume.

## Stack
- Rust 1.75+ with Tokio runtime
- Axum 0.7 (HTTP server and routing)
- SQLx 0.7 with PostgreSQL
- Argon2 for password hashing
- JSON Web Tokens (jsonwebtoken) for access tokens
- Validator for payload validation and tracing for structured logs

## Project Structure
- `src/main.rs` bootstraps configuration, database pool and HTTP router
- `src/config.rs` reads environment variables (with `.env` fallback)
- `src/state.rs` centralises shared state passed to Axum (DB + config)
- `src/routes/` declares route trees (currently `/register` and `/login`)
- `src/handlers/` marshals requests/responses and delegates to services
- `src/services/auth.rs` implements register/login, token issuance and session persistence
- `src/dto/` defines request/response DTOs and validation rules
- `migrations/` contains SQL migrations for users and sessions tables (PostgreSQL)

## Prerequisites
- Rust toolchain (`rustup` recommended)
- PostgreSQL instance
- `sqlx-cli` if you plan to run migrations via CLI (`cargo install sqlx-cli --no-default-features --features postgres`)

## Configuration
Create a `.env` file (or export variables) with:
```
DATABASE_URL=postgres://user:pass@localhost:5432/ticketing
JWT_SECRET=change_me
PORT=8080
ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```
Notes:
- `PORT` defaults to 8080 if omitted
- `ORIGINS` is a comma separated list consumed by the CORS layer
- `JWT_SECRET` must be a strong random string; rotate it carefully because existing refresh tokens will become invalid

## Database Setup
1. Create the database and role (example):
```
psql -d template1 -c "CREATE ROLE \"user\" WITH LOGIN PASSWORD 'pass';"
psql -d template1 -c "ALTER ROLE \"user\" CREATEDB;"
createdb -O "user" ticketing
```
2. Run migrations:
```
cd back/tikiya_api
sqlx migrate run
```
Migrations will create the `extensions`, `users`, and `sessions` tables with UUID primary keys.

## Running the API
```
cargo run
```
Useful probes:
- `GET /health` returns `OK`
- `GET /ready` checks the database connection and returns `READY` or `UNAVAILABLE`

Structured logs are emitted in JSON (compatible with log collectors).

## Authentication Flow
- **Register**: `POST /register` with JSON body `{ "email": "user@example.com", "password": "strong_pass" }`
  - Validates payload (email format, password length 8-128)
  - Hashes the password with Argon2
  - Persists the user and returns `{ user, tokens }`
- **Login**: `POST /login` with same payload structure
  - Verifies credentials
  - Issues an access token (JWT, 15 minutes) and a refresh token (random, stored hashed in `sessions` table`

JWT claims include `sub` (user UUID), `email`, `iat`, and `exp`. Refresh tokens are one-way hashed before storage.

Example request:
```
curl -X POST http://localhost:8080/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"S3cretPass"}'
```
Example response:
```
{
  "user": {
    "id": "...",
    "email": "alice@example.com",
    "role": "client",
    "created_at": "2025-12-14T12:34:56.123456Z"
  },
  "tokens": {
    "access_token": "<jwt>",
    "refresh_token": "<opaque-token>"
  }
}
```

## Error Handling
Errors are normalised via `ApiError` and returned as JSON:
```
{
  "code": 400,
  "message": "Validation Failed",
  "detail": "password: length must be between 8 and 128"
}
```

## Known Next Steps
- Enforce HTTPS (reverse proxy or native TLS) and store secrets outside the repo
- Add rate limiting / account lockout to mitigate brute-force attempts
- Provide refresh-token rotation and logout endpoints
- Add integration tests for register/login flows
- Align migrations (legacy tables from earlier experiments can be removed once confirmed unused)

## Frontend / Client Development
The API is ready to power web, Android and iOS clients. Implementations only need standard HTTPS requests and token storage:
- Use the `/register` and `/login` endpoints to obtain tokens
- Attach the JWT in the `Authorization: Bearer <token>` header for future protected routes (coming soon)
- Persist refresh tokens securely on each platform (EncryptedSharedPreferences on Android, Keychain on iOS, HTTP-only cookies or secure storage on web)

## Development Tips
- Run `cargo fmt` before committing
- `cargo check` validates compilation without producing binaries
- Use `RUST_LOG=debug` for more verbose tracing when debugging

The backend is stable enough to start building the UI layers. Upcoming iterations will focus on additional security hardening and feature endpoints.
