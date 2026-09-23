CREATE SCHEMA messaging;

CREATE SCHEMA communications;

ALTER TABLE design.event
    ADD COLUMN remote_support_enabled BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE design.poi_item (
    poi_item_id BIGSERIAL PRIMARY KEY,
    poi_id BIGINT NOT NULL REFERENCES design.poi(poi_id),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE design.event_day (
    event_day_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES design.event(event_id),
    day_number INTEGER NOT NULL,
    name TEXT,
    date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT event_day_number_positive CHECK (day_number > 0),
    CONSTRAINT event_day_event_number_unique UNIQUE (event_id, day_number),
    CONSTRAINT event_day_event_date_unique UNIQUE (event_id, date)
);

CREATE TABLE design.item_sequence (
    item_sequence_id BIGSERIAL PRIMARY KEY,
    event_day_id BIGINT NOT NULL REFERENCES design.event_day(event_day_id),
    poi_id BIGINT NOT NULL REFERENCES design.poi(poi_id),
    poi_item_id BIGINT NOT NULL REFERENCES design.poi_item(poi_item_id),
    sequence_no INTEGER NOT NULL,
    scheduled_start_time TIME,
    duration_minutes INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT item_sequence_number_positive CHECK (sequence_no > 0),
    CONSTRAINT item_sequence_event_day_poi_sequence_unique UNIQUE (event_day_id, poi_id, sequence_no),
    CONSTRAINT item_sequence_event_day_poi_item_unique UNIQUE (event_day_id, poi_id, poi_item_id),
    CONSTRAINT item_sequence_duration_positive CHECK (duration_minutes IS NULL OR duration_minutes > 0),
    CONSTRAINT item_sequence_schedule_complete CHECK (
        (scheduled_start_time IS NULL AND duration_minutes IS NULL)
        OR
        (scheduled_start_time IS NOT NULL AND duration_minutes IS NOT NULL)
    )
);

CREATE TABLE messaging.message (
    message_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES design.event(event_id),
    message_type SMALLINT NOT NULL,
    payload BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    CONSTRAINT message_expiry_after_creation CHECK (expires_at IS NULL OR expires_at > created_at),
    CONSTRAINT message_cancelled_after_creation CHECK (cancelled_at IS NULL OR cancelled_at >= created_at)
);

CREATE TABLE messaging.delivery (
    delivery_id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL REFERENCES messaging.message(message_id),
    pal_id BIGINT REFERENCES community.pal(pal_id),
    status TEXT NOT NULL DEFAULT 'QUEUED',
    queued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivered_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    last_attempt_at TIMESTAMPTZ,
    CONSTRAINT delivery_status_valid CHECK (status IN ('QUEUED', 'DELIVERING', 'DELIVERED', 'EXPIRED', 'CANCELLED')),
    CONSTRAINT delivery_attempt_count_nonnegative CHECK (attempt_count >= 0),
    CONSTRAINT delivery_expiry_after_queue CHECK (expires_at IS NULL OR expires_at >= queued_at),
    CONSTRAINT delivery_delivered_after_queue CHECK (delivered_at IS NULL OR delivered_at >= queued_at),
    CONSTRAINT delivery_cancelled_after_queue CHECK (cancelled_at IS NULL OR cancelled_at >= queued_at)
);

CREATE TABLE messaging.acknowledgement (
    acknowledgement_id BIGSERIAL PRIMARY KEY,
    delivery_id BIGINT NOT NULL REFERENCES messaging.delivery(delivery_id),
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT acknowledgement_delivery_unique UNIQUE (delivery_id)
);

CREATE TABLE communications.communication (
    communication_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES design.event(event_id),
    communication_type TEXT NOT NULL DEFAULT 'OPERATIONAL',
    title TEXT,
    message TEXT NOT NULL,
    poi_id BIGINT REFERENCES design.poi(poi_id),
    poi_item_id BIGINT REFERENCES design.poi_item(poi_item_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ,
    CONSTRAINT communication_type_valid CHECK (communication_type IN ('OPERATIONAL', 'EMERGENCY')),
    CONSTRAINT communication_target_valid CHECK (
        (poi_id IS NULL AND poi_item_id IS NULL)
        OR
        (poi_id IS NOT NULL AND poi_item_id IS NULL)
        OR
        (poi_id IS NULL AND poi_item_id IS NOT NULL)
    ),
    CONSTRAINT communication_expiry_after_creation CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE TABLE communications.subscription (
    subscription_id BIGSERIAL PRIMARY KEY,
    pal_id BIGINT NOT NULL REFERENCES community.pal(pal_id),
    poi_id BIGINT REFERENCES design.poi(poi_id),
    poi_item_id BIGINT REFERENCES design.poi_item(poi_item_id),
    subscribed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT subscription_target_valid CHECK (
        (poi_id IS NOT NULL AND poi_item_id IS NULL)
        OR
        (poi_id IS NULL AND poi_item_id IS NOT NULL)
    ),
    CONSTRAINT subscription_poi_unique UNIQUE (pal_id, poi_id),
    CONSTRAINT subscription_poi_item_unique UNIQUE (pal_id, poi_item_id)
);

CREATE TABLE audit.event (
    audit_event_id BIGSERIAL PRIMARY KEY,
    audit_type TEXT NOT NULL,
    actor_source TEXT NOT NULL,
    actor_reference TEXT,
    authority_reference TEXT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    before_state JSONB,
    after_state JSONB,
    details JSONB,
    CONSTRAINT audit_type_valid CHECK (audit_type IN ('OPERATOR', 'REMOTE', 'SYSTEM')),
    CONSTRAINT actor_source_valid CHECK (actor_source IN ('OPERATOR', 'REMOTE', 'SYSTEM'))
);

CREATE TABLE audit.operator (
    operator_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES design.event(event_id),
    firebase_uid TEXT NOT NULL,
    display_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT operator_event_firebase_unique UNIQUE (event_id, firebase_uid)
);

CREATE TABLE audit.authority (
    authority_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES design.event(event_id),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT authority_event_name_unique UNIQUE (event_id, name)
);

CREATE TABLE audit.operator_authority (
    operator_id BIGINT NOT NULL REFERENCES audit.operator(operator_id),
    authority_id BIGINT NOT NULL REFERENCES audit.authority(authority_id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (operator_id, authority_id)
);
