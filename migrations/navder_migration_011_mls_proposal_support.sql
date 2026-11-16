BEGIN;

ALTER TABLE messaging.message
    DROP CONSTRAINT IF EXISTS message_protocol_type_valid;

ALTER TABLE messaging.message
    ADD CONSTRAINT message_protocol_type_valid
    CHECK (
        protocol_type IS NULL
        OR protocol_type = ANY (
            ARRAY[
                'COMMIT'::text,
                'WELCOME'::text,
                'APPLICATION'::text,
                'PROPOSAL'::text
            ]
        )
    );

ALTER TABLE messaging.message
    DROP CONSTRAINT IF EXISTS message_mls_metadata_shape;

ALTER TABLE messaging.message
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
                protocol_type = 'APPLICATION'::text
                OR (
                    protocol_type = 'PROPOSAL'::text
                    AND expires_at IS NULL
                )
                OR (
                    protocol_type = ANY (
                        ARRAY['COMMIT'::text, 'WELCOME'::text]
                    )
                    AND group_revision >= 1
                    AND expires_at IS NULL
                )
            )
        )
    );

COMMENT ON CONSTRAINT message_protocol_type_valid
ON messaging.message IS
'Allowed MLS protocol message types: COMMIT, WELCOME, APPLICATION and PROPOSAL.';

COMMENT ON CONSTRAINT message_mls_metadata_shape
ON messaging.message IS
'Validates MLS metadata shape. PROPOSAL uses the current group_revision and must not have expires_at; COMMIT/WELCOME and APPLICATION retain their existing semantics.';

COMMIT;
