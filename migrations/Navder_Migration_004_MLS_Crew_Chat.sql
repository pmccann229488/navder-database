-- ============================================================================
-- Navder Migration 004 — MLS Crew Chat Transport
-- Version: 1.0
-- Target baseline: PostgreSQL 18.6 / PostGIS 3.6, post-Migration-003 schema
-- Approval: Navder Migration 004 specification v1.4 signed off
--
-- IMPORTANT
--   * Run against navder_migration_test first, never directly against production.
--   * Take and verify a database backup before applying.
--   * This script is transactional. Any failed statement rolls back the migration.
--   * This DDL establishes the persistence and integrity model. It does not
--     implement API transaction logic, MLS cryptography, lease renewal, fencing,
--     message retrieval, or client-side atomic checkpointing.
--   * The application must use database transactions and row locks exactly as
--     defined in the approved v1.4 specification.
--
-- Baseline inspection:
--   community.crew already has UNIQUE (event_id, crew_id).
--   community.crew_pal currently has UNIQUE (crew_pal_id, crew_id, pal_id);
--   this migration adds UNIQUE (crew_pal_id, crew_id) for the approved FKs.
--   messaging.message.message_type remains SMALLINT and is not modified.
--   Legacy messaging rows are retained; new MLS columns are nullable for them.
-- ============================================================================

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '0';

-- ---------------------------------------------------------------------------
-- 0. Baseline guards. Fail closed if this is not the expected post-003 schema.
-- ---------------------------------------------------------------------------
DO $migration_guard$
BEGIN
    IF to_regclass('community.crew') IS NULL
       OR to_regclass('community.crew_pal') IS NULL
       OR to_regclass('messaging.message') IS NULL
       OR to_regclass('messaging.delivery') IS NULL
       OR to_regclass('messaging.acknowledgement') IS NULL THEN
        RAISE EXCEPTION
            'Migration 004 aborted: required post-Migration-003 tables are missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'community.crew'::regclass
          AND conname = 'crew_event_crew_uq'
          AND contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'Migration 004 aborted: expected UNIQUE (event_id, crew_id) on community.crew is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'community.crew_pal'::regclass
          AND conname = 'crew_pal_period_identity_uq'
          AND contype = 'u'
    ) THEN
        RAISE EXCEPTION
            'Migration 004 aborted: expected post-Migration-003 crew_pal identity key is missing';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'messaging'
          AND table_name = 'message'
          AND column_name IN (
              'crew_id', 'sender_crew_pal_id', 'crew_sequence',
              'protocol_type', 'operation_id', 'payload_digest',
              'group_revision'
          )
    ) THEN
        RAISE EXCEPTION
            'Migration 004 aborted: one or more MLS message columns already exist; inspect database state before proceeding';
    END IF;

    IF to_regclass('messaging.crew_mls_group') IS NOT NULL
       OR to_regclass('messaging.crew_mls_key_package') IS NOT NULL THEN
        RAISE EXCEPTION
            'Migration 004 aborted: an MLS table already exists; inspect database state before proceeding';
    END IF;
END
$migration_guard$;

-- ---------------------------------------------------------------------------
-- 1. Composite candidate keys required by database-enforced Crew integrity.
-- ---------------------------------------------------------------------------
ALTER TABLE community.crew_pal
    ADD CONSTRAINT crew_pal_id_crew_uq
    UNIQUE (crew_pal_id, crew_id);

