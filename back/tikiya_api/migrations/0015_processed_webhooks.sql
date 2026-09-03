-- Anti-replay for Chargily payment webhooks.
-- A signed webhook that's captured (leaked logs, compromised intermediary)
-- could otherwise be replayed to reprocess an old status transition (e.g.
-- re-marking a refunded ticket as "paid"). Deduping on (checkout_id, status)
-- lets legitimate retries of the exact same event be safely ignored while
-- still allowing genuine new status transitions for the same checkout.
CREATE TABLE IF NOT EXISTS processed_webhooks (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checkout_id  TEXT NOT NULL,
    status       TEXT NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (checkout_id, status)
);

-- Index missing since 0008_events_category.sql — category filter does a full
-- table scan on events without it.
CREATE INDEX IF NOT EXISTS events_category_idx ON events (category);
