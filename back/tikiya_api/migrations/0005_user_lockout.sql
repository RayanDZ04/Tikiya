-- Add lockout tracking to users
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS failed_attempts INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lockout_until TIMESTAMPTZ NULL;
