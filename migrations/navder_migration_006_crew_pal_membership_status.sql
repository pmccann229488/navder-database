-- ============================================================
-- Navder Migration 006
-- Explicit MLS Crew Membership Lifecycle State
--
-- Adds:
--   1. membership_status: PENDING / ACTIVE
--   2. joined_at nullable, with no automatic default
--   3. CHECK constraint enforcing status/timestamp consistency
--
-- Existing membership records:
--   - Become ACTIVE
--   - Retain their existing joined_at values
--
-- IMPORTANT:
-- Apply to navder_migration_test first.
-- Do not apply to navder until testing is complete.
-- ============================================================

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '0';

-- ------------------------------------------------------------
-- 1. Pre-migration checks
-- ------------------------------------------------------------

DO $migration$
BEGIN
    IF to_regclass('community.crew_pal') IS NULL THEN
        RAISE EXCEPTION
            'Migration 006 aborted: community.crew_pal does not exist.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'community'
          AND table_name = 'crew_pal'
          AND column_name = 'membership_status'
    ) THEN
        RAISE EXCEPTION
            'Migration 006 aborted: membership_status already exists.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'community.crew_pal'::regclass
          AND conname IN (
              'crew_pal_membership_status_valid',
              'crew_pal_membership_joined_at_consistent'
          )
    ) THEN
        RAISE EXCEPTION
            'Migration 006 aborted: one or more Migration 006 constraints already exist.';
    END IF;
END
$migration$;

-- ------------------------------------------------------------
-- 2. Add membership_status
--
-- Existing rows receive ACTIVE through the default.
-- Existing joined_at values are not changed.
-- ------------------------------------------------------------

ALTER TABLE community.crew_pal
    ADD COLUMN membership_status TEXT NOT NULL DEFAULT 'ACTIVE';

-- ------------------------------------------------------------
-- 3. Make joined_at nullable and remove automatic timestamp
--
-- Pending memberships must not receive an effective
-- admission timestamp before MLS admission completes.
-- ------------------------------------------------------------

ALTER TABLE community.crew_pal
    ALTER COLUMN joined_at DROP DEFAULT,
    ALTER COLUMN joined_at DROP NOT NULL;

-- ------------------------------------------------------------
-- 4. Restrict membership_status values
-- ------------------------------------------------------------

ALTER TABLE community.crew_pal
    ADD CONSTRAINT crew_pal_membership_status_valid
    CHECK (
        membership_status IN ('PENDING', 'ACTIVE')
    );

-- ------------------------------------------------------------
-- 5. Enforce membership status / joined_at consistency
-- ------------------------------------------------------------

ALTER TABLE community.crew_pal
    ADD CONSTRAINT crew_pal_membership_joined_at_consistent
    CHECK (
        (membership_status = 'PENDING' AND joined_at IS NULL)
        OR
        (membership_status = 'ACTIVE' AND joined_at IS NOT NULL)
    );

-- ------------------------------------------------------------
-- 6. Column documentation
-- ------------------------------------------------------------

COMMENT ON COLUMN community.crew_pal.membership_status IS
    'Crew membership lifecycle state. PENDING confers no normal Crew access; ACTIVE denotes an admitted membership period.';

COMMENT ON COLUMN community.crew_pal.joined_at IS
    'Effective membership admission timestamp. NULL while PENDING; explicitly set on transition to ACTIVE. Existing values are preserved.';

COMMIT;

-- ============================================================
-- END MIGRATION 006
-- ============================================================
