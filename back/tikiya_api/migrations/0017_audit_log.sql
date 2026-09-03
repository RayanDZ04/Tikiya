-- Journal d'audit des actions sensibles (qui, quoi, quand, depuis où).
-- Sert aux enquêtes de sécurité et à la traçabilité (paiements, rôles,
-- suppressions, changements de mot de passe/email).
CREATE TABLE IF NOT EXISTS audit_log (
    id          BIGSERIAL PRIMARY KEY,
    -- Auteur de l'action (NULL si non authentifié, ex: tentative de login).
    actor_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    -- Verbe court et stable, ex: 'password.changed', 'event.deleted'.
    action      TEXT NOT NULL,
    -- Type + id de l'objet visé, ex: ('event', '<uuid>').
    target_type TEXT,
    target_id   TEXT,
    -- IP source (telle que vue par l'API), pour corréler les incidents.
    ip          TEXT,
    -- Contexte libre (JSON) : détails non sensibles utiles à l'enquête.
    metadata    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_actor    ON audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_action   ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_created  ON audit_log(created_at DESC);
