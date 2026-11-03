BEGIN;

-- Persist the client-generated bootstrap operation ID so a lost HTTP response
-- can be retried without creating a second Crew.
ALTER TABLE community.crew
    ADD COLUMN bootstrap_operation_id UUID;

-- Existing Crews pre-date atomic bootstrap. Give each a non-reusable historical
-- value; only new bootstrap requests use client-generated operation IDs.
UPDATE community.crew
SET bootstrap_operation_id = gen_random_uuid()
WHERE bootstrap_operation_id IS NULL;

ALTER TABLE community.crew
    ALTER COLUMN bootstrap_operation_id SET NOT NULL;

ALTER TABLE community.crew
    ADD CONSTRAINT crew_bootstrap_operation_uq
    UNIQUE (bootstrap_operation_id);

COMMENT ON COLUMN community.crew.bootstrap_operation_id IS
'Client-generated idempotency UUID for the atomic Crew and initial MLS group bootstrap operation.';

COMMENT ON CONSTRAINT crew_bootstrap_operation_uq
ON community.crew IS
'Prevents duplicate Crew creation when an atomic bootstrap request is retried.';

COMMIT;
