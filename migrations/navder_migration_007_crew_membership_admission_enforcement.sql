-- ============================================================================
-- Navder Migration 007
-- Crew membership admission enforcement
--
-- Purpose:
--   1. Reject USER crew messages from memberships that are not ACTIVE.
--   2. Prevent PENDING membership rows from carrying a departure timestamp.
--   3. Document the existing one-open-membership-per-Pal rule.
--
-- Prerequisites:
--   - Migration 006 has been applied.
-- ============================================================================

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '0';

-- Preflight checks
DO $migration_preflight$
BEGIN
    IF to_regclass('community.crew_pal') IS NULL THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: community.crew_pal does not exist.';
    END IF;

    IF to_regprocedure('community.validate_crew_message_membership()') IS NULL THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: community.validate_crew_message_membership() does not exist.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = 'community.crew_pal'::regclass
          AND attname = 'membership_status'
          AND NOT attisdropped
    ) THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: membership_status is missing. Apply Migration 006 first.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = 'community.crew_pal'::regclass
          AND attname = 'joined_at'
          AND NOT attisdropped
          AND attnotnull = false
    ) THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: joined_at is missing or is still NOT NULL.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'community.crew_message'::regclass
          AND tgname = 'crew_message_membership_validate_trg'
          AND NOT tgisinternal
    ) THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: expected crew message membership trigger is missing.';
    END IF;

    IF to_regclass('community.crew_pal_one_active_per_pal') IS NULL THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: expected one-open-membership unique index is missing.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'community.crew_pal'::regclass
          AND conname = 'crew_pal_pending_has_no_departure'
    ) THEN
        RAISE EXCEPTION
            'Migration 007 preflight failed: constraint crew_pal_pending_has_no_departure already exists.';
    END IF;
END;
$migration_preflight$;


-- Replace the existing trigger function.
-- A sender must have completed admission before a USER message is accepted.

CREATE OR REPLACE FUNCTION community.validate_crew_message_membership()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    membership_status_value text;
    membership_joined_at timestamptz;
    membership_left_at timestamptz;
BEGIN
    IF NEW.message_type <> 'USER' THEN
        RETURN NEW;
    END IF;

    SELECT membership_status, joined_at, left_at
    INTO membership_status_value,
         membership_joined_at,
         membership_left_at
    FROM community.crew_pal
    WHERE crew_pal_id = NEW.crew_pal_id
      AND crew_id = NEW.crew_id
      AND pal_id = NEW.pal_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Crew message does not reference a valid sender membership period.';
    END IF;

    IF membership_status_value IS DISTINCT FROM 'ACTIVE' THEN
        RAISE EXCEPTION
            'Cannot insert a Crew message: sender membership admission is not ACTIVE.';
    END IF;

    IF NEW.created_at < membership_joined_at
       OR (
           membership_left_at IS NOT NULL
           AND NEW.created_at >= membership_left_at
       )
    THEN
        RAISE EXCEPTION
            'Cannot insert a message outside the sender membership period.';
    END IF;

    RETURN NEW;
END;
$function$;


-- A membership that has not completed admission cannot have departed.

ALTER TABLE community.crew_pal
    ADD CONSTRAINT crew_pal_pending_has_no_departure
    CHECK (
        membership_status IS DISTINCT FROM 'PENDING'
        OR left_at IS NULL
    );


-- Document membership lifecycle semantics.

COMMENT ON CONSTRAINT crew_pal_pending_has_no_departure
ON community.crew_pal
IS 'A PENDING Crew membership has not become effective and therefore cannot have a departure timestamp.';

COMMENT ON COLUMN community.crew_pal.membership_status
IS 'Admission lifecycle: PENDING means MLS admission has not completed; ACTIVE means admission completed successfully. ACTIVE is retained for historical admitted membership periods; left_at indicates whether the period has ended.';

COMMENT ON COLUMN community.crew_pal.left_at
IS 'NULL while the membership period remains open. Populated when an admitted membership period ends. PENDING memberships must have left_at NULL.';

COMMENT ON INDEX community.crew_pal_one_active_per_pal
IS 'Enforces one open Crew membership period per Pal. The left_at IS NULL predicate intentionally reserves the slot for both PENDING admission attempts and ACTIVE membership periods.';


COMMIT;
