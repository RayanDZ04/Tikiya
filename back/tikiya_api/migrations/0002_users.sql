-- Users table: supports email/password and OAuth
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    role TEXT NOT NULL DEFAULT 'client',
    oauth_provider TEXT,
    oauth_subject TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT oauth_unique UNIQUE (oauth_provider, oauth_subject)
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
