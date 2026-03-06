-- Add username column to users table
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS username VARCHAR(50);
