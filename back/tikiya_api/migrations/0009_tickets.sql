-- Tickets: one row per purchased ticket
CREATE TABLE IF NOT EXISTS tickets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id    UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Chargily checkout reference
    checkout_id TEXT NOT NULL UNIQUE,
    -- Status mirroring Chargily: pending | paid | failed | canceled
    status      TEXT NOT NULL DEFAULT 'pending',
    amount      INTEGER NOT NULL,          -- in DZD (whole number)
    currency    TEXT NOT NULL DEFAULT 'dzd',
    payment_method TEXT,                   -- edahabia | cib | null (pending)
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tickets_event_id ON tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user_id  ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status   ON tickets(status);
