-- ============================================================================
-- Navder Migration 007
-- Post-migration verification
--
-- Run after Migration 007 has committed.
-- ============================================================================


-- 1. Confirm the trigger function explicitly checks membership_status.

SELECT pg_get_functiondef(
    'community.validate_crew_message_membership()'::regprocedure
);


-- 2. Confirm the new CHECK constraint is present and validated.

SELECT
    conname,
    convalidated,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'community.crew_pal'::regclass
  AND conname = 'crew_pal_pending_has_no_departure';


-- 3. Confirm the unique index still reserves one open membership period.

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'community'
  AND tablename = 'crew_pal'
  AND indexname = 'crew_pal_one_active_per_pal';


-- 4. Confirm there are no invalid PENDING rows.

SELECT COUNT(*) AS invalid_pending_departures
FROM community.crew_pal
WHERE membership_status = 'PENDING'
  AND left_at IS NOT NULL;
