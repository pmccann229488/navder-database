BEGIN;

ALTER TABLE messaging.message
    ADD COLUMN IF NOT EXISTS sender_created_at TIMESTAMPTZ NULL;

COMMENT ON COLUMN messaging.message.sender_created_at IS
'Original message composition timestamp supplied by the sender device for MLS application messages. NULL for historical messages and messages for which no sender timestamp is available. Distinct from created_at, which records server-side message record creation time.';

COMMIT;
