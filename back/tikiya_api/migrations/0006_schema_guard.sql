-- Fail-fast schema guard: ensures production schema matches what the API expects.
-- If this migration fails, stop and fix earlier migrations / DB schema.

DO $$
DECLARE
    id_type text;
BEGIN
    -- users table must exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        RAISE EXCEPTION 'schema_guard: table public.users is missing';
    END IF;

    -- users.id must be uuid
    SELECT data_type INTO id_type
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';

    IF id_type IS NULL THEN
        RAISE EXCEPTION 'schema_guard: column users.id is missing';
    END IF;

    IF id_type <> 'uuid' THEN
        RAISE EXCEPTION 'schema_guard: users.id must be uuid, got %', id_type;
    END IF;

    -- required columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='role') THEN
        RAISE EXCEPTION 'schema_guard: column users.role is missing';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='created_at') THEN
        RAISE EXCEPTION 'schema_guard: column users.created_at is missing';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='password_hash') THEN
        RAISE EXCEPTION 'schema_guard: column users.password_hash is missing';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='oauth_provider') THEN
        RAISE EXCEPTION 'schema_guard: column users.oauth_provider is missing';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='oauth_subject') THEN
        RAISE EXCEPTION 'schema_guard: column users.oauth_subject is missing';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='failed_attempts') THEN
        RAISE EXCEPTION 'schema_guard: column users.failed_attempts is missing';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='lockout_until') THEN
        RAISE EXCEPTION 'schema_guard: column users.lockout_until is missing';
    END IF;
END $$;
