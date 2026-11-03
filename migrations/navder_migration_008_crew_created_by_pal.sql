BEGIN;

-- 1. Add the creator column as nullable initially.
ALTER TABLE community.crew
ADD COLUMN created_by_pal_id UUID;

-- 2. Backfill existing Crews.
-- Prefer the earliest current active membership.
-- If no current active membership exists, use the earliest
-- historical membership.

WITH chosen_creator AS (
    SELECT DISTINCT ON (cp.crew_id)
        cp.crew_id,
        cp.pal_id
    FROM community.crew_pal cp
    ORDER BY
        cp.crew_id,
        CASE
            WHEN cp.membership_status = 'ACTIVE'
             AND cp.left_at IS NULL
            THEN 0
            ELSE 1
        END,
        cp.joined_at ASC NULLS LAST,
        cp.created_at ASC,
        cp.crew_pal_id ASC
)
UPDATE community.crew c
SET created_by_pal_id = cc.pal_id
FROM chosen_creator cc
WHERE cc.crew_id = c.crew_id;

-- 3. Refuse to proceed if any Crew has no valid creator.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM community.crew
        WHERE created_by_pal_id IS NULL
    ) THEN
        RAISE EXCEPTION
            'Migration 008 aborted: one or more Crews have no membership from which to assign a creator';
    END IF;
END;
$$;

-- 4. Require a creator for every Crew.
ALTER TABLE community.crew
ALTER COLUMN created_by_pal_id SET NOT NULL;

-- 5. Enforce Pal referential integrity.
ALTER TABLE community.crew
ADD CONSTRAINT crew_created_by_pal_fk
FOREIGN KEY (created_by_pal_id)
REFERENCES community.pal (pal_id)
ON DELETE RESTRICT;

-- 6. Prevent creator identity from being changed.
CREATE OR REPLACE FUNCTION community.prevent_crew_creator_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.created_by_pal_id IS DISTINCT FROM OLD.created_by_pal_id THEN
        RAISE EXCEPTION
            'Crew creator identity cannot be changed';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER crew_creator_immutable
BEFORE UPDATE OF created_by_pal_id
ON community.crew
FOR EACH ROW
EXECUTE FUNCTION community.prevent_crew_creator_change();

-- 7. Document the column.
COMMENT ON COLUMN community.crew.created_by_pal_id IS
'Permanent Pal identity of the Crew creator. Set from authenticated Pal identity on creation and immutable thereafter.';

COMMENT ON CONSTRAINT crew_created_by_pal_fk
ON community.crew IS
'Ensures the permanent Crew creator references an existing Pal.';

COMMIT;
