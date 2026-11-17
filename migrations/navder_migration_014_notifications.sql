-- Navder notification infrastructure.
-- Stores APNs device registrations and durable Crew Chat notification jobs.

CREATE TABLE IF NOT EXISTS messaging.notification_device (
    notification_device_id BIGSERIAL PRIMARY KEY,
    pal_id UUID NOT NULL REFERENCES community.pal(pal_id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    environment TEXT NOT NULL CHECK (environment IN ('development', 'production')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    invalidated_at TIMESTAMPTZ NULL,
    UNIQUE (environment, device_token)
);

CREATE INDEX IF NOT EXISTS notification_device_pal_idx
    ON messaging.notification_device (pal_id)
    WHERE invalidated_at IS NULL;

CREATE TABLE IF NOT EXISTS messaging.notification_outbox (
    notification_outbox_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL,
    crew_id BIGINT NOT NULL,
    crew_message_id BIGINT NOT NULL,
    recipient_crew_pal_id BIGINT NOT NULL,
    recipient_pal_id UUID NOT NULL REFERENCES community.pal(pal_id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'SENDING', 'SENT', 'CANCELLED')),
    attempt_count INTEGER NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    locked_at TIMESTAMPTZ NULL,
    sent_at TIMESTAMPTZ NULL,
    last_error TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (crew_message_id, recipient_pal_id, notification_type)
);

CREATE INDEX IF NOT EXISTS notification_outbox_pending_idx
    ON messaging.notification_outbox (status, available_at, notification_outbox_id);
