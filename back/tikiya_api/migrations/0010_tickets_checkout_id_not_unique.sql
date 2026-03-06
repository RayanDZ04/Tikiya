-- Plusieurs billets peuvent partager le même checkout_id (achat en lot)
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS tickets_checkout_id_key;