-- ---------------------------------------------------------------------------
-- 2. MLS group control row.
--
-- One row per Crew. next_sequence is the next available Crew transport
-- sequence. group_revision is the application concurrency revision, not the
-- MLS epoch. Fencing token is monotonic and is never reset on release/expiry.
-- ---------------------------------------------------------------------------
CREATE TABLE messaging.crew_mls_group (
    crew_id BIGINT PRIMARY KEY,
    group_id BYTEA NOT NULL,
    next_sequence BIGINT NOT NULL DEFAULT 1,
    reservation_id UUID,
    reservation_request_id UUID,
    reservation_owner_crew_pal_id BIGINT,
    reservation_fencing_token BIGINT NOT NULL DEFAULT 0,
    reservation_expires_at TIMESTAMPTZ,
    group_revision BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT crew_mls_group_crew_fk
        FOREIGN KEY (crew_id)
        REFERENCES community.crew (crew_id)
        ON DELETE RESTRICT,

    CONSTRAINT crew_mls_group_reservation_owner_fk
        FOREIGN KEY (reservation_owner_crew_pal_id, crew_id)
        REFERENCES community.crew_pal (crew_pal_id, crew_id)
        ON DELETE RESTRICT,

    CONSTRAINT crew_mls_group_next_sequence_positive
        CHECK (next_sequence >= 1),

    CONSTRAINT crew_mls_group_fencing_nonnegative
        CHECK (reservation_fencing_token >= 0),

    CONSTRAINT crew_mls_group_revision_nonnegative
        CHECK (group_revision >= 0),

    CONSTRAINT crew_mls_group_group_id_nonempty
        CHECK (octet_length(group_id) > 0),

    CONSTRAINT crew_mls_group_reservation_complete
        CHECK (
            (
                reservation_id IS NULL
                AND reservation_request_id IS NULL
                AND reservation_owner_crew_pal_id IS NULL
                AND reservation_expires_at IS NULL
            )
            OR
            (
                reservation_id IS NOT NULL
                AND reservation_request_id IS NOT NULL
                AND reservation_owner_crew_pal_id IS NOT NULL
                AND reservation_expires_at IS NOT NULL
            )
        )
);

CREATE UNIQUE INDEX crew_mls_group_group_id_uq
    ON messaging.crew_mls_group (group_id);

CREATE UNIQUE INDEX crew_mls_group_reservation_id_uq
    ON messaging.crew_mls_group (reservation_id)
    WHERE reservation_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Extend the existing durable messaging.message transport.
--
-- Generic messages retain NULL MLS columns and existing message_type values.
-- MLS protocol_type is independent of message_type and supports COMMIT, WELCOME and APPLICATION. Values are COMMIT, WELCOME and APPLICATION.
-- ---------------------------------------------------------------------------
ALTER TABLE messaging.message
    ADD COLUMN crew_id BIGINT,
    ADD COLUMN sender_crew_pal_id BIGINT,
    ADD COLUMN crew_sequence BIGINT,
    ADD COLUMN protocol_type TEXT,
    ADD COLUMN operation_id UUID,
    ADD COLUMN payload_digest BYTEA,
    ADD COLUMN group_revision BIGINT;

