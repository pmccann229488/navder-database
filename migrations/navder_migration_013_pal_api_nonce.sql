-- Navder Migration 013
-- Add API nonce replay protection storage for Pal API authentication.

BEGIN;

CREATE TABLE IF NOT EXISTS community.pal_api_nonce (
    pal_id UUID NOT NULL,
    nonce UUID NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (pal_id, nonce),

    CONSTRAINT fk_pal_api_nonce_pal
        FOREIGN KEY (pal_id)
        REFERENCES community.pal (pal_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pal_api_nonce_received_at
    ON community.pal_api_nonce (received_at);

COMMIT;
