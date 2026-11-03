BEGIN;

ALTER TABLE messaging.delivery
ADD CONSTRAINT delivery_mls_recipient_excludes_generic_pal
CHECK (
    crew_pal_id IS NULL
    OR (
        crew_id IS NOT NULL
        AND pal_id IS NULL
    )
);

COMMIT;