ALTER TABLE messaging.message
    ADD CONSTRAINT message_crew_event_fk
        FOREIGN KEY (event_id, crew_id)
        REFERENCES community.crew (event_id, crew_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT message_sender_crew_pal_fk
        FOREIGN KEY (sender_crew_pal_id, crew_id)
        REFERENCES community.crew_pal (crew_pal_id, crew_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT message_protocol_type_valid
        CHECK (
            protocol_type IS NULL
            OR protocol_type IN ('COMMIT', 'WELCOME', 'APPLICATION')
        ),
    ADD CONSTRAINT message_mls_metadata_shape
        CHECK (
            (
                protocol_type IS NULL
                AND crew_id IS NULL
                AND sender_crew_pal_id IS NULL
                AND crew_sequence IS NULL
                AND operation_id IS NULL
                AND payload_digest IS NULL
                AND group_revision IS NULL
            )
            OR
            (
                protocol_type IS NOT NULL
                AND crew_id IS NOT NULL
                AND sender_crew_pal_id IS NOT NULL
                AND crew_sequence IS NOT NULL
                AND operation_id IS NOT NULL
                AND payload_digest IS NOT NULL
                AND octet_length(payload_digest) = 32
                AND group_revision IS NOT NULL
                AND group_revision >= 0
                AND (
                    protocol_type = 'APPLICATION'
                    OR (
                        protocol_type IN ('COMMIT', 'WELCOME')
                        AND group_revision >= 1
                        AND expires_at IS NULL
                    )
                )
            )
        ),
    ADD CONSTRAINT message_crew_sequence_positive
        CHECK (crew_sequence IS NULL OR crew_sequence >= 1),
    ADD CONSTRAINT message_group_revision_nonnegative
        CHECK (group_revision IS NULL OR group_revision >= 0);

-- Candidate key supports delivery's composite message/Crew FK.
ALTER TABLE messaging.message
    ADD CONSTRAINT message_id_crew_uq
    UNIQUE (message_id, crew_id);

-- One sequence position per Crew; ordinary messages have NULL crew_id/sequence.
CREATE UNIQUE INDEX message_crew_sequence_uq
    ON messaging.message (crew_id, crew_sequence)
    WHERE crew_id IS NOT NULL AND crew_sequence IS NOT NULL;

-- One record of each protocol type per accepted operation per Crew.
-- A single operation may therefore create one COMMIT and one WELCOME record.
CREATE UNIQUE INDEX message_crew_operation_protocol_uq
    ON messaging.message (crew_id, operation_id, protocol_type)
    WHERE protocol_type IS NOT NULL;

CREATE INDEX message_crew_protocol_pending_idx
    ON messaging.message (crew_id, crew_sequence)
    WHERE protocol_type IS NOT NULL AND cancelled_at IS NULL;

-- ---------------------------------------------------------------------------
-- 4. Extend delivery with the Crew and membership-period recipient identity.
--
-- Legacy/generic deliveries retain NULL crew_id and crew_pal_id. For MLS
-- deliveries both values are mandatory and must identify the same Crew as the
-- referenced message.
-- ---------------------------------------------------------------------------
ALTER TABLE messaging.delivery
    ADD COLUMN crew_id BIGINT,
    ADD COLUMN crew_pal_id BIGINT;

ALTER TABLE messaging.delivery
    ADD CONSTRAINT delivery_crew_recipient_pair
        CHECK (
            (crew_id IS NULL AND crew_pal_id IS NULL)
            OR
            (crew_id IS NOT NULL AND crew_pal_id IS NOT NULL)
        ),
    ADD CONSTRAINT delivery_crew_membership_fk
        FOREIGN KEY (crew_pal_id, crew_id)
        REFERENCES community.crew_pal (crew_pal_id, crew_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT delivery_message_crew_fk
        FOREIGN KEY (message_id, crew_id)
        REFERENCES messaging.message (message_id, crew_id)
        ON DELETE RESTRICT;

-- A message can be delivered at most once to a given membership period.
CREATE UNIQUE INDEX delivery_message_crew_pal_uq
    ON messaging.delivery (message_id, crew_pal_id)
    WHERE crew_pal_id IS NOT NULL;

CREATE INDEX delivery_crew_pal_status_idx
    ON messaging.delivery (crew_id, crew_pal_id, status, queued_at)
    WHERE crew_pal_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. MLS KeyPackage inventory.
--
-- Payload is opaque MLS KeyPackage data. Consumed records are retained; the
-- API must consume a package atomically with Commit acceptance.
-- ---------------------------------------------------------------------------
CREATE TABLE messaging.crew_mls_key_package (
    key_package_id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    crew_id BIGINT NOT NULL,
    crew_pal_id BIGINT NOT NULL,
    payload BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    consumed_by_operation_id UUID,

    CONSTRAINT crew_mls_key_package_membership_fk
        FOREIGN KEY (crew_pal_id, crew_id)
        REFERENCES community.crew_pal (crew_pal_id, crew_id)
        ON DELETE RESTRICT,

    CONSTRAINT crew_mls_key_package_payload_nonempty
        CHECK (octet_length(payload) > 0),

    CONSTRAINT crew_mls_key_package_expiry_valid
        CHECK (expires_at > created_at),

    CONSTRAINT crew_mls_key_package_consumption_pair
        CHECK (
            (consumed_at IS NULL AND consumed_by_operation_id IS NULL)
            OR
            (consumed_at IS NOT NULL AND consumed_by_operation_id IS NOT NULL)
        )
);

CREATE INDEX crew_mls_key_package_available_idx
    ON messaging.crew_mls_key_package (crew_id, crew_pal_id, expires_at)
    WHERE consumed_at IS NULL;

CREATE UNIQUE INDEX crew_mls_key_package_consumed_operation_uq
    ON messaging.crew_mls_key_package (crew_id, consumed_by_operation_id)
    WHERE consumed_by_operation_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. Documentation comments.
-- ---------------------------------------------------------------------------
COMMENT ON TABLE messaging.crew_mls_group IS
    'One per-Crew MLS group coordination row. group_revision is an application concurrency revision, not an MLS epoch.';

COMMENT ON COLUMN messaging.crew_mls_group.next_sequence IS
    'Next Crew transport sequence to allocate; independent of MLS epoch and group_revision.';

COMMENT ON COLUMN messaging.crew_mls_group.reservation_fencing_token IS
    'Monotonically increasing fencing token. Never decremented or reused, including after release or expiry.';

COMMENT ON COLUMN messaging.crew_mls_group.group_revision IS
    'Server-side concurrency revision. Starts at 0 for initial creator bootstrap and increments once per accepted state-advancing Commit.';

COMMENT ON COLUMN messaging.message.group_revision IS
    'For COMMIT: resulting group revision. For WELCOME: revision of the group state into which the joining member is introduced; both records from one operation carry the same revision. For APPLICATION: current group revision at message creation; it does not advance the revision.';

COMMENT ON COLUMN messaging.message.payload_digest IS
    'SHA-256 digest of the exact protocol payload bytes; 32 bytes. Used with operation_id for retry integrity.';

COMMENT ON COLUMN messaging.delivery.crew_pal_id IS
    'MLS recipient membership-period identity. NULL for legacy/generic deliveries.';

COMMENT ON TABLE messaging.crew_mls_key_package IS
    'Opaque MLS KeyPackage inventory. Consumption is one-time and atomic with accepted Commit submission; consumed rows are retained.';

COMMIT;

-- ============================================================================
-- POST-MIGRATION VALIDATION (run separately after successful COMMIT)
-- ============================================================================
-- 1. Confirm new tables:
--    SELECT to_regclass('messaging.crew_mls_group'),
--           to_regclass('messaging.crew_mls_key_package');
--
-- 2. Confirm added message columns:
--    SELECT column_name, data_type, is_nullable
--    FROM information_schema.columns
--    WHERE table_schema='messaging' AND table_name='message'
--      AND column_name IN ('crew_id','sender_crew_pal_id','crew_sequence',
--                          'protocol_type','operation_id','payload_digest',
--                          'group_revision')
--    ORDER BY ordinal_position;
--
-- 3. Confirm added delivery columns:
--    SELECT column_name, data_type, is_nullable
--    FROM information_schema.columns
--    WHERE table_schema='messaging' AND table_name='delivery'
--      AND column_name IN ('crew_id','crew_pal_id')
--    ORDER BY ordinal_position;
--
-- 4. Confirm legacy message and delivery counts are unchanged:
--    SELECT count(*) FROM messaging.message;
--    SELECT count(*) FROM messaging.delivery;
--
-- 5. Confirm no legacy records were assigned MLS metadata:
--    SELECT count(*) FROM messaging.message WHERE protocol_type IS NOT NULL;
--    SELECT count(*) FROM messaging.delivery WHERE crew_pal_id IS NOT NULL;
--
-- APPLICATION IMPLEMENTATION REQUIREMENTS NOT ENFORCEABLE BY THIS DDL:
--   * Every state-advancing Commit must acquire/renew a reservation.\n--   * Ordinary APPLICATION messages use the same Crew transport sequence and\n--     idempotency model but do not acquire a reservation or advance group_revision.
--   * Acquire compares client_group_revision with group_revision while holding
--     the crew_mls_group row FOR UPDATE.
--   * Every new lease increments reservation_fencing_token.
--   * Lease expiry is evaluated using database time; initial default duration
--     is 60 seconds and is server-configurable.
--   * A lost/expired lease invalidates the generated Commit; client discards it.
--   * Commit acceptance, sequence allocation, message/delivery inserts,
--     KeyPackage consumption, group_revision increment and reservation clearing
--     must be one transaction.
--   * Check operation idempotency before reservation validation on retry.
--   * Existing members receive COMMIT; joining membership period receives
--     WELCOME. Recipient membership periods are derived server-side.
--   * Acknowledgement is recorded only after the recipient has durably
--     persisted MLS state, transport cursor and group_revision.
--   * Initial registration creates the group row at revision 0, with the
--     creator as the sole initial member. Additional members join by Commit
--     and Welcome. The creator's initial MLS state/cursor/revision 0 must be
--     durably persisted before registration is considered complete.
-- ============================================================================
