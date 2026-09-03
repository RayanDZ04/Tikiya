-- Authentification à deux facteurs (TOTP) — surtout pour les comptes à
-- privilège (admins) et à l'argent (organisateurs).
-- Le secret est stocké en base32 ; il n'est actif qu'une fois `totp_enabled`.
ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_secret TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_enabled BOOLEAN NOT NULL DEFAULT FALSE;
