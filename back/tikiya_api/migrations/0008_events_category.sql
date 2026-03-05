-- Ajouter la colonne catégorie aux événements
ALTER TABLE events
    ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'musique';

-- Mettre tous les événements existants en "musique"
UPDATE events SET category = 'musique';
