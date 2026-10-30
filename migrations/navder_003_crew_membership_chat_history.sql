
-- navder_003_crew_membership_chat_history.sql
--
-- Purpose:
-- Associate each USER message with the sender's specific Crew membership
-- period. Preserve historical membership periods so returning members can
-- retrieve messages sent during periods when they were members.
--
-- Run after navder_002_crew_social_features_v4_7.sql.
-- Back up the database before applying.

BEGIN;

-- 1. Provide a composite key so a message's Crew, Pal and membership
--    period must all refer to the same crew_pal record.

ALTER TABLE community.crew_pal
    ADD CONSTRAINT crew_pal_period_identity_uq
    UNIQUE (crew_pal_id, crew_id, pal_id);


-- 2. Add the sender membership-period reference to chat messages.

ALTER TABLE community.crew_message
    ADD COLUMN crew_pal_id bigint;


-- 3. Check that every existing USER message belongs to exactly one
--    membership period, based on the message timestamp.

DO $$
DECLARE
    unmatched_count bigint;
BEGIN
    SELECT count(*)
    INTO unmatched_count
    FROM community.crew_message cm
    WHERE cm.message_type = 'USER'
      AND (
          SELECT count(*)
          FROM community.crew_pal cp
          WHERE cp.crew_id = cm.crew_id
            AND cp.pal_id = cm.pal_id
            AND cm.created_at >= cp.joined_at
            AND (
                cp.left_at IS NULL
                OR cm.created_at < cp.left_at
            )
      ) <> 1;

    IF unmatched_count > 0 THEN
        RAISE EXCEPTION
            'Cannot migrate: % USER messages do not match exactly one Crew membership period.',
            unmatched_count;
    END IF;
END
$$;


-- 4. Backfill the sender's membership period.

UPDATE community.crew_message cm
SET crew_pal_id = (
    SELECT cp.crew_pal_id
    FROM community.crew_pal cp
    WHERE cp.crew_id = cm.crew_id
      AND cp.pal_id = cm.pal_id
      AND cm.created_at >= cp.joined_at
      AND (
          cp.left_at IS NULL
          OR cm.created_at < cp.left_at
      )
)
WHERE cm.message_type = 'USER';


-- 5. Enforce the correct payload shape:
--    USER messages must reference a membership period.
--    Membership-event records must not reference one.

ALTER TABLE community.crew_message
    DROP CONSTRAINT crew_message_payload_shape;

ALTER TABLE community.crew_message
    ADD CONSTRAINT crew_message_payload_shape CHECK (
        (
            message_type = 'USER'
            AND pal_id IS NOT NULL
            AND crew_pal_id IS NOT NULL
            AND ciphertext IS NOT NULL
            AND message IS NULL
            AND actor_kind IS NULL
            AND actor_pal_id IS NULL
            AND affected_pal_id IS NULL
        )
        OR
        (
            message_type IN (
                'MEMBER_JOINED',
                'MEMBER_LEFT',
                'MEMBER_REMOVED'
            )
            AND pal_id IS NULL
            AND crew_pal_id IS NULL
            AND message IS NULL
            AND ciphertext IS NULL
            AND affected_pal_id IS NOT NULL
            AND (
                (actor_kind = 'PAL' AND actor_pal_id IS NOT NULL)
                OR
                (actor_kind = 'SERVICE' AND actor_pal_id IS NULL)
            )
            AND (
                (
                    message_type IN ('MEMBER_JOINED', 'MEMBER_LEFT')
                    AND actor_kind = 'PAL'
                    AND actor_pal_id = affected_pal_id
                )
                OR
                (
                    message_type = 'MEMBER_REMOVED'
                    AND (
                        (
                            actor_kind = 'PAL'
                            AND actor_pal_id IS DISTINCT FROM affected_pal_id
                        )
                        OR actor_kind = 'SERVICE'
                    )
                )
            )
        )
    );


-- 6. Ensure the message's Crew, Pal and membership period agree.

ALTER TABLE community.crew_message
    ADD CONSTRAINT crew_message_membership_period_fk
    FOREIGN KEY (crew_pal_id, crew_id, pal_id)
    REFERENCES community.crew_pal
        (crew_pal_id, crew_id, pal_id)
    ON DELETE RESTRICT;


-- 7. Index membership-period history lookups.

CREATE INDEX crew_message_crew_membership_idx
    ON community.crew_message
        (crew_id, crew_pal_id, crew_message_id)
    WHERE message_type = 'USER';

CREATE INDEX crew_pal_history_lookup_idx
    ON community.crew_pal
        (crew_id, pal_id, joined_at, left_at);


-- 8. Prevent a message being inserted against an expired
--    membership period.

CREATE OR REPLACE FUNCTION community.validate_crew_message_membership()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    membership_joined_at timestamptz;
    membership_left_at timestamptz;
BEGIN
    IF NEW.message_type <> 'USER' THEN
        RETURN NEW;
    END IF;

    SELECT joined_at, left_at
    INTO membership_joined_at, membership_left_at
    FROM community.crew_pal
    WHERE crew_pal_id = NEW.crew_pal_id
      AND crew_id = NEW.crew_id
      AND pal_id = NEW.pal_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Crew message does not reference a valid sender membership period.';
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
$$;

CREATE TRIGGER crew_message_membership_validate_trg
    BEFORE INSERT ON community.crew_message
    FOR EACH ROW
    EXECUTE FUNCTION community.validate_crew_message_membership();


COMMENT ON COLUMN community.crew_message.crew_pal_id IS
    'Sender membership-period ID. Identifies which Crew membership period was active when the message was sent.';

COMMIT;


-- Verification queries (run separately).

-- Check messages and their sender membership periods.
SELECT
    cm.crew_message_id,
    cm.crew_id,
    cm.pal_id,
    cm.crew_pal_id,
    cm.created_at,
    cp.joined_at,
    cp.left_at
FROM community.crew_message cm
LEFT JOIN community.crew_pal cp
    ON cp.crew_pal_id = cm.crew_pal_id
WHERE cm.message_type = 'USER'
ORDER BY cm.crew_message_id DESC
LIMIT 20;

-- Check that every USER message has a membership-period reference.
SELECT count(*) AS invalid_messages
FROM community.crew_message
WHERE message_type = 'USER'
  AND crew_pal_id IS NULL;
