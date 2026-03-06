-- Add email verification flag to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE;

-- Mark OAuth users as already verified (no email to verify)
UPDATE users SET email_verified = TRUE WHERE oauth_provider IS NOT NULL;

-- OTP table: one pending code per user at a time
CREATE TABLE IF NOT EXISTS email_otps (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash   TEXT NOT NULL,           -- SHA-256 hex of the 6-digit code
    expires_at  TIMESTAMPTZ NOT NULL,
    attempts    INT  NOT NULL DEFAULT 0,
    used        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only one active OTP per user at a time
CREATE UNIQUE INDEX IF NOT EXISTS email_otps_user_active
    ON email_otps (user_id)
    WHERE NOT used;
