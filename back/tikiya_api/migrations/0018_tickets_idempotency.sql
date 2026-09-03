-- Idempotence de la création de paiement : un double-clic (ou un retry réseau)
-- avec la même clé ne doit pas créer deux billets. Le client envoie un en-tête
-- Idempotency-Key ; on stocke aussi l'URL de checkout pour pouvoir la rejouer.
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS checkout_url TEXT;

-- Une clé est unique par utilisateur (NULL autorisé et non contraint).
CREATE UNIQUE INDEX IF NOT EXISTS uq_tickets_user_idempotency
    ON tickets (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;
