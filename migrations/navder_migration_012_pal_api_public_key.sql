-- Navder Migration 012
-- Add API public key to community.pal.
--
-- The API public key is optional and, when present, must be
-- exactly 65 bytes.

BEGIN;

ALTER TABLE community.pal
    ADD COLUMN api_public_key BYTEA;

ALTER TABLE community.pal
    ADD CONSTRAINT pal_api_public_key_length_chk
    CHECK (
        api_public_key IS NULL
        OR octet_length(api_public_key) = 65
    );

COMMIT;
