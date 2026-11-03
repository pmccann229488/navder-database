--
-- PostgreSQL database dump
--

\restrict BkkRVtSDg7AZeP7ujYoVFQKsZGk4iKPC4RRuDUwoThr1VsYtOnPbIUezafmwcOJ

-- Dumped from database version 18.6 (Homebrew)
-- Dumped by pg_dump version 18.6 (Homebrew)

-- Started on 2026-10-31 14:50:50 GMT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 31173)
-- Name: activity; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA activity;


--
-- TOC entry 8 (class 2615 OID 31174)
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- TOC entry 9 (class 2615 OID 31175)
-- Name: communications; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA communications;


--
-- TOC entry 10 (class 2615 OID 31176)
-- Name: community; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA community;


--
-- TOC entry 11 (class 2615 OID 31177)
-- Name: content; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA content;


--
-- TOC entry 12 (class 2615 OID 31178)
-- Name: design; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA design;


--
-- TOC entry 13 (class 2615 OID 31179)
-- Name: intelligence; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA intelligence;


--
-- TOC entry 14 (class 2615 OID 31180)
-- Name: messaging; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA messaging;


--
-- TOC entry 15 (class 2615 OID 31181)
-- Name: operations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA operations;


--
-- TOC entry 16 (class 2615 OID 31182)
-- Name: survey; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA survey;


--
-- TOC entry 2 (class 3079 OID 31183)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 5839 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 1773 (class 1247 OID 32266)
-- Name: congestion_level; Type: TYPE; Schema: design; Owner: -
--

CREATE TYPE design.congestion_level AS ENUM (
    'NONE',
    'LOW',
    'MEDIUM',
    'HIGH',
    'SEVERE'
);


--
-- TOC entry 1776 (class 1247 OID 32278)
-- Name: weather_condition; Type: TYPE; Schema: design; Owner: -
--

CREATE TYPE design.weather_condition AS ENUM (
    'CLEAR',
    'PARTLY_CLOUDY',
    'CLOUDY',
    'RAIN',
    'HEAVY_RAIN',
    'WIND',
    'STORM',
    'SNOW',
    'FOG'
);


--
-- TOC entry 497 (class 1255 OID 41953)
-- Name: validate_crew_message_membership(); Type: FUNCTION; Schema: community; Owner: -
--

CREATE FUNCTION community.validate_crew_message_membership() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 235 (class 1259 OID 32297)
-- Name: assistance_request; Type: TABLE; Schema: activity; Owner: -
--

CREATE TABLE activity.assistance_request (
    assistance_request_id bigint NOT NULL,
    event_id bigint NOT NULL,
    request_reference text NOT NULL,
    requested_at timestamp with time zone DEFAULT now() NOT NULL,
    notified_pal_count integer DEFAULT 0 NOT NULL,
    acknowledged_pal_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT assistance_acknowledged_count_valid CHECK ((acknowledged_pal_count >= 0)),
    CONSTRAINT assistance_acknowledged_not_exceed_notified CHECK ((acknowledged_pal_count <= notified_pal_count)),
    CONSTRAINT assistance_notified_count_valid CHECK ((notified_pal_count >= 0))
);


--
-- TOC entry 236 (class 1259 OID 32316)
-- Name: assistance_request_assistance_request_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.assistance_request_assistance_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5840 (class 0 OID 0)
-- Dependencies: 236
-- Name: assistance_request_assistance_request_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.assistance_request_assistance_request_id_seq OWNED BY activity.assistance_request.assistance_request_id;


--
-- TOC entry 237 (class 1259 OID 32317)
-- Name: navigation_event; Type: TABLE; Schema: activity; Owner: -
--

CREATE TABLE activity.navigation_event (
    navigation_event_id bigint NOT NULL,
    navigation_session_id bigint NOT NULL,
    event_type text NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    details jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 238 (class 1259 OID 32329)
-- Name: navigation_event_navigation_event_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.navigation_event_navigation_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5841 (class 0 OID 0)
-- Dependencies: 238
-- Name: navigation_event_navigation_event_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.navigation_event_navigation_event_id_seq OWNED BY activity.navigation_event.navigation_event_id;


--
-- TOC entry 239 (class 1259 OID 32330)
-- Name: navigation_segment; Type: TABLE; Schema: activity; Owner: -
--

CREATE TABLE activity.navigation_segment (
    navigation_segment_id bigint NOT NULL,
    navigation_session_id bigint NOT NULL,
    path_segment_id bigint NOT NULL,
    sequence_no integer NOT NULL,
    entered_at timestamp with time zone,
    exited_at timestamp with time zone,
    distance_metres numeric(10,2),
    duration_seconds integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT navigation_segment_distance_valid CHECK (((distance_metres IS NULL) OR (distance_metres >= (0)::numeric))),
    CONSTRAINT navigation_segment_duration_valid CHECK (((duration_seconds IS NULL) OR (duration_seconds >= 0))),
    CONSTRAINT navigation_segment_sequence_valid CHECK ((sequence_no > 0)),
    CONSTRAINT navigation_segment_times_valid CHECK (((exited_at IS NULL) OR (entered_at IS NULL) OR (exited_at >= entered_at)))
);


--
-- TOC entry 240 (class 1259 OID 32343)
-- Name: navigation_segment_navigation_segment_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.navigation_segment_navigation_segment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5842 (class 0 OID 0)
-- Dependencies: 240
-- Name: navigation_segment_navigation_segment_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.navigation_segment_navigation_segment_id_seq OWNED BY activity.navigation_segment.navigation_segment_id;


--
-- TOC entry 241 (class 1259 OID 32344)
-- Name: navigation_session; Type: TABLE; Schema: activity; Owner: -
--

CREATE TABLE activity.navigation_session (
    navigation_session_id bigint NOT NULL,
    event_id bigint NOT NULL,
    session_reference text NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    start_location public.geometry(Point,4326),
    destination text,
    planned_distance_metres numeric(10,2),
    actual_distance_metres numeric(10,2),
    duration_seconds integer,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT navigation_session_actual_distance_valid CHECK (((actual_distance_metres IS NULL) OR (actual_distance_metres >= (0)::numeric))),
    CONSTRAINT navigation_session_completion_valid CHECK (((completed_at IS NULL) OR (completed_at >= started_at))),
    CONSTRAINT navigation_session_duration_valid CHECK (((duration_seconds IS NULL) OR (duration_seconds >= 0))),
    CONSTRAINT navigation_session_planned_distance_valid CHECK (((planned_distance_metres IS NULL) OR (planned_distance_metres >= (0)::numeric)))
);


--
-- TOC entry 242 (class 1259 OID 32364)
-- Name: navigation_session_navigation_session_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.navigation_session_navigation_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5843 (class 0 OID 0)
-- Dependencies: 242
-- Name: navigation_session_navigation_session_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.navigation_session_navigation_session_id_seq OWNED BY activity.navigation_session.navigation_session_id;


--
-- TOC entry 243 (class 1259 OID 32365)
-- Name: pal_pinger_session; Type: TABLE; Schema: activity; Owner: -
--

CREATE TABLE activity.pal_pinger_session (
    pal_pinger_session_id bigint NOT NULL,
    event_id bigint NOT NULL,
    session_reference text NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pal_pinger_session_completion_valid CHECK (((completed_at IS NULL) OR (completed_at >= started_at)))
);


--
-- TOC entry 244 (class 1259 OID 32382)
-- Name: pal_pinger_session_pal_pinger_session_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.pal_pinger_session_pal_pinger_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5844 (class 0 OID 0)
-- Dependencies: 244
-- Name: pal_pinger_session_pal_pinger_session_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.pal_pinger_session_pal_pinger_session_id_seq OWNED BY activity.pal_pinger_session.pal_pinger_session_id;


--
-- TOC entry 245 (class 1259 OID 32383)
-- Name: authority; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.authority (
    authority_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 246 (class 1259 OID 32393)
-- Name: authority_authority_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.authority_authority_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5845 (class 0 OID 0)
-- Dependencies: 246
-- Name: authority_authority_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.authority_authority_id_seq OWNED BY audit.authority.authority_id;


--
-- TOC entry 247 (class 1259 OID 32394)
-- Name: event; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.event (
    audit_event_id bigint NOT NULL,
    audit_type text NOT NULL,
    actor_source text NOT NULL,
    actor_reference text,
    authority_reference text,
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id text,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    before_state jsonb,
    after_state jsonb,
    details jsonb,
    CONSTRAINT actor_source_valid CHECK ((actor_source = ANY (ARRAY['OPERATOR'::text, 'REMOTE'::text, 'SYSTEM'::text]))),
    CONSTRAINT audit_type_valid CHECK ((audit_type = ANY (ARRAY['OPERATOR'::text, 'REMOTE'::text, 'SYSTEM'::text])))
);


--
-- TOC entry 248 (class 1259 OID 32408)
-- Name: event_audit_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.event_audit_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5846 (class 0 OID 0)
-- Dependencies: 248
-- Name: event_audit_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.event_audit_event_id_seq OWNED BY audit.event.audit_event_id;


--
-- TOC entry 249 (class 1259 OID 32409)
-- Name: operator; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.operator (
    operator_id bigint NOT NULL,
    event_id bigint NOT NULL,
    firebase_uid text NOT NULL,
    display_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 250 (class 1259 OID 32420)
-- Name: operator_authority; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.operator_authority (
    operator_id bigint NOT NULL,
    authority_id bigint NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 251 (class 1259 OID 32427)
-- Name: operator_operator_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.operator_operator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5847 (class 0 OID 0)
-- Dependencies: 251
-- Name: operator_operator_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.operator_operator_id_seq OWNED BY audit.operator.operator_id;


--
-- TOC entry 252 (class 1259 OID 32428)
-- Name: communication; Type: TABLE; Schema: communications; Owner: -
--

CREATE TABLE communications.communication (
    communication_id bigint NOT NULL,
    event_id bigint NOT NULL,
    communication_type text DEFAULT 'OPERATIONAL'::text NOT NULL,
    title text,
    message text NOT NULL,
    poi_id bigint,
    poi_item_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    item_sequence_id bigint,
    CONSTRAINT communication_expiry_after_creation CHECK (((expires_at IS NULL) OR (expires_at > created_at))),
    CONSTRAINT communication_target_valid CHECK ((((poi_id IS NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NOT NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NULL) AND (poi_item_id IS NOT NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NOT NULL)))),
    CONSTRAINT communication_type_valid CHECK ((communication_type = ANY (ARRAY['OPERATIONAL'::text, 'EMERGENCY'::text])))
);


--
-- TOC entry 253 (class 1259 OID 32443)
-- Name: communication_communication_id_seq; Type: SEQUENCE; Schema: communications; Owner: -
--

CREATE SEQUENCE communications.communication_communication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5848 (class 0 OID 0)
-- Dependencies: 253
-- Name: communication_communication_id_seq; Type: SEQUENCE OWNED BY; Schema: communications; Owner: -
--

ALTER SEQUENCE communications.communication_communication_id_seq OWNED BY communications.communication.communication_id;


--
-- TOC entry 254 (class 1259 OID 32444)
-- Name: subscription; Type: TABLE; Schema: communications; Owner: -
--

CREATE TABLE communications.subscription (
    subscription_id bigint NOT NULL,
    pal_id uuid NOT NULL,
    poi_id bigint,
    poi_item_id bigint,
    subscribed_at timestamp with time zone DEFAULT now() NOT NULL,
    item_sequence_id bigint,
    CONSTRAINT subscription_target_valid CHECK ((((poi_id IS NOT NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NULL) AND (poi_item_id IS NOT NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NOT NULL))))
);


--
-- TOC entry 255 (class 1259 OID 32452)
-- Name: subscription_subscription_id_seq; Type: SEQUENCE; Schema: communications; Owner: -
--

CREATE SEQUENCE communications.subscription_subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5849 (class 0 OID 0)
-- Dependencies: 255
-- Name: subscription_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: communications; Owner: -
--

ALTER SEQUENCE communications.subscription_subscription_id_seq OWNED BY communications.subscription.subscription_id;


--
-- TOC entry 256 (class 1259 OID 32453)
-- Name: crew; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew (
    crew_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    event_id bigint NOT NULL
);


--
-- TOC entry 257 (class 1259 OID 32465)
-- Name: crew_crew_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.crew_crew_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5850 (class 0 OID 0)
-- Dependencies: 257
-- Name: crew_crew_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.crew_crew_id_seq OWNED BY community.crew.crew_id;


--
-- TOC entry 352 (class 1259 OID 36400)
-- Name: crew_invitation; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_invitation (
    crew_id bigint NOT NULL,
    token_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT crew_invitation_token_hash_not_empty CHECK ((length(btrim(token_hash)) > 0))
);


--
-- TOC entry 356 (class 1259 OID 41873)
-- Name: crew_meetup; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_meetup (
    crew_meetup_id bigint NOT NULL,
    event_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    poi_id bigint NOT NULL,
    organiser_pal_id uuid,
    mode text NOT NULL,
    scheduled_at timestamp with time zone,
    status text DEFAULT 'OPEN'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    ended_at timestamp with time zone,
    CONSTRAINT crew_meetup_ended_valid CHECK (((ended_at IS NULL) OR (ended_at >= created_at))),
    CONSTRAINT crew_meetup_expiry_valid CHECK (((expires_at IS NULL) OR (expires_at > created_at))),
    CONSTRAINT crew_meetup_mode_valid CHECK ((mode = ANY (ARRAY['MEET_NOW'::text, 'SCHEDULED'::text]))),
    CONSTRAINT crew_meetup_schedule_valid CHECK ((((mode = 'MEET_NOW'::text) AND (scheduled_at IS NULL)) OR ((mode = 'SCHEDULED'::text) AND (scheduled_at IS NOT NULL)))),
    CONSTRAINT crew_meetup_status_valid CHECK ((status = ANY (ARRAY['OPEN'::text, 'CANCELLED'::text, 'COMPLETED'::text, 'EXPIRED'::text])))
);


--
-- TOC entry 5851 (class 0 OID 0)
-- Dependencies: 356
-- Name: TABLE crew_meetup; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON TABLE community.crew_meetup IS 'Crew-owned rendezvous records; composite foreign keys enforce same-event Crew/POI integrity.';


--
-- TOC entry 355 (class 1259 OID 41872)
-- Name: crew_meetup_crew_meetup_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

ALTER TABLE community.crew_meetup ALTER COLUMN crew_meetup_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME community.crew_meetup_crew_meetup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 358 (class 1259 OID 41915)
-- Name: crew_meetup_response; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_meetup_response (
    crew_meetup_response_id bigint NOT NULL,
    crew_meetup_id bigint NOT NULL,
    pal_id uuid NOT NULL,
    response text NOT NULL,
    responded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT crew_meetup_response_value_valid CHECK ((response = ANY (ARRAY['ON_MY_WAY'::text, 'CANT_MAKE_IT'::text])))
);


--
-- TOC entry 5852 (class 0 OID 0)
-- Dependencies: 358
-- Name: TABLE crew_meetup_response; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON TABLE community.crew_meetup_response IS 'One current response per Pal per Meet-up; no attendee location is stored.';


--
-- TOC entry 357 (class 1259 OID 41914)
-- Name: crew_meetup_response_crew_meetup_response_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

ALTER TABLE community.crew_meetup_response ALTER COLUMN crew_meetup_response_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME community.crew_meetup_response_crew_meetup_response_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 258 (class 1259 OID 32466)
-- Name: crew_message; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_message (
    crew_message_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    pal_id uuid,
    message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    message_type text DEFAULT 'USER'::text NOT NULL,
    ciphertext bytea,
    actor_kind text,
    actor_pal_id uuid,
    affected_pal_id uuid,
    idempotency_key uuid NOT NULL,
    crew_pal_id bigint,
    CONSTRAINT crew_message_actor_kind_valid CHECK (((actor_kind IS NULL) OR (actor_kind = ANY (ARRAY['PAL'::text, 'SERVICE'::text])))),
    CONSTRAINT crew_message_payload_shape CHECK ((((message_type = 'USER'::text) AND (pal_id IS NOT NULL) AND (crew_pal_id IS NOT NULL) AND (ciphertext IS NOT NULL) AND (message IS NULL) AND (actor_kind IS NULL) AND (actor_pal_id IS NULL) AND (affected_pal_id IS NULL)) OR ((message_type = ANY (ARRAY['MEMBER_JOINED'::text, 'MEMBER_LEFT'::text, 'MEMBER_REMOVED'::text])) AND (pal_id IS NULL) AND (crew_pal_id IS NULL) AND (message IS NULL) AND (ciphertext IS NULL) AND (affected_pal_id IS NOT NULL) AND (((actor_kind = 'PAL'::text) AND (actor_pal_id IS NOT NULL)) OR ((actor_kind = 'SERVICE'::text) AND (actor_pal_id IS NULL))) AND (((message_type = ANY (ARRAY['MEMBER_JOINED'::text, 'MEMBER_LEFT'::text])) AND (actor_kind = 'PAL'::text) AND (actor_pal_id = affected_pal_id)) OR ((message_type = 'MEMBER_REMOVED'::text) AND (((actor_kind = 'PAL'::text) AND (actor_pal_id IS DISTINCT FROM affected_pal_id)) OR (actor_kind = 'SERVICE'::text))))))),
    CONSTRAINT crew_message_type_valid CHECK ((message_type = ANY (ARRAY['USER'::text, 'MEMBER_JOINED'::text, 'MEMBER_LEFT'::text, 'MEMBER_REMOVED'::text])))
);


--
-- TOC entry 5853 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN crew_message.ciphertext; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON COLUMN community.crew_message.ciphertext IS 'Opaque client-encrypted user message bytes. Server must not write plaintext content.';


--
-- TOC entry 5854 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN crew_message.idempotency_key; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON COLUMN community.crew_message.idempotency_key IS 'Stable UUID for one logical message/event operation; caller must reuse it on retries.';


--
-- TOC entry 5855 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN crew_message.crew_pal_id; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON COLUMN community.crew_message.crew_pal_id IS 'Sender membership-period ID. Identifies which Crew membership period was active when the message was sent.';


--
-- TOC entry 259 (class 1259 OID 32477)
-- Name: crew_message_crew_message_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.crew_message_crew_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5856 (class 0 OID 0)
-- Dependencies: 259
-- Name: crew_message_crew_message_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.crew_message_crew_message_id_seq OWNED BY community.crew_message.crew_message_id;


--
-- TOC entry 260 (class 1259 OID 32478)
-- Name: crew_pal; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_pal (
    crew_pal_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    pal_id uuid NOT NULL,
    joined_at timestamp with time zone,
    left_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    display_name text NOT NULL,
    membership_status text DEFAULT 'ACTIVE'::text NOT NULL,
    CONSTRAINT crew_pal_dates_valid CHECK (((left_at IS NULL) OR (left_at > joined_at))),
    CONSTRAINT crew_pal_membership_joined_at_consistent CHECK ((((membership_status = 'PENDING'::text) AND (joined_at IS NULL)) OR ((membership_status = 'ACTIVE'::text) AND (joined_at IS NOT NULL)))),
    CONSTRAINT crew_pal_membership_status_valid CHECK ((membership_status = ANY (ARRAY['PENDING'::text, 'ACTIVE'::text]))),
    CONSTRAINT crew_pal_pending_has_no_departure CHECK (((membership_status IS DISTINCT FROM 'PENDING'::text) OR (left_at IS NULL)))
);


--
-- TOC entry 5857 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN crew_pal.joined_at; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON COLUMN community.crew_pal.joined_at IS 'Effective membership admission timestamp. NULL while PENDING; explicitly set on transition to ACTIVE. Existing values are preserved.';


--
-- TOC entry 5858 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN crew_pal.left_at; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON COLUMN community.crew_pal.left_at IS 'NULL while the membership period remains open. Populated when an admitted membership period ends. PENDING memberships must have left_at NULL.';


--
-- TOC entry 5859 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN crew_pal.membership_status; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON COLUMN community.crew_pal.membership_status IS 'Admission lifecycle: PENDING means MLS admission has not completed; ACTIVE means admission completed successfully. ACTIVE is retained for historical admitted membership periods; left_at indicates whether the period has ended.';


--
-- TOC entry 5860 (class 0 OID 0)
-- Dependencies: 260
-- Name: CONSTRAINT crew_pal_pending_has_no_departure ON crew_pal; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON CONSTRAINT crew_pal_pending_has_no_departure ON community.crew_pal IS 'A PENDING Crew membership has not become effective and therefore cannot have a departure timestamp.';


--
-- TOC entry 261 (class 1259 OID 32492)
-- Name: crew_pal_crew_pal_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.crew_pal_crew_pal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5861 (class 0 OID 0)
-- Dependencies: 261
-- Name: crew_pal_crew_pal_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.crew_pal_crew_pal_id_seq OWNED BY community.crew_pal.crew_pal_id;


--
-- TOC entry 354 (class 1259 OID 41842)
-- Name: crew_pick; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_pick (
    crew_pick_id bigint NOT NULL,
    event_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    poi_id bigint NOT NULL,
    created_by_pal_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 5862 (class 0 OID 0)
-- Dependencies: 354
-- Name: TABLE crew_pick; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON TABLE community.crew_pick IS 'Crew-owned persistent POI picks. Creator departure does not delete the pick.';


--
-- TOC entry 353 (class 1259 OID 41841)
-- Name: crew_pick_crew_pick_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

ALTER TABLE community.crew_pick ALTER COLUMN crew_pick_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME community.crew_pick_crew_pick_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 351 (class 1259 OID 33754)
-- Name: event_session; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.event_session (
    event_session_id uuid DEFAULT gen_random_uuid() NOT NULL,
    pal_id uuid NOT NULL,
    event_id bigint NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    ended_at timestamp with time zone,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT event_session_dates_valid CHECK (((ended_at IS NULL) OR (ended_at >= started_at))),
    CONSTRAINT event_session_status_valid CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'ENDED'::text])))
);


--
-- TOC entry 262 (class 1259 OID 32493)
-- Name: pal; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.pal (
    pal_id uuid NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 263 (class 1259 OID 32504)
-- Name: allergen; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.allergen (
    allergen_id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 264 (class 1259 OID 32516)
-- Name: allergen_allergen_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.allergen_allergen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5863 (class 0 OID 0)
-- Dependencies: 264
-- Name: allergen_allergen_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.allergen_allergen_id_seq OWNED BY design.allergen.allergen_id;


--
-- TOC entry 265 (class 1259 OID 32517)
-- Name: dietary_attribute; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.dietary_attribute (
    dietary_attribute_id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 266 (class 1259 OID 32529)
-- Name: dietary_attribute_dietary_attribute_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.dietary_attribute_dietary_attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5864 (class 0 OID 0)
-- Dependencies: 266
-- Name: dietary_attribute_dietary_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.dietary_attribute_dietary_attribute_id_seq OWNED BY design.dietary_attribute.dietary_attribute_id;


--
-- TOC entry 267 (class 1259 OID 32530)
-- Name: elevator; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.elevator (
    elevator_id bigint NOT NULL,
    traversal_path_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 268 (class 1259 OID 32542)
-- Name: elevator_elevator_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.elevator_elevator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5865 (class 0 OID 0)
-- Dependencies: 268
-- Name: elevator_elevator_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.elevator_elevator_id_seq OWNED BY design.elevator.elevator_id;


--
-- TOC entry 269 (class 1259 OID 32543)
-- Name: escalator; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.escalator (
    escalator_id bigint NOT NULL,
    traversal_path_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 270 (class 1259 OID 32555)
-- Name: escalator_escalator_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.escalator_escalator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5866 (class 0 OID 0)
-- Dependencies: 270
-- Name: escalator_escalator_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.escalator_escalator_id_seq OWNED BY design.escalator.escalator_id;


--
-- TOC entry 271 (class 1259 OID 32556)
-- Name: event; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.event (
    event_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'DRAFT'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone NOT NULL,
    remote_support_enabled boolean DEFAULT false NOT NULL,
    api_url text,
    runtime_url text,
    runtime_version text,
    CONSTRAINT event_dates_valid CHECK ((end_at > start_at))
);


--
-- TOC entry 272 (class 1259 OID 32574)
-- Name: event_beacon; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.event_beacon (
    event_beacon_id bigint NOT NULL,
    event_id bigint NOT NULL,
    poi_id bigint,
    name text NOT NULL,
    description text,
    geometry public.geometry(Point,4326) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 273 (class 1259 OID 32587)
-- Name: event_beacon_event_beacon_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_beacon_event_beacon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5867 (class 0 OID 0)
-- Dependencies: 273
-- Name: event_beacon_event_beacon_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_beacon_event_beacon_id_seq OWNED BY design.event_beacon.event_beacon_id;


--
-- TOC entry 274 (class 1259 OID 32588)
-- Name: event_beacon_physical; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.event_beacon_physical (
    event_beacon_physical_id bigint NOT NULL,
    event_beacon_id bigint NOT NULL,
    physical_beacon_id bigint NOT NULL,
    role text NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    description text,
    CONSTRAINT event_beacon_physical_role_valid CHECK ((role = ANY (ARRAY['PRIMARY'::text, 'SECONDARY'::text])))
);


--
-- TOC entry 275 (class 1259 OID 32600)
-- Name: event_beacon_physical_event_beacon_physical_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_beacon_physical_event_beacon_physical_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5868 (class 0 OID 0)
-- Dependencies: 275
-- Name: event_beacon_physical_event_beacon_physical_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_beacon_physical_event_beacon_physical_id_seq OWNED BY design.event_beacon_physical.event_beacon_physical_id;


--
-- TOC entry 276 (class 1259 OID 32601)
-- Name: event_day; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.event_day (
    event_day_id bigint NOT NULL,
    event_id bigint NOT NULL,
    day_number integer NOT NULL,
    name text,
    date date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT event_day_number_positive CHECK ((day_number > 0))
);


--
-- TOC entry 277 (class 1259 OID 32615)
-- Name: event_day_event_day_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_day_event_day_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5869 (class 0 OID 0)
-- Dependencies: 277
-- Name: event_day_event_day_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_day_event_day_id_seq OWNED BY design.event_day.event_day_id;


--
-- TOC entry 278 (class 1259 OID 32616)
-- Name: event_event_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5870 (class 0 OID 0)
-- Dependencies: 278
-- Name: event_event_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_event_id_seq OWNED BY design.event.event_id;


--
-- TOC entry 279 (class 1259 OID 32617)
-- Name: flight; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.flight (
    flight_id bigint NOT NULL,
    staircase_id bigint NOT NULL,
    sequence_no integer NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT flight_sequence_valid CHECK ((sequence_no > 0))
);


--
-- TOC entry 280 (class 1259 OID 32631)
-- Name: flight_flight_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.flight_flight_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5871 (class 0 OID 0)
-- Dependencies: 280
-- Name: flight_flight_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.flight_flight_id_seq OWNED BY design.flight.flight_id;


--
-- TOC entry 281 (class 1259 OID 32632)
-- Name: item_sequence; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.item_sequence (
    item_sequence_id bigint NOT NULL,
    event_day_id bigint NOT NULL,
    poi_item_id bigint NOT NULL,
    sequence_no integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    scheduled_start_time time without time zone,
    duration_minutes integer,
    CONSTRAINT item_sequence_duration_positive CHECK (((duration_minutes IS NULL) OR (duration_minutes > 0))),
    CONSTRAINT item_sequence_number_positive CHECK ((sequence_no > 0)),
    CONSTRAINT item_sequence_schedule_complete CHECK ((((scheduled_start_time IS NULL) AND (duration_minutes IS NULL)) OR ((scheduled_start_time IS NOT NULL) AND (duration_minutes IS NOT NULL))))
);


--
-- TOC entry 282 (class 1259 OID 32646)
-- Name: item_sequence_item_sequence_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.item_sequence_item_sequence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5872 (class 0 OID 0)
-- Dependencies: 282
-- Name: item_sequence_item_sequence_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.item_sequence_item_sequence_id_seq OWNED BY design.item_sequence.item_sequence_id;


--
-- TOC entry 283 (class 1259 OID 32647)
-- Name: junction; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.junction (
    junction_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text,
    geometry public.geometry(Point,4326) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    display_geometry public.geometry(Polygon,4326),
    display_image_ref text
);


--
-- TOC entry 284 (class 1259 OID 32659)
-- Name: junction_junction_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.junction_junction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5873 (class 0 OID 0)
-- Dependencies: 284
-- Name: junction_junction_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.junction_junction_id_seq OWNED BY design.junction.junction_id;


--
-- TOC entry 285 (class 1259 OID 32660)
-- Name: offering; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering (
    offering_id bigint NOT NULL,
    poi_id bigint NOT NULL,
    offering_type_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 286 (class 1259 OID 32673)
-- Name: offering_availability; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_availability (
    offering_availability_id bigint NOT NULL,
    offering_id bigint NOT NULL,
    starts_at time without time zone NOT NULL,
    ends_at time without time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT offering_availability_time_order CHECK ((ends_at > starts_at))
);


--
-- TOC entry 287 (class 1259 OID 32685)
-- Name: offering_availability_offering_availability_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_availability_offering_availability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5874 (class 0 OID 0)
-- Dependencies: 287
-- Name: offering_availability_offering_availability_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_availability_offering_availability_id_seq OWNED BY design.offering_availability.offering_availability_id;


--
-- TOC entry 288 (class 1259 OID 32686)
-- Name: offering_item; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_item (
    offering_item_id bigint NOT NULL,
    offering_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    price numeric(10,2),
    image_ref text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT offering_item_price_non_negative CHECK (((price IS NULL) OR (price >= (0)::numeric)))
);


--
-- TOC entry 289 (class 1259 OID 32699)
-- Name: offering_item_allergen; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_item_allergen (
    offering_item_id bigint NOT NULL,
    allergen_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 290 (class 1259 OID 32706)
-- Name: offering_item_dietary_attribute; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_item_dietary_attribute (
    offering_item_id bigint NOT NULL,
    dietary_attribute_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 291 (class 1259 OID 32713)
-- Name: offering_item_offering_item_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_item_offering_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5875 (class 0 OID 0)
-- Dependencies: 291
-- Name: offering_item_offering_item_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_item_offering_item_id_seq OWNED BY design.offering_item.offering_item_id;


--
-- TOC entry 292 (class 1259 OID 32714)
-- Name: offering_offering_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_offering_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5876 (class 0 OID 0)
-- Dependencies: 292
-- Name: offering_offering_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_offering_id_seq OWNED BY design.offering.offering_id;


--
-- TOC entry 293 (class 1259 OID 32715)
-- Name: offering_type; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_type (
    offering_type_id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 294 (class 1259 OID 32727)
-- Name: offering_type_offering_type_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_type_offering_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5877 (class 0 OID 0)
-- Dependencies: 294
-- Name: offering_type_offering_type_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_type_offering_type_id_seq OWNED BY design.offering_type.offering_type_id;


--
-- TOC entry 295 (class 1259 OID 32728)
-- Name: path; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.path (
    path_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 296 (class 1259 OID 32739)
-- Name: path_connector; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.path_connector (
    path_connector_id bigint NOT NULL,
    path_id bigint NOT NULL,
    name text,
    geometry public.geometry(Point,4326) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 297 (class 1259 OID 32751)
-- Name: path_connector_path_connector_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_connector_path_connector_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5878 (class 0 OID 0)
-- Dependencies: 297
-- Name: path_connector_path_connector_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_connector_path_connector_id_seq OWNED BY design.path_connector.path_connector_id;


--
-- TOC entry 298 (class 1259 OID 32752)
-- Name: path_endpoint; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.path_endpoint (
    path_endpoint_id bigint NOT NULL,
    path_id bigint NOT NULL,
    endpoint_order smallint NOT NULL,
    junction_id bigint,
    zone_connector_id bigint,
    terminus_id bigint,
    CONSTRAINT path_endpoint_exactly_one_target CHECK ((((((junction_id IS NOT NULL))::integer + ((zone_connector_id IS NOT NULL))::integer) + ((terminus_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT path_endpoint_order_valid CHECK ((endpoint_order = ANY (ARRAY[1, 2])))
);


--
-- TOC entry 299 (class 1259 OID 32760)
-- Name: path_endpoint_path_endpoint_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_endpoint_path_endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5879 (class 0 OID 0)
-- Dependencies: 299
-- Name: path_endpoint_path_endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_endpoint_path_endpoint_id_seq OWNED BY design.path_endpoint.path_endpoint_id;


--
-- TOC entry 300 (class 1259 OID 32761)
-- Name: path_path_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_path_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5880 (class 0 OID 0)
-- Dependencies: 300
-- Name: path_path_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_path_id_seq OWNED BY design.path.path_id;


--
-- TOC entry 301 (class 1259 OID 32762)
-- Name: path_segment; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.path_segment (
    path_segment_id bigint NOT NULL,
    path_id bigint NOT NULL,
    sequence_no integer NOT NULL,
    segment_type text DEFAULT 'NORMAL'::text NOT NULL,
    geometry public.geometry(LineString,4326) NOT NULL,
    width_metres numeric(6,2),
    fallback_congestion design.congestion_level,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT path_segment_sequence_positive CHECK ((sequence_no > 0))
);


--
-- TOC entry 302 (class 1259 OID 32778)
-- Name: path_segment_congestion; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.path_segment_congestion (
    path_segment_congestion_id bigint NOT NULL,
    path_segment_id bigint NOT NULL,
    congestion_level design.congestion_level NOT NULL,
    observed_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 303 (class 1259 OID 32788)
-- Name: path_segment_congestion_path_segment_congestion_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_segment_congestion_path_segment_congestion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5881 (class 0 OID 0)
-- Dependencies: 303
-- Name: path_segment_congestion_path_segment_congestion_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_segment_congestion_path_segment_congestion_id_seq OWNED BY design.path_segment_congestion.path_segment_congestion_id;


--
-- TOC entry 304 (class 1259 OID 32789)
-- Name: path_segment_path_segment_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_segment_path_segment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5882 (class 0 OID 0)
-- Dependencies: 304
-- Name: path_segment_path_segment_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_segment_path_segment_id_seq OWNED BY design.path_segment.path_segment_id;


--
-- TOC entry 305 (class 1259 OID 32790)
-- Name: physical_beacon; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.physical_beacon (
    physical_beacon_id bigint NOT NULL,
    asset_name text NOT NULL,
    hardware_model text NOT NULL,
    ibeacon_uuid uuid NOT NULL,
    ibeacon_major integer NOT NULL,
    ibeacon_minor integer NOT NULL,
    status text DEFAULT 'AVAILABLE'::text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT physical_beacon_major_non_negative CHECK ((ibeacon_major >= 0)),
    CONSTRAINT physical_beacon_minor_non_negative CHECK ((ibeacon_minor >= 0))
);


--
-- TOC entry 306 (class 1259 OID 32809)
-- Name: physical_beacon_physical_beacon_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.physical_beacon_physical_beacon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5883 (class 0 OID 0)
-- Dependencies: 306
-- Name: physical_beacon_physical_beacon_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.physical_beacon_physical_beacon_id_seq OWNED BY design.physical_beacon.physical_beacon_id;


--
-- TOC entry 307 (class 1259 OID 32810)
-- Name: poi; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi (
    poi_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text NOT NULL,
    poi_type_id bigint CONSTRAINT poi_poi_type_not_null NOT NULL,
    description text,
    geometry public.geometry(Point,4326) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    lod_display_level integer
);


--
-- TOC entry 308 (class 1259 OID 32824)
-- Name: poi_capability; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_capability (
    poi_capability_id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 309 (class 1259 OID 32836)
-- Name: poi_capability_poi_capability_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_capability_poi_capability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5884 (class 0 OID 0)
-- Dependencies: 309
-- Name: poi_capability_poi_capability_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_capability_poi_capability_id_seq OWNED BY design.poi_capability.poi_capability_id;


--
-- TOC entry 310 (class 1259 OID 32837)
-- Name: poi_item; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_item (
    poi_item_id bigint NOT NULL,
    poi_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 311 (class 1259 OID 32849)
-- Name: poi_item_poi_item_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_item_poi_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5885 (class 0 OID 0)
-- Dependencies: 311
-- Name: poi_item_poi_item_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_item_poi_item_id_seq OWNED BY design.poi_item.poi_item_id;


--
-- TOC entry 312 (class 1259 OID 32850)
-- Name: poi_path_connector; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_path_connector (
    poi_id bigint NOT NULL,
    path_connector_id bigint NOT NULL,
    is_primary boolean DEFAULT false NOT NULL
);


--
-- TOC entry 313 (class 1259 OID 32857)
-- Name: poi_poi_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_poi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5886 (class 0 OID 0)
-- Dependencies: 313
-- Name: poi_poi_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_poi_id_seq OWNED BY design.poi.poi_id;


--
-- TOC entry 314 (class 1259 OID 32858)
-- Name: poi_type; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_type (
    poi_type_id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 315 (class 1259 OID 32870)
-- Name: poi_type_capability; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_type_capability (
    poi_type_id bigint NOT NULL,
    poi_capability_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 316 (class 1259 OID 32877)
-- Name: poi_type_poi_type_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_type_poi_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5887 (class 0 OID 0)
-- Dependencies: 316
-- Name: poi_type_poi_type_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_type_poi_type_id_seq OWNED BY design.poi_type.poi_type_id;


--
-- TOC entry 317 (class 1259 OID 32878)
-- Name: queue; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.queue (
    queue_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    fallback_wait_seconds integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    poi_id bigint NOT NULL,
    CONSTRAINT queue_fallback_wait_valid CHECK (((fallback_wait_seconds IS NULL) OR (fallback_wait_seconds >= 0)))
);


--
-- TOC entry 318 (class 1259 OID 32892)
-- Name: queue_queue_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5888 (class 0 OID 0)
-- Dependencies: 318
-- Name: queue_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_queue_id_seq OWNED BY design.queue.queue_id;


--
-- TOC entry 319 (class 1259 OID 32893)
-- Name: queue_source; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.queue_source (
    queue_source_id bigint NOT NULL,
    queue_id bigint NOT NULL,
    queue_source_type_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 320 (class 1259 OID 32906)
-- Name: queue_source_ble; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.queue_source_ble (
    queue_source_ble_id bigint NOT NULL,
    queue_source_id bigint NOT NULL,
    event_beacon_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 321 (class 1259 OID 32916)
-- Name: queue_source_ble_queue_source_ble_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_source_ble_queue_source_ble_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5889 (class 0 OID 0)
-- Dependencies: 321
-- Name: queue_source_ble_queue_source_ble_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_source_ble_queue_source_ble_id_seq OWNED BY design.queue_source_ble.queue_source_ble_id;


--
-- TOC entry 322 (class 1259 OID 32917)
-- Name: queue_source_queue_source_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_source_queue_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5890 (class 0 OID 0)
-- Dependencies: 322
-- Name: queue_source_queue_source_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_source_queue_source_id_seq OWNED BY design.queue_source.queue_source_id;


--
-- TOC entry 323 (class 1259 OID 32918)
-- Name: queue_source_type; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.queue_source_type (
    queue_source_type_id bigint NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 324 (class 1259 OID 32930)
-- Name: queue_source_type_queue_source_type_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_source_type_queue_source_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5891 (class 0 OID 0)
-- Dependencies: 324
-- Name: queue_source_type_queue_source_type_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_source_type_queue_source_type_id_seq OWNED BY design.queue_source_type.queue_source_type_id;


--
-- TOC entry 325 (class 1259 OID 32931)
-- Name: queue_wait_time; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.queue_wait_time (
    queue_wait_time_id bigint NOT NULL,
    queue_id bigint NOT NULL,
    wait_seconds integer NOT NULL,
    observed_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    queue_source_id bigint NOT NULL,
    CONSTRAINT queue_wait_time_valid CHECK ((wait_seconds >= 0))
);


--
-- TOC entry 326 (class 1259 OID 32943)
-- Name: queue_wait_time_queue_wait_time_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_wait_time_queue_wait_time_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5892 (class 0 OID 0)
-- Dependencies: 326
-- Name: queue_wait_time_queue_wait_time_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_wait_time_queue_wait_time_id_seq OWNED BY design.queue_wait_time.queue_wait_time_id;


--
-- TOC entry 327 (class 1259 OID 32944)
-- Name: ramp; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.ramp (
    ramp_id bigint NOT NULL,
    traversal_path_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 328 (class 1259 OID 32956)
-- Name: ramp_ramp_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.ramp_ramp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5893 (class 0 OID 0)
-- Dependencies: 328
-- Name: ramp_ramp_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.ramp_ramp_id_seq OWNED BY design.ramp.ramp_id;


--
-- TOC entry 329 (class 1259 OID 32957)
-- Name: staircase; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.staircase (
    staircase_id bigint NOT NULL,
    traversal_path_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 330 (class 1259 OID 32969)
-- Name: staircase_staircase_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.staircase_staircase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5894 (class 0 OID 0)
-- Dependencies: 330
-- Name: staircase_staircase_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.staircase_staircase_id_seq OWNED BY design.staircase.staircase_id;


--
-- TOC entry 331 (class 1259 OID 32970)
-- Name: terminus; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.terminus (
    terminus_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text NOT NULL,
    terminus_type text DEFAULT 'END'::text NOT NULL,
    geometry public.geometry(Point,4326) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 332 (class 1259 OID 32985)
-- Name: terminus_terminus_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.terminus_terminus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5895 (class 0 OID 0)
-- Dependencies: 332
-- Name: terminus_terminus_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.terminus_terminus_id_seq OWNED BY design.terminus.terminus_id;


--
-- TOC entry 333 (class 1259 OID 32986)
-- Name: traversal_destination; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.traversal_destination (
    traversal_destination_id bigint NOT NULL,
    poi_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 334 (class 1259 OID 32998)
-- Name: traversal_destination_traversal_destination_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.traversal_destination_traversal_destination_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5896 (class 0 OID 0)
-- Dependencies: 334
-- Name: traversal_destination_traversal_destination_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.traversal_destination_traversal_destination_id_seq OWNED BY design.traversal_destination.traversal_destination_id;


--
-- TOC entry 335 (class 1259 OID 32999)
-- Name: traversal_path; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.traversal_path (
    traversal_path_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    path_connector_id bigint NOT NULL,
    traversal_destination_id bigint NOT NULL
);


--
-- TOC entry 336 (class 1259 OID 33012)
-- Name: traversal_path_traversal_path_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.traversal_path_traversal_path_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5897 (class 0 OID 0)
-- Dependencies: 336
-- Name: traversal_path_traversal_path_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.traversal_path_traversal_path_id_seq OWNED BY design.traversal_path.traversal_path_id;


--
-- TOC entry 337 (class 1259 OID 33013)
-- Name: weather_forecast; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.weather_forecast (
    weather_forecast_id bigint NOT NULL,
    event_id bigint NOT NULL,
    forecast_at timestamp with time zone NOT NULL,
    valid_from timestamp with time zone NOT NULL,
    valid_to timestamp with time zone NOT NULL,
    temperature_c numeric(5,2),
    precipitation_probability numeric(5,2),
    wind_speed_mps numeric(6,2),
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    weather_condition design.weather_condition,
    CONSTRAINT weather_forecast_dates_valid CHECK ((valid_to > valid_from)),
    CONSTRAINT weather_forecast_precipitation_valid CHECK (((precipitation_probability IS NULL) OR ((precipitation_probability >= (0)::numeric) AND (precipitation_probability <= (100)::numeric))))
);


--
-- TOC entry 338 (class 1259 OID 33027)
-- Name: weather_forecast_weather_forecast_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.weather_forecast_weather_forecast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5898 (class 0 OID 0)
-- Dependencies: 338
-- Name: weather_forecast_weather_forecast_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.weather_forecast_weather_forecast_id_seq OWNED BY design.weather_forecast.weather_forecast_id;


--
-- TOC entry 339 (class 1259 OID 33028)
-- Name: weather_update; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.weather_update (
    weather_update_id bigint NOT NULL,
    event_id bigint NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    weather_condition design.weather_condition NOT NULL,
    message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT weather_update_dates_valid CHECK ((ends_at > starts_at))
);


--
-- TOC entry 340 (class 1259 OID 33043)
-- Name: weather_update_weather_update_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.weather_update_weather_update_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5899 (class 0 OID 0)
-- Dependencies: 340
-- Name: weather_update_weather_update_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.weather_update_weather_update_id_seq OWNED BY design.weather_update.weather_update_id;


--
-- TOC entry 341 (class 1259 OID 33044)
-- Name: zone; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.zone (
    zone_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text NOT NULL,
    description text,
    geometry public.geometry(Polygon,4326),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 342 (class 1259 OID 33056)
-- Name: zone_connector; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.zone_connector (
    zone_connector_id bigint NOT NULL,
    zone_id bigint NOT NULL,
    name text NOT NULL,
    connector_type text DEFAULT 'ACCESS'::text NOT NULL,
    geometry public.geometry(Point,4326) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 343 (class 1259 OID 33071)
-- Name: zone_connector_zone_connector_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.zone_connector_zone_connector_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5900 (class 0 OID 0)
-- Dependencies: 343
-- Name: zone_connector_zone_connector_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.zone_connector_zone_connector_id_seq OWNED BY design.zone_connector.zone_connector_id;


--
-- TOC entry 344 (class 1259 OID 33072)
-- Name: zone_zone_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.zone_zone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5901 (class 0 OID 0)
-- Dependencies: 344
-- Name: zone_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.zone_zone_id_seq OWNED BY design.zone.zone_id;


--
-- TOC entry 345 (class 1259 OID 33073)
-- Name: acknowledgement; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.acknowledgement (
    acknowledgement_id bigint NOT NULL,
    delivery_id bigint NOT NULL,
    acknowledged_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 346 (class 1259 OID 33080)
-- Name: acknowledgement_acknowledgement_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

CREATE SEQUENCE messaging.acknowledgement_acknowledgement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5902 (class 0 OID 0)
-- Dependencies: 346
-- Name: acknowledgement_acknowledgement_id_seq; Type: SEQUENCE OWNED BY; Schema: messaging; Owner: -
--

ALTER SEQUENCE messaging.acknowledgement_acknowledgement_id_seq OWNED BY messaging.acknowledgement.acknowledgement_id;


--
-- TOC entry 359 (class 1259 OID 42064)
-- Name: crew_mls_group; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.crew_mls_group (
    crew_id bigint NOT NULL,
    group_id bytea NOT NULL,
    next_sequence bigint DEFAULT 1 NOT NULL,
    reservation_id uuid,
    reservation_request_id uuid,
    reservation_owner_crew_pal_id bigint,
    reservation_fencing_token bigint DEFAULT 0 NOT NULL,
    reservation_expires_at timestamp with time zone,
    group_revision bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT crew_mls_group_fencing_nonnegative CHECK ((reservation_fencing_token >= 0)),
    CONSTRAINT crew_mls_group_group_id_nonempty CHECK ((octet_length(group_id) > 0)),
    CONSTRAINT crew_mls_group_next_sequence_positive CHECK ((next_sequence >= 1)),
    CONSTRAINT crew_mls_group_reservation_complete CHECK ((((reservation_id IS NULL) AND (reservation_request_id IS NULL) AND (reservation_owner_crew_pal_id IS NULL) AND (reservation_expires_at IS NULL)) OR ((reservation_id IS NOT NULL) AND (reservation_request_id IS NOT NULL) AND (reservation_owner_crew_pal_id IS NOT NULL) AND (reservation_expires_at IS NOT NULL)))),
    CONSTRAINT crew_mls_group_revision_nonnegative CHECK ((group_revision >= 0))
);


--
-- TOC entry 5903 (class 0 OID 0)
-- Dependencies: 359
-- Name: TABLE crew_mls_group; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON TABLE messaging.crew_mls_group IS 'One per-Crew MLS group coordination row. group_revision is an application concurrency revision, not an MLS epoch.';


--
-- TOC entry 5904 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN crew_mls_group.next_sequence; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON COLUMN messaging.crew_mls_group.next_sequence IS 'Next Crew transport sequence to allocate; independent of MLS epoch and group_revision.';


--
-- TOC entry 5905 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN crew_mls_group.reservation_fencing_token; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON COLUMN messaging.crew_mls_group.reservation_fencing_token IS 'Monotonically increasing fencing token. Never decremented or reused, including after release or expiry.';


--
-- TOC entry 5906 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN crew_mls_group.group_revision; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON COLUMN messaging.crew_mls_group.group_revision IS 'Server-side concurrency revision. Starts at 0 for initial creator bootstrap and increments once per accepted state-advancing Commit.';


--
-- TOC entry 361 (class 1259 OID 42133)
-- Name: crew_mls_key_package; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.crew_mls_key_package (
    key_package_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    crew_pal_id bigint NOT NULL,
    payload bytea NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    consumed_by_operation_id uuid,
    CONSTRAINT crew_mls_key_package_consumption_pair CHECK ((((consumed_at IS NULL) AND (consumed_by_operation_id IS NULL)) OR ((consumed_at IS NOT NULL) AND (consumed_by_operation_id IS NOT NULL)))),
    CONSTRAINT crew_mls_key_package_expiry_valid CHECK ((expires_at > created_at)),
    CONSTRAINT crew_mls_key_package_payload_nonempty CHECK ((octet_length(payload) > 0))
);


--
-- TOC entry 5907 (class 0 OID 0)
-- Dependencies: 361
-- Name: TABLE crew_mls_key_package; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON TABLE messaging.crew_mls_key_package IS 'Opaque MLS KeyPackage inventory. Consumption is one-time and atomic with accepted Commit submission; consumed rows are retained.';


--
-- TOC entry 360 (class 1259 OID 42132)
-- Name: crew_mls_key_package_key_package_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

ALTER TABLE messaging.crew_mls_key_package ALTER COLUMN key_package_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME messaging.crew_mls_key_package_key_package_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 347 (class 1259 OID 33081)
-- Name: delivery; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.delivery (
    delivery_id bigint NOT NULL,
    message_id bigint NOT NULL,
    pal_id uuid,
    status text DEFAULT 'QUEUED'::text NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    delivered_at timestamp with time zone,
    expires_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp with time zone,
    crew_id bigint,
    crew_pal_id bigint,
    CONSTRAINT delivery_attempt_count_nonnegative CHECK ((attempt_count >= 0)),
    CONSTRAINT delivery_cancelled_after_queue CHECK (((cancelled_at IS NULL) OR (cancelled_at >= queued_at))),
    CONSTRAINT delivery_crew_recipient_pair CHECK ((((crew_id IS NULL) AND (crew_pal_id IS NULL)) OR ((crew_id IS NOT NULL) AND (crew_pal_id IS NOT NULL)))),
    CONSTRAINT delivery_delivered_after_queue CHECK (((delivered_at IS NULL) OR (delivered_at >= queued_at))),
    CONSTRAINT delivery_expiry_after_queue CHECK (((expires_at IS NULL) OR (expires_at >= queued_at))),
    CONSTRAINT delivery_mls_recipient_excludes_generic_pal CHECK (((crew_pal_id IS NULL) OR ((crew_id IS NOT NULL) AND (pal_id IS NULL)))),
    CONSTRAINT delivery_status_valid CHECK ((status = ANY (ARRAY['QUEUED'::text, 'DELIVERING'::text, 'DELIVERED'::text, 'EXPIRED'::text, 'CANCELLED'::text])))
);


--
-- TOC entry 5908 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN delivery.crew_pal_id; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON COLUMN messaging.delivery.crew_pal_id IS 'MLS recipient membership-period identity. NULL for legacy/generic deliveries.';


--
-- TOC entry 348 (class 1259 OID 33099)
-- Name: delivery_delivery_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

CREATE SEQUENCE messaging.delivery_delivery_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5909 (class 0 OID 0)
-- Dependencies: 348
-- Name: delivery_delivery_id_seq; Type: SEQUENCE OWNED BY; Schema: messaging; Owner: -
--

ALTER SEQUENCE messaging.delivery_delivery_id_seq OWNED BY messaging.delivery.delivery_id;


--
-- TOC entry 349 (class 1259 OID 33100)
-- Name: message; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.message (
    message_id bigint NOT NULL,
    event_id bigint NOT NULL,
    message_type smallint NOT NULL,
    payload bytea NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    crew_id bigint,
    sender_crew_pal_id bigint,
    crew_sequence bigint,
    protocol_type text,
    operation_id uuid,
    payload_digest bytea,
    group_revision bigint,
    CONSTRAINT message_cancelled_after_creation CHECK (((cancelled_at IS NULL) OR (cancelled_at >= created_at))),
    CONSTRAINT message_crew_sequence_positive CHECK (((crew_sequence IS NULL) OR (crew_sequence >= 1))),
    CONSTRAINT message_expiry_after_creation CHECK (((expires_at IS NULL) OR (expires_at > created_at))),
    CONSTRAINT message_group_revision_nonnegative CHECK (((group_revision IS NULL) OR (group_revision >= 0))),
    CONSTRAINT message_mls_metadata_shape CHECK ((((protocol_type IS NULL) AND (crew_id IS NULL) AND (sender_crew_pal_id IS NULL) AND (crew_sequence IS NULL) AND (operation_id IS NULL) AND (payload_digest IS NULL) AND (group_revision IS NULL)) OR ((protocol_type IS NOT NULL) AND (crew_id IS NOT NULL) AND (sender_crew_pal_id IS NOT NULL) AND (crew_sequence IS NOT NULL) AND (operation_id IS NOT NULL) AND (payload_digest IS NOT NULL) AND (octet_length(payload_digest) = 32) AND (group_revision IS NOT NULL) AND (group_revision >= 0) AND ((protocol_type = 'APPLICATION'::text) OR ((protocol_type = ANY (ARRAY['COMMIT'::text, 'WELCOME'::text])) AND (group_revision >= 1) AND (expires_at IS NULL)))))),
    CONSTRAINT message_protocol_type_valid CHECK (((protocol_type IS NULL) OR (protocol_type = ANY (ARRAY['COMMIT'::text, 'WELCOME'::text, 'APPLICATION'::text]))))
);


--
-- TOC entry 5910 (class 0 OID 0)
-- Dependencies: 349
-- Name: COLUMN message.payload_digest; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON COLUMN messaging.message.payload_digest IS 'SHA-256 digest of the exact protocol payload bytes; 32 bytes. Used with operation_id for retry integrity.';


--
-- TOC entry 5911 (class 0 OID 0)
-- Dependencies: 349
-- Name: COLUMN message.group_revision; Type: COMMENT; Schema: messaging; Owner: -
--

COMMENT ON COLUMN messaging.message.group_revision IS 'For COMMIT: resulting group revision. For WELCOME: revision of the group state into which the joining member is introduced; both records from one operation carry the same revision. For APPLICATION: current group revision at message creation; it does not advance the revision.';


--
-- TOC entry 350 (class 1259 OID 33113)
-- Name: message_message_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

CREATE SEQUENCE messaging.message_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5912 (class 0 OID 0)
-- Dependencies: 350
-- Name: message_message_id_seq; Type: SEQUENCE OWNED BY; Schema: messaging; Owner: -
--

ALTER SEQUENCE messaging.message_message_id_seq OWNED BY messaging.message.message_id;


--
-- TOC entry 4951 (class 2604 OID 33114)
-- Name: assistance_request assistance_request_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.assistance_request ALTER COLUMN assistance_request_id SET DEFAULT nextval('activity.assistance_request_assistance_request_id_seq'::regclass);


--
-- TOC entry 4956 (class 2604 OID 33115)
-- Name: navigation_event navigation_event_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_event ALTER COLUMN navigation_event_id SET DEFAULT nextval('activity.navigation_event_navigation_event_id_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 33116)
-- Name: navigation_segment navigation_segment_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment ALTER COLUMN navigation_segment_id SET DEFAULT nextval('activity.navigation_segment_navigation_segment_id_seq'::regclass);


--
-- TOC entry 4961 (class 2604 OID 33117)
-- Name: navigation_session navigation_session_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_session ALTER COLUMN navigation_session_id SET DEFAULT nextval('activity.navigation_session_navigation_session_id_seq'::regclass);


--
-- TOC entry 4966 (class 2604 OID 33118)
-- Name: pal_pinger_session pal_pinger_session_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.pal_pinger_session ALTER COLUMN pal_pinger_session_id SET DEFAULT nextval('activity.pal_pinger_session_pal_pinger_session_id_seq'::regclass);


--
-- TOC entry 4971 (class 2604 OID 33119)
-- Name: authority authority_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority ALTER COLUMN authority_id SET DEFAULT nextval('audit.authority_authority_id_seq'::regclass);


--
-- TOC entry 4973 (class 2604 OID 33120)
-- Name: event audit_event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.event ALTER COLUMN audit_event_id SET DEFAULT nextval('audit.event_audit_event_id_seq'::regclass);


--
-- TOC entry 4975 (class 2604 OID 33121)
-- Name: operator operator_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator ALTER COLUMN operator_id SET DEFAULT nextval('audit.operator_operator_id_seq'::regclass);


--
-- TOC entry 4978 (class 2604 OID 33122)
-- Name: communication communication_id; Type: DEFAULT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication ALTER COLUMN communication_id SET DEFAULT nextval('communications.communication_communication_id_seq'::regclass);


--
-- TOC entry 4981 (class 2604 OID 33123)
-- Name: subscription subscription_id; Type: DEFAULT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription ALTER COLUMN subscription_id SET DEFAULT nextval('communications.subscription_subscription_id_seq'::regclass);


--
-- TOC entry 4983 (class 2604 OID 33124)
-- Name: crew crew_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew ALTER COLUMN crew_id SET DEFAULT nextval('community.crew_crew_id_seq'::regclass);


--
-- TOC entry 4986 (class 2604 OID 33125)
-- Name: crew_message crew_message_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message ALTER COLUMN crew_message_id SET DEFAULT nextval('community.crew_message_crew_message_id_seq'::regclass);


--
-- TOC entry 4989 (class 2604 OID 33126)
-- Name: crew_pal crew_pal_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal ALTER COLUMN crew_pal_id SET DEFAULT nextval('community.crew_pal_crew_pal_id_seq'::regclass);


--
-- TOC entry 4994 (class 2604 OID 33127)
-- Name: allergen allergen_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen ALTER COLUMN allergen_id SET DEFAULT nextval('design.allergen_allergen_id_seq'::regclass);


--
-- TOC entry 4997 (class 2604 OID 33128)
-- Name: dietary_attribute dietary_attribute_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute ALTER COLUMN dietary_attribute_id SET DEFAULT nextval('design.dietary_attribute_dietary_attribute_id_seq'::regclass);


--
-- TOC entry 5000 (class 2604 OID 33129)
-- Name: elevator elevator_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.elevator ALTER COLUMN elevator_id SET DEFAULT nextval('design.elevator_elevator_id_seq'::regclass);


--
-- TOC entry 5003 (class 2604 OID 33130)
-- Name: escalator escalator_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.escalator ALTER COLUMN escalator_id SET DEFAULT nextval('design.escalator_escalator_id_seq'::regclass);


--
-- TOC entry 5006 (class 2604 OID 33131)
-- Name: event event_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event ALTER COLUMN event_id SET DEFAULT nextval('design.event_event_id_seq'::regclass);


--
-- TOC entry 5011 (class 2604 OID 33132)
-- Name: event_beacon event_beacon_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon ALTER COLUMN event_beacon_id SET DEFAULT nextval('design.event_beacon_event_beacon_id_seq'::regclass);


--
-- TOC entry 5014 (class 2604 OID 33133)
-- Name: event_beacon_physical event_beacon_physical_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical ALTER COLUMN event_beacon_physical_id SET DEFAULT nextval('design.event_beacon_physical_event_beacon_physical_id_seq'::regclass);


--
-- TOC entry 5016 (class 2604 OID 33134)
-- Name: event_day event_day_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day ALTER COLUMN event_day_id SET DEFAULT nextval('design.event_day_event_day_id_seq'::regclass);


--
-- TOC entry 5019 (class 2604 OID 33135)
-- Name: flight flight_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight ALTER COLUMN flight_id SET DEFAULT nextval('design.flight_flight_id_seq'::regclass);


--
-- TOC entry 5022 (class 2604 OID 33136)
-- Name: item_sequence item_sequence_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence ALTER COLUMN item_sequence_id SET DEFAULT nextval('design.item_sequence_item_sequence_id_seq'::regclass);


--
-- TOC entry 5025 (class 2604 OID 33137)
-- Name: junction junction_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction ALTER COLUMN junction_id SET DEFAULT nextval('design.junction_junction_id_seq'::regclass);


--
-- TOC entry 5028 (class 2604 OID 33138)
-- Name: offering offering_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering ALTER COLUMN offering_id SET DEFAULT nextval('design.offering_offering_id_seq'::regclass);


--
-- TOC entry 5031 (class 2604 OID 33139)
-- Name: offering_availability offering_availability_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_availability ALTER COLUMN offering_availability_id SET DEFAULT nextval('design.offering_availability_offering_availability_id_seq'::regclass);


--
-- TOC entry 5034 (class 2604 OID 33140)
-- Name: offering_item offering_item_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item ALTER COLUMN offering_item_id SET DEFAULT nextval('design.offering_item_offering_item_id_seq'::regclass);


--
-- TOC entry 5039 (class 2604 OID 33141)
-- Name: offering_type offering_type_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type ALTER COLUMN offering_type_id SET DEFAULT nextval('design.offering_type_offering_type_id_seq'::regclass);


--
-- TOC entry 5042 (class 2604 OID 33142)
-- Name: path path_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path ALTER COLUMN path_id SET DEFAULT nextval('design.path_path_id_seq'::regclass);


--
-- TOC entry 5045 (class 2604 OID 33143)
-- Name: path_connector path_connector_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_connector ALTER COLUMN path_connector_id SET DEFAULT nextval('design.path_connector_path_connector_id_seq'::regclass);


--
-- TOC entry 5048 (class 2604 OID 33144)
-- Name: path_endpoint path_endpoint_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint ALTER COLUMN path_endpoint_id SET DEFAULT nextval('design.path_endpoint_path_endpoint_id_seq'::regclass);


--
-- TOC entry 5049 (class 2604 OID 33145)
-- Name: path_segment path_segment_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment ALTER COLUMN path_segment_id SET DEFAULT nextval('design.path_segment_path_segment_id_seq'::regclass);


--
-- TOC entry 5053 (class 2604 OID 33146)
-- Name: path_segment_congestion path_segment_congestion_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment_congestion ALTER COLUMN path_segment_congestion_id SET DEFAULT nextval('design.path_segment_congestion_path_segment_congestion_id_seq'::regclass);


--
-- TOC entry 5056 (class 2604 OID 33147)
-- Name: physical_beacon physical_beacon_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon ALTER COLUMN physical_beacon_id SET DEFAULT nextval('design.physical_beacon_physical_beacon_id_seq'::regclass);


--
-- TOC entry 5060 (class 2604 OID 33148)
-- Name: poi poi_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi ALTER COLUMN poi_id SET DEFAULT nextval('design.poi_poi_id_seq'::regclass);


--
-- TOC entry 5063 (class 2604 OID 33149)
-- Name: poi_capability poi_capability_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability ALTER COLUMN poi_capability_id SET DEFAULT nextval('design.poi_capability_poi_capability_id_seq'::regclass);


--
-- TOC entry 5066 (class 2604 OID 33150)
-- Name: poi_item poi_item_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_item ALTER COLUMN poi_item_id SET DEFAULT nextval('design.poi_item_poi_item_id_seq'::regclass);


--
-- TOC entry 5070 (class 2604 OID 33151)
-- Name: poi_type poi_type_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type ALTER COLUMN poi_type_id SET DEFAULT nextval('design.poi_type_poi_type_id_seq'::regclass);


--
-- TOC entry 5074 (class 2604 OID 33152)
-- Name: queue queue_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue ALTER COLUMN queue_id SET DEFAULT nextval('design.queue_queue_id_seq'::regclass);


--
-- TOC entry 5077 (class 2604 OID 33153)
-- Name: queue_source queue_source_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source ALTER COLUMN queue_source_id SET DEFAULT nextval('design.queue_source_queue_source_id_seq'::regclass);


--
-- TOC entry 5080 (class 2604 OID 33154)
-- Name: queue_source_ble queue_source_ble_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble ALTER COLUMN queue_source_ble_id SET DEFAULT nextval('design.queue_source_ble_queue_source_ble_id_seq'::regclass);


--
-- TOC entry 5083 (class 2604 OID 33155)
-- Name: queue_source_type queue_source_type_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type ALTER COLUMN queue_source_type_id SET DEFAULT nextval('design.queue_source_type_queue_source_type_id_seq'::regclass);


--
-- TOC entry 5086 (class 2604 OID 33156)
-- Name: queue_wait_time queue_wait_time_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time ALTER COLUMN queue_wait_time_id SET DEFAULT nextval('design.queue_wait_time_queue_wait_time_id_seq'::regclass);


--
-- TOC entry 5089 (class 2604 OID 33157)
-- Name: ramp ramp_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.ramp ALTER COLUMN ramp_id SET DEFAULT nextval('design.ramp_ramp_id_seq'::regclass);


--
-- TOC entry 5092 (class 2604 OID 33158)
-- Name: staircase staircase_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.staircase ALTER COLUMN staircase_id SET DEFAULT nextval('design.staircase_staircase_id_seq'::regclass);


--
-- TOC entry 5095 (class 2604 OID 33159)
-- Name: terminus terminus_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.terminus ALTER COLUMN terminus_id SET DEFAULT nextval('design.terminus_terminus_id_seq'::regclass);


--
-- TOC entry 5099 (class 2604 OID 33160)
-- Name: traversal_destination traversal_destination_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_destination ALTER COLUMN traversal_destination_id SET DEFAULT nextval('design.traversal_destination_traversal_destination_id_seq'::regclass);


--
-- TOC entry 5102 (class 2604 OID 33161)
-- Name: traversal_path traversal_path_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path ALTER COLUMN traversal_path_id SET DEFAULT nextval('design.traversal_path_traversal_path_id_seq'::regclass);


--
-- TOC entry 5105 (class 2604 OID 33162)
-- Name: weather_forecast weather_forecast_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_forecast ALTER COLUMN weather_forecast_id SET DEFAULT nextval('design.weather_forecast_weather_forecast_id_seq'::regclass);


--
-- TOC entry 5107 (class 2604 OID 33163)
-- Name: weather_update weather_update_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_update ALTER COLUMN weather_update_id SET DEFAULT nextval('design.weather_update_weather_update_id_seq'::regclass);


--
-- TOC entry 5110 (class 2604 OID 33164)
-- Name: zone zone_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone ALTER COLUMN zone_id SET DEFAULT nextval('design.zone_zone_id_seq'::regclass);


--
-- TOC entry 5113 (class 2604 OID 33165)
-- Name: zone_connector zone_connector_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone_connector ALTER COLUMN zone_connector_id SET DEFAULT nextval('design.zone_connector_zone_connector_id_seq'::regclass);


--
-- TOC entry 5117 (class 2604 OID 33166)
-- Name: acknowledgement acknowledgement_id; Type: DEFAULT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement ALTER COLUMN acknowledgement_id SET DEFAULT nextval('messaging.acknowledgement_acknowledgement_id_seq'::regclass);


--
-- TOC entry 5119 (class 2604 OID 33167)
-- Name: delivery delivery_id; Type: DEFAULT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery ALTER COLUMN delivery_id SET DEFAULT nextval('messaging.delivery_delivery_id_seq'::regclass);


--
-- TOC entry 5123 (class 2604 OID 33168)
-- Name: message message_id; Type: DEFAULT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message ALTER COLUMN message_id SET DEFAULT nextval('messaging.message_message_id_seq'::regclass);


--
-- TOC entry 5707 (class 0 OID 32297)
-- Dependencies: 235
-- Data for Name: assistance_request; Type: TABLE DATA; Schema: activity; Owner: -
--

COPY activity.assistance_request (assistance_request_id, event_id, request_reference, requested_at, notified_pal_count, acknowledged_pal_count, created_at) FROM stdin;
\.


--
-- TOC entry 5709 (class 0 OID 32317)
-- Dependencies: 237
-- Data for Name: navigation_event; Type: TABLE DATA; Schema: activity; Owner: -
--

COPY activity.navigation_event (navigation_event_id, navigation_session_id, event_type, occurred_at, details, created_at) FROM stdin;
\.


--
-- TOC entry 5711 (class 0 OID 32330)
-- Dependencies: 239
-- Data for Name: navigation_segment; Type: TABLE DATA; Schema: activity; Owner: -
--

COPY activity.navigation_segment (navigation_segment_id, navigation_session_id, path_segment_id, sequence_no, entered_at, exited_at, distance_metres, duration_seconds, created_at) FROM stdin;
\.


--
-- TOC entry 5713 (class 0 OID 32344)
-- Dependencies: 241
-- Data for Name: navigation_session; Type: TABLE DATA; Schema: activity; Owner: -
--

COPY activity.navigation_session (navigation_session_id, event_id, session_reference, started_at, completed_at, start_location, destination, planned_distance_metres, actual_distance_metres, duration_seconds, status, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5715 (class 0 OID 32365)
-- Dependencies: 243
-- Data for Name: pal_pinger_session; Type: TABLE DATA; Schema: activity; Owner: -
--

COPY activity.pal_pinger_session (pal_pinger_session_id, event_id, session_reference, started_at, completed_at, status, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5717 (class 0 OID 32383)
-- Dependencies: 245
-- Data for Name: authority; Type: TABLE DATA; Schema: audit; Owner: -
--

COPY audit.authority (authority_id, event_id, name, description, created_at) FROM stdin;
\.


--
-- TOC entry 5719 (class 0 OID 32394)
-- Dependencies: 247
-- Data for Name: event; Type: TABLE DATA; Schema: audit; Owner: -
--

COPY audit.event (audit_event_id, audit_type, actor_source, actor_reference, authority_reference, action, entity_type, entity_id, occurred_at, before_state, after_state, details) FROM stdin;
\.


--
-- TOC entry 5721 (class 0 OID 32409)
-- Dependencies: 249
-- Data for Name: operator; Type: TABLE DATA; Schema: audit; Owner: -
--

COPY audit.operator (operator_id, event_id, firebase_uid, display_name, created_at) FROM stdin;
\.


--
-- TOC entry 5722 (class 0 OID 32420)
-- Dependencies: 250
-- Data for Name: operator_authority; Type: TABLE DATA; Schema: audit; Owner: -
--

COPY audit.operator_authority (operator_id, authority_id, assigned_at) FROM stdin;
\.


--
-- TOC entry 5724 (class 0 OID 32428)
-- Dependencies: 252
-- Data for Name: communication; Type: TABLE DATA; Schema: communications; Owner: -
--

COPY communications.communication (communication_id, event_id, communication_type, title, message, poi_id, poi_item_id, created_at, expires_at, item_sequence_id) FROM stdin;
\.


--
-- TOC entry 5726 (class 0 OID 32444)
-- Dependencies: 254
-- Data for Name: subscription; Type: TABLE DATA; Schema: communications; Owner: -
--

COPY communications.subscription (subscription_id, pal_id, poi_id, poi_item_id, subscribed_at, item_sequence_id) FROM stdin;
\.


--
-- TOC entry 5728 (class 0 OID 32453)
-- Dependencies: 256
-- Data for Name: crew; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew (crew_id, name, description, created_at, updated_at, event_id) FROM stdin;
9	Red Team	\N	2026-10-13 10:55:41.699047+01	2026-10-13 10:55:41.699047+01	1
10	Blue Team	\N	2026-10-13 11:03:03.457645+01	2026-10-13 11:03:03.457645+01	1
11	Green Team	\N	2026-10-13 11:39:21.619632+01	2026-10-13 11:39:21.619632+01	1
12	Orange Team	\N	2026-10-13 11:59:43.867013+01	2026-10-13 11:59:43.867013+01	1
13	Purple Team	\N	2026-10-13 12:56:26.93529+01	2026-10-13 12:56:26.93529+01	1
14	Indigo Boys	\N	2026-10-14 09:45:04.500483+01	2026-10-14 09:45:04.500483+01	1
15	Azure Team	\N	2026-10-14 09:51:11.54699+01	2026-10-14 09:51:11.54699+01	1
16	The Krays	\N	2026-10-14 10:10:09.462792+01	2026-10-14 10:10:09.462792+01	1
17	The Versaces	\N	2026-10-14 10:19:14.743325+01	2026-10-14 10:19:14.743325+01	1
18	Oratory	\N	2026-10-14 11:13:11.658643+01	2026-10-14 11:13:11.658643+01	1
19	The Corleones	\N	2026-10-14 11:29:24.269883+01	2026-10-14 11:29:24.269883+01	1
20	The Einsteins	\N	2026-10-15 09:26:48.113699+01	2026-10-15 09:26:48.113699+01	1
21	The Houdinis	\N	2026-10-15 10:18:05.674677+01	2026-10-15 10:18:05.674677+01	1
22	The Magicians	\N	2026-10-16 08:13:28.726582+01	2026-10-16 08:13:28.726582+01	1
23	The 3 Stooges	\N	2026-10-19 09:36:33.399584+01	2026-10-19 09:36:33.399584+01	1
24	Star Wars	\N	2026-10-30 12:23:11.454315+00	2026-10-30 12:23:11.454315+00	1
25	Fighter	\N	2026-10-30 12:36:02.843996+00	2026-10-30 12:36:02.843996+00	1
\.


--
-- TOC entry 5824 (class 0 OID 36400)
-- Dependencies: 352
-- Data for Name: crew_invitation; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew_invitation (crew_id, token_hash, created_at, updated_at) FROM stdin;
10	ef276947b4fa00225890243e97820eed2410f5208d868d335e35ad2ff90ef84b	2026-10-13 11:03:03.457645+01	2026-10-13 11:07:24.523796+01
11	0aa068bbbc3aba86e85d7c6684da0a65c1d0824facd160d5b9552ee3a8d23b56	2026-10-13 11:39:21.619632+01	2026-10-13 11:39:21.619632+01
12	389f01c46ab35068a8b9eed2d6aba459a89163e60e82c8263230d4119f9e0190	2026-10-13 11:59:43.867013+01	2026-10-13 11:59:43.867013+01
13	6cd98231003d76b5b71181a9c2db600c3614d1edc5124f101817bc34d648b2d8	2026-10-13 12:56:26.93529+01	2026-10-13 12:56:26.93529+01
14	10f48ef5f027282768c96a4d4b0316f40b0bcaf617e55e03895d7030d82c16fb	2026-10-14 09:45:04.500483+01	2026-10-14 09:45:04.500483+01
15	20a2b0aefd91aa30bb78c7a4da0fc5809481aaf3489f0be867e29b317378c6e6	2026-10-14 09:51:11.54699+01	2026-10-14 09:51:11.54699+01
16	9f8d1c9183f903e8a2167d70e3b637026491b33426b1d02377ee92d5743b909f	2026-10-14 10:10:09.462792+01	2026-10-14 10:10:09.462792+01
17	192d20398b3a3a55b94a39a37b6671af3d6d0ad28c10fcf922bcd347e4556588	2026-10-14 10:19:14.743325+01	2026-10-14 10:19:14.743325+01
18	69894412caf85b91906704e8a3577bc024c2d98baec7e36413a83c8f47bc55ef	2026-10-14 11:13:11.658643+01	2026-10-14 11:13:11.658643+01
19	c6156982f70b92269c228f5420eb0b52df4d80879be6266410a0b00b655a1dc3	2026-10-14 11:29:24.269883+01	2026-10-14 11:29:24.269883+01
20	ece847656ec0ffa646d7fef3f1972dd3d84f6189cad9c16dbf601d0a179d5362	2026-10-15 09:26:48.113699+01	2026-10-15 09:26:48.113699+01
21	e5210864f48eb33eab68cd9981bea41f6bddf5e6ee6555cfbf492d1841bcf80e	2026-10-15 10:18:05.674677+01	2026-10-15 10:18:05.674677+01
22	f85086748645077e3878ee85c2a3ed97f70248cd803a08b57f3d68b31840ed8f	2026-10-16 08:13:28.726582+01	2026-10-16 08:13:28.726582+01
23	ebc3c3322646d8d1d97237f6b714ecdb7abc5b1659f31e2720bbbf29297a2b1a	2026-10-19 09:36:33.399584+01	2026-10-19 09:36:33.399584+01
24	8e09db3c82b2fd9522d40498693dc199ca582e5a507d4d9df48c8d99294d55d5	2026-10-30 12:23:11.454315+00	2026-10-30 12:23:11.454315+00
25	e890bd9c379b93cfd1d63f8f9e4ff5479fb78cfb99ed200dec35e85cc3493ef5	2026-10-30 12:36:02.843996+00	2026-10-30 12:36:02.843996+00
\.


--
-- TOC entry 5828 (class 0 OID 41873)
-- Dependencies: 356
-- Data for Name: crew_meetup; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew_meetup (crew_meetup_id, event_id, crew_id, poi_id, organiser_pal_id, mode, scheduled_at, status, created_at, updated_at, expires_at, ended_at) FROM stdin;
\.


--
-- TOC entry 5830 (class 0 OID 41915)
-- Dependencies: 358
-- Data for Name: crew_meetup_response; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew_meetup_response (crew_meetup_response_id, crew_meetup_id, pal_id, response, responded_at) FROM stdin;
\.


--
-- TOC entry 5730 (class 0 OID 32466)
-- Dependencies: 258
-- Data for Name: crew_message; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew_message (crew_message_id, crew_id, pal_id, message, created_at, message_type, ciphertext, actor_kind, actor_pal_id, affected_pal_id, idempotency_key, crew_pal_id) FROM stdin;
1	23	91aa24bd-0718-4e2c-b937-0e51577da6e2	\N	2026-10-26 13:00:40.810681+00	USER	\\x6447567a644331745a584e7a5957646c4c54453d	\N	\N	\N	c4a38a6e-6f3b-4d8e-9a21-5d0d7e3a4101	49
\.


--
-- TOC entry 5732 (class 0 OID 32478)
-- Dependencies: 260
-- Data for Name: crew_pal; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew_pal (crew_pal_id, crew_id, pal_id, joined_at, left_at, created_at, display_name, membership_status) FROM stdin;
11	9	9c463aec-fa6e-4462-ba1a-9338dadf93b9	2026-10-13 10:55:41.699047+01	\N	2026-10-13 10:55:41.699047+01	Patrick G	ACTIVE
12	10	ee366cc8-fd77-4313-b344-7c4135c1ae8e	2026-10-13 11:03:03.457645+01	\N	2026-10-13 11:03:03.457645+01	G Mac	ACTIVE
13	10	0998b63e-1530-4687-ae29-355b87eacb78	2026-10-13 11:06:31.842161+01	\N	2026-10-13 11:06:31.842161+01	Patsy	ACTIVE
14	11	50f97ba4-057b-4590-bb0c-02f6ef36ddb7	2026-10-13 11:39:21.619632+01	\N	2026-10-13 11:39:21.619632+01	Randolf	ACTIVE
15	10	2730e305-cba8-4e0d-b7e7-1700285af257	2026-10-13 11:54:50.060376+01	\N	2026-10-13 11:54:50.060376+01	Barry	ACTIVE
16	12	9b2d3173-2066-48a7-af11-1c0465e4443b	2026-10-13 11:59:43.867013+01	\N	2026-10-13 11:59:43.867013+01	Spinning	ACTIVE
17	12	356443e2-99ef-42e9-b31a-ddbcc497e9a3	2026-10-13 12:00:28.842847+01	\N	2026-10-13 12:00:28.842847+01	Jenny	ACTIVE
18	13	79f633b6-dfa0-450b-be31-6c3ee8522744	2026-10-13 12:56:26.93529+01	\N	2026-10-13 12:56:26.93529+01	Roger	ACTIVE
19	13	d69c31a0-c833-40dc-b611-06daf1111e75	2026-10-13 12:57:51.546278+01	\N	2026-10-13 12:57:51.546278+01	Daltry	ACTIVE
20	14	1cf8eec5-9ab1-4da4-a8f8-f1108b3b8451	2026-10-14 09:45:04.500483+01	\N	2026-10-14 09:45:04.500483+01	Johnny	ACTIVE
21	14	497e0a0d-75bf-4976-87bc-6960bd01f973	2026-10-14 09:46:40.846627+01	\N	2026-10-14 09:46:40.846627+01	Lily	ACTIVE
22	15	1eeaf6a1-32cd-4f1d-a9a4-d25d3def1af1	2026-10-14 09:51:11.54699+01	\N	2026-10-14 09:51:11.54699+01	Bobby	ACTIVE
23	15	41537ec2-92dd-4a02-8220-b05b509e075a	2026-10-14 09:52:02.496231+01	2026-10-14 09:59:39.234201+01	2026-10-14 09:52:02.496231+01	Dazzler	ACTIVE
24	16	29216a1b-c556-4e68-a0d0-14e8d601bbe8	2026-10-14 10:10:09.462792+01	\N	2026-10-14 10:10:09.462792+01	Ruby	ACTIVE
25	16	f56f1b3b-06d4-4a48-93ab-fcd69202a658	2026-10-14 10:11:28.992051+01	\N	2026-10-14 10:11:28.992051+01	Reggie	ACTIVE
27	17	753c3f32-e38a-48a7-b62b-44c2ce55cce0	2026-10-14 10:20:06.192614+01	2026-10-14 10:27:27.720341+01	2026-10-14 10:20:06.192614+01	Donatella	ACTIVE
28	17	753c3f32-e38a-48a7-b62b-44c2ce55cce0	2026-10-14 10:29:04.976543+01	2026-10-14 10:29:24.124476+01	2026-10-14 10:29:04.976543+01	Donatella	ACTIVE
29	17	753c3f32-e38a-48a7-b62b-44c2ce55cce0	2026-10-14 10:29:41.72859+01	2026-10-14 11:03:37.449381+01	2026-10-14 10:29:41.72859+01	Donatella	ACTIVE
26	17	d3db9508-799d-464b-a831-421a5d3e16ce	2026-10-14 10:19:14.743325+01	2026-10-14 11:03:55.008835+01	2026-10-14 10:19:14.743325+01	Gianni	ACTIVE
30	18	d3db9508-799d-464b-a831-421a5d3e16ce	2026-10-14 11:13:11.658643+01	\N	2026-10-14 11:13:11.658643+01	Gianni	ACTIVE
31	18	753c3f32-e38a-48a7-b62b-44c2ce55cce0	2026-10-14 11:13:33.315512+01	2026-10-14 11:14:02.729688+01	2026-10-14 11:13:33.315512+01	Donatella	ACTIVE
33	19	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-14 11:30:10.183662+01	2026-10-14 11:30:26.353983+01	2026-10-14 11:30:10.183662+01	Fido	ACTIVE
34	19	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-14 11:34:46.799899+01	2026-10-14 11:36:08.72067+01	2026-10-14 11:34:46.799899+01	Fido	ACTIVE
35	19	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-14 12:02:25.96723+01	2026-10-14 12:02:42.764767+01	2026-10-14 12:02:25.96723+01	Fido	ACTIVE
36	19	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-14 12:10:18.471593+01	2026-10-14 12:10:34.032923+01	2026-10-14 12:10:18.471593+01	Fido	ACTIVE
37	19	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-14 12:12:16.532788+01	2026-10-14 12:12:33.726855+01	2026-10-14 12:12:16.532788+01	Fido	ACTIVE
32	19	2a2b30fa-caef-4126-bff3-4e11d626b9bd	2026-10-14 11:29:24.269883+01	2026-10-14 12:20:41.84995+01	2026-10-14 11:29:24.269883+01	Don	ACTIVE
39	19	2a2b30fa-caef-4126-bff3-4e11d626b9bd	2026-10-14 12:21:39.725521+01	\N	2026-10-14 12:21:39.725521+01	Don	ACTIVE
40	20	da57296e-3a86-447d-8495-3a450c2e96ee	2026-10-15 09:26:48.113699+01	\N	2026-10-15 09:26:48.113699+01	Albert	ACTIVE
38	19	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-14 12:12:45.050489+01	2026-10-15 09:27:09.192418+01	2026-10-14 12:12:45.050489+01	Fido	ACTIVE
42	21	ca0e2970-9b1d-49b1-8c46-c834587374fc	2026-10-15 10:18:05.674677+01	\N	2026-10-15 10:18:05.674677+01	Harry	ACTIVE
41	20	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-15 09:27:16.849815+01	2026-10-15 12:43:33.606763+01	2026-10-15 09:27:16.849815+01	Fido	ACTIVE
44	21	0cb4dee7-f0b9-480b-a250-604ca0a74ba4	2026-10-16 07:49:26.68124+01	\N	2026-10-16 07:49:26.68124+01	Rene	ACTIVE
43	21	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-15 12:43:52.97551+01	2026-10-16 08:13:17.804393+01	2026-10-15 12:43:52.97551+01	Fido	ACTIVE
45	22	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-16 08:13:28.726582+01	2026-10-16 10:59:34.979546+01	2026-10-16 08:13:28.726582+01	Fido	ACTIVE
47	21	29a827a4-1830-4f80-8c35-47d4529384df	2026-10-19 09:24:20.561246+01	\N	2026-10-19 09:24:20.561246+01	Fido 2	ACTIVE
46	21	43d8daa2-60e6-4b41-818e-d58a5aa5a453	2026-10-16 10:59:41.784308+01	2026-10-19 09:24:58.796685+01	2026-10-16 10:59:41.784308+01	Fido	ACTIVE
50	23	b2a6281e-8108-4c9b-ae00-65f8d20bce9a	2026-10-19 09:37:22.37163+01	2026-10-19 12:23:33.426669+01	2026-10-19 09:37:22.37163+01	Moe	ACTIVE
49	23	91aa24bd-0718-4e2c-b937-0e51577da6e2	2026-10-19 09:36:55.886676+01	2026-10-30 11:51:46.677004+00	2026-10-19 09:36:55.886676+01	Curly	ACTIVE
48	23	bea5e544-7673-4713-8ff3-6a9bd93b4820	2026-10-19 09:36:33.399584+01	2026-10-30 12:07:23.503824+00	2026-10-19 09:36:33.399584+01	Larry	ACTIVE
51	23	b2a6281e-8108-4c9b-ae00-65f8d20bce9a	2026-10-19 12:24:50.834939+01	2026-10-30 12:09:01.698986+00	2026-10-19 12:24:50.834939+01	Moe	ACTIVE
53	24	91aa24bd-0718-4e2c-b937-0e51577da6e2	2026-10-30 12:25:01.181638+00	\N	2026-10-30 12:25:01.181638+00	Curly	ACTIVE
52	24	bea5e544-7673-4713-8ff3-6a9bd93b4820	2026-10-30 12:23:11.454315+00	2026-10-30 12:34:56.372573+00	2026-10-30 12:23:11.454315+00	Larry	ACTIVE
54	25	bea5e544-7673-4713-8ff3-6a9bd93b4820	2026-10-30 12:36:02.843996+00	\N	2026-10-30 12:36:02.843996+00	Larry	ACTIVE
\.


--
-- TOC entry 5826 (class 0 OID 41842)
-- Dependencies: 354
-- Data for Name: crew_pick; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.crew_pick (crew_pick_id, event_id, crew_id, poi_id, created_by_pal_id, created_at) FROM stdin;
\.


--
-- TOC entry 5823 (class 0 OID 33754)
-- Dependencies: 351
-- Data for Name: event_session; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.event_session (event_session_id, pal_id, event_id, started_at, ended_at, status, created_at, updated_at) FROM stdin;
5c41a0b8-2e81-45c9-957b-5e3a2bdcc6eb	11111111-1111-1111-1111-111111111111	1	2026-10-09 10:22:43.571922+01	2026-10-09 10:40:13.865123+01	ENDED	2026-10-09 10:22:43.571922+01	2026-10-09 10:40:13.865123+01
e76576bc-644b-4c81-b81c-6039f135caaf	0998b63e-1530-4687-ae29-355b87eacb78	1	2026-10-12 12:05:08.945742+01	\N	ACTIVE	2026-10-12 12:05:08.945742+01	2026-10-12 12:05:08.945742+01
0c220d1a-b19a-4151-b492-5db48277d71e	a2918d33-095f-448a-b4cd-1d243871d662	1	2026-10-12 12:09:49.0762+01	\N	ACTIVE	2026-10-12 12:09:49.0762+01	2026-10-12 12:09:49.0762+01
bb963e50-1943-4905-867f-aba2d874e66b	6d1b9e8a-8e80-4c04-a6b3-01b064765547	1	2026-10-12 12:43:24.195674+01	\N	ACTIVE	2026-10-12 12:43:24.195674+01	2026-10-12 12:43:24.195674+01
f1cdc187-819b-40bb-80f9-739e6c3f8520	11111111-1111-1111-1111-111111111111	1	2026-10-13 09:31:10.832717+01	\N	ACTIVE	2026-10-13 09:31:10.832717+01	2026-10-13 09:31:10.832717+01
25c209fb-4730-4301-9902-9ed41b3d9bde	9c463aec-fa6e-4462-ba1a-9338dadf93b9	1	2026-10-13 10:55:19.417825+01	\N	ACTIVE	2026-10-13 10:55:19.417825+01	2026-10-13 10:55:19.417825+01
d2c635bb-3544-41a5-aeb7-028b5cedffd7	ee366cc8-fd77-4313-b344-7c4135c1ae8e	1	2026-10-13 11:02:44.739954+01	\N	ACTIVE	2026-10-13 11:02:44.739954+01	2026-10-13 11:02:44.739954+01
487f35f7-b3c8-4b99-88e5-0c19165c7375	50f97ba4-057b-4590-bb0c-02f6ef36ddb7	1	2026-10-13 11:39:11.755874+01	\N	ACTIVE	2026-10-13 11:39:11.755874+01	2026-10-13 11:39:11.755874+01
8f8546e5-152f-44a4-9c3b-f36ff52f39a2	2730e305-cba8-4e0d-b7e7-1700285af257	1	2026-10-13 11:54:00.465638+01	\N	ACTIVE	2026-10-13 11:54:00.465638+01	2026-10-13 11:54:00.465638+01
f42ab360-cebb-480c-84b4-fd7632f0f933	9b2d3173-2066-48a7-af11-1c0465e4443b	1	2026-10-13 11:59:29.191158+01	\N	ACTIVE	2026-10-13 11:59:29.191158+01	2026-10-13 11:59:29.191158+01
fe58ab19-42cd-406a-ba21-bec1904ca866	356443e2-99ef-42e9-b31a-ddbcc497e9a3	1	2026-10-13 11:59:58.269008+01	\N	ACTIVE	2026-10-13 11:59:58.269008+01	2026-10-13 11:59:58.269008+01
eb68476d-4511-4804-9092-514f223d4c88	79f633b6-dfa0-450b-be31-6c3ee8522744	1	2026-10-13 12:56:16.259486+01	\N	ACTIVE	2026-10-13 12:56:16.259486+01	2026-10-13 12:56:16.259486+01
af9f15ef-9f91-493e-bac7-293f424e10a4	d69c31a0-c833-40dc-b611-06daf1111e75	1	2026-10-13 12:57:08.048865+01	\N	ACTIVE	2026-10-13 12:57:08.048865+01	2026-10-13 12:57:08.048865+01
329b0c5c-05ed-47dc-93d4-3a99d40154e5	1cf8eec5-9ab1-4da4-a8f8-f1108b3b8451	1	2026-10-14 09:44:50.863101+01	\N	ACTIVE	2026-10-14 09:44:50.863101+01	2026-10-14 09:44:50.863101+01
72add3bc-0619-43c4-8682-4537ee5f8a7f	497e0a0d-75bf-4976-87bc-6960bd01f973	1	2026-10-14 09:46:14.613403+01	\N	ACTIVE	2026-10-14 09:46:14.613403+01	2026-10-14 09:46:14.613403+01
3cf75418-0111-45ee-aba4-d329beafdc56	1eeaf6a1-32cd-4f1d-a9a4-d25d3def1af1	1	2026-10-14 09:50:50.955722+01	\N	ACTIVE	2026-10-14 09:50:50.955722+01	2026-10-14 09:50:50.955722+01
7eb41985-611f-4f16-ac87-a75f88711540	41537ec2-92dd-4a02-8220-b05b509e075a	1	2026-10-14 09:51:42.044948+01	\N	ACTIVE	2026-10-14 09:51:42.044948+01	2026-10-14 09:51:42.044948+01
003af8e9-942b-44ff-98e2-e4aa45389145	29216a1b-c556-4e68-a0d0-14e8d601bbe8	1	2026-10-14 10:09:54.480426+01	\N	ACTIVE	2026-10-14 10:09:54.480426+01	2026-10-14 10:09:54.480426+01
2732a8b1-687a-46c7-aa4e-62d0c942cb78	f56f1b3b-06d4-4a48-93ab-fcd69202a658	1	2026-10-14 10:11:14.297818+01	\N	ACTIVE	2026-10-14 10:11:14.297818+01	2026-10-14 10:11:14.297818+01
d09058b9-90d1-4f37-aa4d-e4216705d382	d3db9508-799d-464b-a831-421a5d3e16ce	1	2026-10-14 10:18:59.093822+01	\N	ACTIVE	2026-10-14 10:18:59.093822+01	2026-10-14 10:18:59.093822+01
276d66f0-1b55-41e9-8acb-c1d7ca2d2ac0	753c3f32-e38a-48a7-b62b-44c2ce55cce0	1	2026-10-14 10:19:48.159963+01	\N	ACTIVE	2026-10-14 10:19:48.159963+01	2026-10-14 10:19:48.159963+01
a5d95dd7-2698-4d2b-8023-8bf53c042639	2a2b30fa-caef-4126-bff3-4e11d626b9bd	1	2026-10-14 11:28:58.814645+01	\N	ACTIVE	2026-10-14 11:28:58.814645+01	2026-10-14 11:28:58.814645+01
dd186b41-b8ae-4574-9701-d77fd4d6f384	43d8daa2-60e6-4b41-818e-d58a5aa5a453	1	2026-10-14 11:29:59.53253+01	\N	ACTIVE	2026-10-14 11:29:59.53253+01	2026-10-14 11:29:59.53253+01
19d3b6ad-afa1-4833-b64a-69d15bdf4069	da57296e-3a86-447d-8495-3a450c2e96ee	1	2026-10-15 09:26:32.214158+01	\N	ACTIVE	2026-10-15 09:26:32.214158+01	2026-10-15 09:26:32.214158+01
2ed0f09d-15e2-4dd2-9615-be5a6eed7a68	ca0e2970-9b1d-49b1-8c46-c834587374fc	1	2026-10-15 10:17:47.021426+01	\N	ACTIVE	2026-10-15 10:17:47.021426+01	2026-10-15 10:17:47.021426+01
665dd59f-5f6c-45a1-a45c-a6873a159189	0cb4dee7-f0b9-480b-a250-604ca0a74ba4	1	2026-10-16 07:49:02.835806+01	\N	ACTIVE	2026-10-16 07:49:02.835806+01	2026-10-16 07:49:02.835806+01
16bb3b75-4424-4e21-b29a-d4c9423d2d93	29a827a4-1830-4f80-8c35-47d4529384df	1	2026-10-19 09:24:01.420725+01	\N	ACTIVE	2026-10-19 09:24:01.420725+01	2026-10-19 09:24:01.420725+01
45e14080-0903-40e8-9d76-3f917f66766a	bea5e544-7673-4713-8ff3-6a9bd93b4820	1	2026-10-19 09:36:16.410889+01	\N	ACTIVE	2026-10-19 09:36:16.410889+01	2026-10-19 09:36:16.410889+01
c799b846-188f-43da-8018-757fe650c593	91aa24bd-0718-4e2c-b937-0e51577da6e2	1	2026-10-19 09:36:46.096489+01	\N	ACTIVE	2026-10-19 09:36:46.096489+01	2026-10-19 09:36:46.096489+01
ff5d19ba-8557-469e-a63c-28becd05d33a	b2a6281e-8108-4c9b-ae00-65f8d20bce9a	1	2026-10-19 09:37:07.821836+01	\N	ACTIVE	2026-10-19 09:37:07.821836+01	2026-10-19 09:37:07.821836+01
\.


--
-- TOC entry 5734 (class 0 OID 32493)
-- Dependencies: 262
-- Data for Name: pal; Type: TABLE DATA; Schema: community; Owner: -
--

COPY community.pal (pal_id, name, created_at, updated_at) FROM stdin;
11111111-1111-1111-1111-111111111111	Patrick	2026-10-09 10:13:52.826068+01	2026-10-09 10:13:52.826068+01
0998b63e-1530-4687-ae29-355b87eacb78	Patsy	2026-10-12 12:05:08.921542+01	2026-10-12 12:05:08.921542+01
a2918d33-095f-448a-b4cd-1d243871d662	Rene	2026-10-12 12:09:49.057153+01	2026-10-12 12:37:18.897805+01
6d1b9e8a-8e80-4c04-a6b3-01b064765547	Jeremy C	2026-10-12 12:43:24.175704+01	2026-10-12 12:43:24.175704+01
9c463aec-fa6e-4462-ba1a-9338dadf93b9	Patrick G	2026-10-13 10:55:19.395107+01	2026-10-13 10:55:19.395107+01
ee366cc8-fd77-4313-b344-7c4135c1ae8e	G Mac	2026-10-13 11:02:44.705856+01	2026-10-13 11:02:44.705856+01
50f97ba4-057b-4590-bb0c-02f6ef36ddb7	Randolf	2026-10-13 11:39:11.734874+01	2026-10-13 11:39:11.734874+01
2730e305-cba8-4e0d-b7e7-1700285af257	Barry	2026-10-13 11:54:00.43956+01	2026-10-13 11:54:00.43956+01
9b2d3173-2066-48a7-af11-1c0465e4443b	Spinning	2026-10-13 11:59:29.166168+01	2026-10-13 11:59:29.166168+01
356443e2-99ef-42e9-b31a-ddbcc497e9a3	Jenny	2026-10-13 11:59:58.237076+01	2026-10-13 11:59:58.237076+01
79f633b6-dfa0-450b-be31-6c3ee8522744	Roger	2026-10-13 12:56:16.237128+01	2026-10-13 12:56:16.237128+01
d69c31a0-c833-40dc-b611-06daf1111e75	Daltry	2026-10-13 12:57:08.034423+01	2026-10-13 12:57:08.034423+01
1cf8eec5-9ab1-4da4-a8f8-f1108b3b8451	Johnny	2026-10-14 09:44:50.839444+01	2026-10-14 09:44:50.839444+01
497e0a0d-75bf-4976-87bc-6960bd01f973	Lily	2026-10-14 09:46:14.587884+01	2026-10-14 09:46:14.587884+01
1eeaf6a1-32cd-4f1d-a9a4-d25d3def1af1	Bobby	2026-10-14 09:50:50.931026+01	2026-10-14 09:50:50.931026+01
41537ec2-92dd-4a02-8220-b05b509e075a	Dazzler	2026-10-14 09:51:42.012437+01	2026-10-14 09:51:42.012437+01
29216a1b-c556-4e68-a0d0-14e8d601bbe8	Ruby	2026-10-14 10:09:54.458423+01	2026-10-14 10:09:54.458423+01
f56f1b3b-06d4-4a48-93ab-fcd69202a658	Reggie	2026-10-14 10:11:14.275501+01	2026-10-14 10:11:14.275501+01
d3db9508-799d-464b-a831-421a5d3e16ce	Gianni	2026-10-14 10:18:59.070257+01	2026-10-14 10:18:59.070257+01
753c3f32-e38a-48a7-b62b-44c2ce55cce0	Donatella	2026-10-14 10:19:48.133054+01	2026-10-14 10:19:48.133054+01
2a2b30fa-caef-4126-bff3-4e11d626b9bd	Don	2026-10-14 11:28:58.787662+01	2026-10-14 11:28:58.787662+01
43d8daa2-60e6-4b41-818e-d58a5aa5a453	Fido	2026-10-14 11:29:59.503371+01	2026-10-14 11:29:59.503371+01
da57296e-3a86-447d-8495-3a450c2e96ee	Albert	2026-10-15 09:26:32.189406+01	2026-10-15 09:26:32.189406+01
ca0e2970-9b1d-49b1-8c46-c834587374fc	Harry	2026-10-15 10:17:46.997741+01	2026-10-15 10:17:46.997741+01
0cb4dee7-f0b9-480b-a250-604ca0a74ba4	Rene	2026-10-16 07:49:02.686351+01	2026-10-16 07:49:02.686351+01
29a827a4-1830-4f80-8c35-47d4529384df	Fido 2	2026-10-19 09:24:01.38468+01	2026-10-19 09:24:01.38468+01
bea5e544-7673-4713-8ff3-6a9bd93b4820	Larry	2026-10-19 09:36:16.389986+01	2026-10-19 09:36:16.389986+01
91aa24bd-0718-4e2c-b937-0e51577da6e2	Curly	2026-10-19 09:36:46.065768+01	2026-10-19 09:36:46.065768+01
b2a6281e-8108-4c9b-ae00-65f8d20bce9a	Moe	2026-10-19 09:37:07.79178+01	2026-10-19 09:37:07.79178+01
\.


--
-- TOC entry 5735 (class 0 OID 32504)
-- Dependencies: 263
-- Data for Name: allergen; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.allergen (allergen_id, code, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5737 (class 0 OID 32517)
-- Dependencies: 265
-- Data for Name: dietary_attribute; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.dietary_attribute (dietary_attribute_id, code, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5739 (class 0 OID 32530)
-- Dependencies: 267
-- Data for Name: elevator; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.elevator (elevator_id, traversal_path_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5741 (class 0 OID 32543)
-- Dependencies: 269
-- Data for Name: escalator; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.escalator (escalator_id, traversal_path_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5743 (class 0 OID 32556)
-- Dependencies: 271
-- Data for Name: event; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.event (event_id, name, description, status, created_at, updated_at, start_at, end_at, remote_support_enabled, api_url, runtime_url, runtime_version) FROM stdin;
1	Ebrington Festival	Navder proof-of-concept event	OPEN	2026-10-09 10:00:07.711847+01	2026-10-09 10:00:07.711847+01	2026-10-01 00:00:00+01	2027-04-01 00:59:59+01	f	https://api.example.com	https://bankmore.co.uk/navder/public/ebfest/runtime.json	1.0.0
\.


--
-- TOC entry 5744 (class 0 OID 32574)
-- Dependencies: 272
-- Data for Name: event_beacon; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.event_beacon (event_beacon_id, event_id, poi_id, name, description, geometry, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5746 (class 0 OID 32588)
-- Dependencies: 274
-- Data for Name: event_beacon_physical; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.event_beacon_physical (event_beacon_physical_id, event_beacon_id, physical_beacon_id, role, assigned_at, description) FROM stdin;
\.


--
-- TOC entry 5748 (class 0 OID 32601)
-- Dependencies: 276
-- Data for Name: event_day; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.event_day (event_day_id, event_id, day_number, name, date, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5751 (class 0 OID 32617)
-- Dependencies: 279
-- Data for Name: flight; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.flight (flight_id, staircase_id, sequence_no, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5753 (class 0 OID 32632)
-- Dependencies: 281
-- Data for Name: item_sequence; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.item_sequence (item_sequence_id, event_day_id, poi_item_id, sequence_no, created_at, updated_at, scheduled_start_time, duration_minutes) FROM stdin;
\.


--
-- TOC entry 5755 (class 0 OID 32647)
-- Dependencies: 283
-- Data for Name: junction; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.junction (junction_id, event_id, name, geometry, description, created_at, updated_at, display_geometry, display_image_ref) FROM stdin;
\.


--
-- TOC entry 5757 (class 0 OID 32660)
-- Dependencies: 285
-- Data for Name: offering; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.offering (offering_id, poi_id, offering_type_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5758 (class 0 OID 32673)
-- Dependencies: 286
-- Data for Name: offering_availability; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.offering_availability (offering_availability_id, offering_id, starts_at, ends_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5760 (class 0 OID 32686)
-- Dependencies: 288
-- Data for Name: offering_item; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.offering_item (offering_item_id, offering_id, name, description, price, image_ref, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5761 (class 0 OID 32699)
-- Dependencies: 289
-- Data for Name: offering_item_allergen; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.offering_item_allergen (offering_item_id, allergen_id, created_at) FROM stdin;
\.


--
-- TOC entry 5762 (class 0 OID 32706)
-- Dependencies: 290
-- Data for Name: offering_item_dietary_attribute; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.offering_item_dietary_attribute (offering_item_id, dietary_attribute_id, created_at) FROM stdin;
\.


--
-- TOC entry 5765 (class 0 OID 32715)
-- Dependencies: 293
-- Data for Name: offering_type; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.offering_type (offering_type_id, code, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5767 (class 0 OID 32728)
-- Dependencies: 295
-- Data for Name: path; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.path (path_id, event_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5768 (class 0 OID 32739)
-- Dependencies: 296
-- Data for Name: path_connector; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.path_connector (path_connector_id, path_id, name, geometry, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5770 (class 0 OID 32752)
-- Dependencies: 298
-- Data for Name: path_endpoint; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.path_endpoint (path_endpoint_id, path_id, endpoint_order, junction_id, zone_connector_id, terminus_id) FROM stdin;
\.


--
-- TOC entry 5773 (class 0 OID 32762)
-- Dependencies: 301
-- Data for Name: path_segment; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.path_segment (path_segment_id, path_id, sequence_no, segment_type, geometry, width_metres, fallback_congestion, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5774 (class 0 OID 32778)
-- Dependencies: 302
-- Data for Name: path_segment_congestion; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.path_segment_congestion (path_segment_congestion_id, path_segment_id, congestion_level, observed_at, created_at) FROM stdin;
\.


--
-- TOC entry 5777 (class 0 OID 32790)
-- Dependencies: 305
-- Data for Name: physical_beacon; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.physical_beacon (physical_beacon_id, asset_name, hardware_model, ibeacon_uuid, ibeacon_major, ibeacon_minor, status, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5779 (class 0 OID 32810)
-- Dependencies: 307
-- Data for Name: poi; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.poi (poi_id, event_id, name, poi_type_id, description, geometry, created_at, updated_at, lod_display_level) FROM stdin;
\.


--
-- TOC entry 5780 (class 0 OID 32824)
-- Dependencies: 308
-- Data for Name: poi_capability; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.poi_capability (poi_capability_id, code, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5782 (class 0 OID 32837)
-- Dependencies: 310
-- Data for Name: poi_item; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.poi_item (poi_item_id, poi_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5784 (class 0 OID 32850)
-- Dependencies: 312
-- Data for Name: poi_path_connector; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.poi_path_connector (poi_id, path_connector_id, is_primary) FROM stdin;
\.


--
-- TOC entry 5786 (class 0 OID 32858)
-- Dependencies: 314
-- Data for Name: poi_type; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.poi_type (poi_type_id, code, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5787 (class 0 OID 32870)
-- Dependencies: 315
-- Data for Name: poi_type_capability; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.poi_type_capability (poi_type_id, poi_capability_id, created_at) FROM stdin;
\.


--
-- TOC entry 5789 (class 0 OID 32878)
-- Dependencies: 317
-- Data for Name: queue; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.queue (queue_id, event_id, name, description, fallback_wait_seconds, created_at, updated_at, poi_id) FROM stdin;
\.


--
-- TOC entry 5791 (class 0 OID 32893)
-- Dependencies: 319
-- Data for Name: queue_source; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.queue_source (queue_source_id, queue_id, queue_source_type_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5792 (class 0 OID 32906)
-- Dependencies: 320
-- Data for Name: queue_source_ble; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.queue_source_ble (queue_source_ble_id, queue_source_id, event_beacon_id, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5795 (class 0 OID 32918)
-- Dependencies: 323
-- Data for Name: queue_source_type; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.queue_source_type (queue_source_type_id, code, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5797 (class 0 OID 32931)
-- Dependencies: 325
-- Data for Name: queue_wait_time; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.queue_wait_time (queue_wait_time_id, queue_id, wait_seconds, observed_at, created_at, queue_source_id) FROM stdin;
\.


--
-- TOC entry 5799 (class 0 OID 32944)
-- Dependencies: 327
-- Data for Name: ramp; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.ramp (ramp_id, traversal_path_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5801 (class 0 OID 32957)
-- Dependencies: 329
-- Data for Name: staircase; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.staircase (staircase_id, traversal_path_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5803 (class 0 OID 32970)
-- Dependencies: 331
-- Data for Name: terminus; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.terminus (terminus_id, event_id, name, terminus_type, geometry, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5805 (class 0 OID 32986)
-- Dependencies: 333
-- Data for Name: traversal_destination; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.traversal_destination (traversal_destination_id, poi_id, name, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5807 (class 0 OID 32999)
-- Dependencies: 335
-- Data for Name: traversal_path; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.traversal_path (traversal_path_id, name, description, created_at, updated_at, path_connector_id, traversal_destination_id) FROM stdin;
\.


--
-- TOC entry 5809 (class 0 OID 33013)
-- Dependencies: 337
-- Data for Name: weather_forecast; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.weather_forecast (weather_forecast_id, event_id, forecast_at, valid_from, valid_to, temperature_c, precipitation_probability, wind_speed_mps, description, created_at, weather_condition) FROM stdin;
\.


--
-- TOC entry 5811 (class 0 OID 33028)
-- Dependencies: 339
-- Data for Name: weather_update; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.weather_update (weather_update_id, event_id, starts_at, ends_at, weather_condition, message, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5813 (class 0 OID 33044)
-- Dependencies: 341
-- Data for Name: zone; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.zone (zone_id, event_id, name, description, geometry, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5814 (class 0 OID 33056)
-- Dependencies: 342
-- Data for Name: zone_connector; Type: TABLE DATA; Schema: design; Owner: -
--

COPY design.zone_connector (zone_connector_id, zone_id, name, connector_type, geometry, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5817 (class 0 OID 33073)
-- Dependencies: 345
-- Data for Name: acknowledgement; Type: TABLE DATA; Schema: messaging; Owner: -
--

COPY messaging.acknowledgement (acknowledgement_id, delivery_id, acknowledged_at) FROM stdin;
\.


--
-- TOC entry 5831 (class 0 OID 42064)
-- Dependencies: 359
-- Data for Name: crew_mls_group; Type: TABLE DATA; Schema: messaging; Owner: -
--

COPY messaging.crew_mls_group (crew_id, group_id, next_sequence, reservation_id, reservation_request_id, reservation_owner_crew_pal_id, reservation_fencing_token, reservation_expires_at, group_revision, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5833 (class 0 OID 42133)
-- Dependencies: 361
-- Data for Name: crew_mls_key_package; Type: TABLE DATA; Schema: messaging; Owner: -
--

COPY messaging.crew_mls_key_package (key_package_id, crew_id, crew_pal_id, payload, created_at, expires_at, consumed_at, consumed_by_operation_id) FROM stdin;
\.


--
-- TOC entry 5819 (class 0 OID 33081)
-- Dependencies: 347
-- Data for Name: delivery; Type: TABLE DATA; Schema: messaging; Owner: -
--

COPY messaging.delivery (delivery_id, message_id, pal_id, status, queued_at, delivered_at, expires_at, cancelled_at, attempt_count, last_attempt_at, crew_id, crew_pal_id) FROM stdin;
\.


--
-- TOC entry 5821 (class 0 OID 33100)
-- Dependencies: 349
-- Data for Name: message; Type: TABLE DATA; Schema: messaging; Owner: -
--

COPY messaging.message (message_id, event_id, message_type, payload, created_at, expires_at, cancelled_at, crew_id, sender_crew_pal_id, crew_sequence, protocol_type, operation_id, payload_digest, group_revision) FROM stdin;
\.


--
-- TOC entry 4950 (class 0 OID 31502)
-- Dependencies: 231
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 5913 (class 0 OID 0)
-- Dependencies: 236
-- Name: assistance_request_assistance_request_id_seq; Type: SEQUENCE SET; Schema: activity; Owner: -
--

SELECT pg_catalog.setval('activity.assistance_request_assistance_request_id_seq', 1, false);


--
-- TOC entry 5914 (class 0 OID 0)
-- Dependencies: 238
-- Name: navigation_event_navigation_event_id_seq; Type: SEQUENCE SET; Schema: activity; Owner: -
--

SELECT pg_catalog.setval('activity.navigation_event_navigation_event_id_seq', 1, false);


--
-- TOC entry 5915 (class 0 OID 0)
-- Dependencies: 240
-- Name: navigation_segment_navigation_segment_id_seq; Type: SEQUENCE SET; Schema: activity; Owner: -
--

SELECT pg_catalog.setval('activity.navigation_segment_navigation_segment_id_seq', 1, false);


--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 242
-- Name: navigation_session_navigation_session_id_seq; Type: SEQUENCE SET; Schema: activity; Owner: -
--

SELECT pg_catalog.setval('activity.navigation_session_navigation_session_id_seq', 1, false);


--
-- TOC entry 5917 (class 0 OID 0)
-- Dependencies: 244
-- Name: pal_pinger_session_pal_pinger_session_id_seq; Type: SEQUENCE SET; Schema: activity; Owner: -
--

SELECT pg_catalog.setval('activity.pal_pinger_session_pal_pinger_session_id_seq', 1, false);


--
-- TOC entry 5918 (class 0 OID 0)
-- Dependencies: 246
-- Name: authority_authority_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: -
--

SELECT pg_catalog.setval('audit.authority_authority_id_seq', 1, false);


--
-- TOC entry 5919 (class 0 OID 0)
-- Dependencies: 248
-- Name: event_audit_event_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: -
--

SELECT pg_catalog.setval('audit.event_audit_event_id_seq', 1, false);


--
-- TOC entry 5920 (class 0 OID 0)
-- Dependencies: 251
-- Name: operator_operator_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: -
--

SELECT pg_catalog.setval('audit.operator_operator_id_seq', 1, false);


--
-- TOC entry 5921 (class 0 OID 0)
-- Dependencies: 253
-- Name: communication_communication_id_seq; Type: SEQUENCE SET; Schema: communications; Owner: -
--

SELECT pg_catalog.setval('communications.communication_communication_id_seq', 1, false);


--
-- TOC entry 5922 (class 0 OID 0)
-- Dependencies: 255
-- Name: subscription_subscription_id_seq; Type: SEQUENCE SET; Schema: communications; Owner: -
--

SELECT pg_catalog.setval('communications.subscription_subscription_id_seq', 1, false);


--
-- TOC entry 5923 (class 0 OID 0)
-- Dependencies: 257
-- Name: crew_crew_id_seq; Type: SEQUENCE SET; Schema: community; Owner: -
--

SELECT pg_catalog.setval('community.crew_crew_id_seq', 25, true);


--
-- TOC entry 5924 (class 0 OID 0)
-- Dependencies: 355
-- Name: crew_meetup_crew_meetup_id_seq; Type: SEQUENCE SET; Schema: community; Owner: -
--

SELECT pg_catalog.setval('community.crew_meetup_crew_meetup_id_seq', 1, false);


--
-- TOC entry 5925 (class 0 OID 0)
-- Dependencies: 357
-- Name: crew_meetup_response_crew_meetup_response_id_seq; Type: SEQUENCE SET; Schema: community; Owner: -
--

SELECT pg_catalog.setval('community.crew_meetup_response_crew_meetup_response_id_seq', 1, false);


--
-- TOC entry 5926 (class 0 OID 0)
-- Dependencies: 259
-- Name: crew_message_crew_message_id_seq; Type: SEQUENCE SET; Schema: community; Owner: -
--

SELECT pg_catalog.setval('community.crew_message_crew_message_id_seq', 2, true);


--
-- TOC entry 5927 (class 0 OID 0)
-- Dependencies: 261
-- Name: crew_pal_crew_pal_id_seq; Type: SEQUENCE SET; Schema: community; Owner: -
--

SELECT pg_catalog.setval('community.crew_pal_crew_pal_id_seq', 54, true);


--
-- TOC entry 5928 (class 0 OID 0)
-- Dependencies: 353
-- Name: crew_pick_crew_pick_id_seq; Type: SEQUENCE SET; Schema: community; Owner: -
--

SELECT pg_catalog.setval('community.crew_pick_crew_pick_id_seq', 1, false);


--
-- TOC entry 5929 (class 0 OID 0)
-- Dependencies: 264
-- Name: allergen_allergen_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.allergen_allergen_id_seq', 1, false);


--
-- TOC entry 5930 (class 0 OID 0)
-- Dependencies: 266
-- Name: dietary_attribute_dietary_attribute_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.dietary_attribute_dietary_attribute_id_seq', 1, false);


--
-- TOC entry 5931 (class 0 OID 0)
-- Dependencies: 268
-- Name: elevator_elevator_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.elevator_elevator_id_seq', 1, false);


--
-- TOC entry 5932 (class 0 OID 0)
-- Dependencies: 270
-- Name: escalator_escalator_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.escalator_escalator_id_seq', 1, false);


--
-- TOC entry 5933 (class 0 OID 0)
-- Dependencies: 273
-- Name: event_beacon_event_beacon_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.event_beacon_event_beacon_id_seq', 1, false);


--
-- TOC entry 5934 (class 0 OID 0)
-- Dependencies: 275
-- Name: event_beacon_physical_event_beacon_physical_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.event_beacon_physical_event_beacon_physical_id_seq', 1, false);


--
-- TOC entry 5935 (class 0 OID 0)
-- Dependencies: 277
-- Name: event_day_event_day_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.event_day_event_day_id_seq', 1, false);


--
-- TOC entry 5936 (class 0 OID 0)
-- Dependencies: 278
-- Name: event_event_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.event_event_id_seq', 1, true);


--
-- TOC entry 5937 (class 0 OID 0)
-- Dependencies: 280
-- Name: flight_flight_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.flight_flight_id_seq', 1, false);


--
-- TOC entry 5938 (class 0 OID 0)
-- Dependencies: 282
-- Name: item_sequence_item_sequence_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.item_sequence_item_sequence_id_seq', 1, false);


--
-- TOC entry 5939 (class 0 OID 0)
-- Dependencies: 284
-- Name: junction_junction_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.junction_junction_id_seq', 1, false);


--
-- TOC entry 5940 (class 0 OID 0)
-- Dependencies: 287
-- Name: offering_availability_offering_availability_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.offering_availability_offering_availability_id_seq', 1, false);


--
-- TOC entry 5941 (class 0 OID 0)
-- Dependencies: 291
-- Name: offering_item_offering_item_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.offering_item_offering_item_id_seq', 1, false);


--
-- TOC entry 5942 (class 0 OID 0)
-- Dependencies: 292
-- Name: offering_offering_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.offering_offering_id_seq', 1, false);


--
-- TOC entry 5943 (class 0 OID 0)
-- Dependencies: 294
-- Name: offering_type_offering_type_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.offering_type_offering_type_id_seq', 1, false);


--
-- TOC entry 5944 (class 0 OID 0)
-- Dependencies: 297
-- Name: path_connector_path_connector_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.path_connector_path_connector_id_seq', 1, false);


--
-- TOC entry 5945 (class 0 OID 0)
-- Dependencies: 299
-- Name: path_endpoint_path_endpoint_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.path_endpoint_path_endpoint_id_seq', 1, false);


--
-- TOC entry 5946 (class 0 OID 0)
-- Dependencies: 300
-- Name: path_path_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.path_path_id_seq', 1, false);


--
-- TOC entry 5947 (class 0 OID 0)
-- Dependencies: 303
-- Name: path_segment_congestion_path_segment_congestion_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.path_segment_congestion_path_segment_congestion_id_seq', 1, false);


--
-- TOC entry 5948 (class 0 OID 0)
-- Dependencies: 304
-- Name: path_segment_path_segment_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.path_segment_path_segment_id_seq', 1, false);


--
-- TOC entry 5949 (class 0 OID 0)
-- Dependencies: 306
-- Name: physical_beacon_physical_beacon_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.physical_beacon_physical_beacon_id_seq', 1, false);


--
-- TOC entry 5950 (class 0 OID 0)
-- Dependencies: 309
-- Name: poi_capability_poi_capability_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.poi_capability_poi_capability_id_seq', 1, false);


--
-- TOC entry 5951 (class 0 OID 0)
-- Dependencies: 311
-- Name: poi_item_poi_item_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.poi_item_poi_item_id_seq', 1, false);


--
-- TOC entry 5952 (class 0 OID 0)
-- Dependencies: 313
-- Name: poi_poi_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.poi_poi_id_seq', 1, false);


--
-- TOC entry 5953 (class 0 OID 0)
-- Dependencies: 316
-- Name: poi_type_poi_type_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.poi_type_poi_type_id_seq', 1, false);


--
-- TOC entry 5954 (class 0 OID 0)
-- Dependencies: 318
-- Name: queue_queue_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.queue_queue_id_seq', 1, false);


--
-- TOC entry 5955 (class 0 OID 0)
-- Dependencies: 321
-- Name: queue_source_ble_queue_source_ble_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.queue_source_ble_queue_source_ble_id_seq', 1, false);


--
-- TOC entry 5956 (class 0 OID 0)
-- Dependencies: 322
-- Name: queue_source_queue_source_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.queue_source_queue_source_id_seq', 1, false);


--
-- TOC entry 5957 (class 0 OID 0)
-- Dependencies: 324
-- Name: queue_source_type_queue_source_type_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.queue_source_type_queue_source_type_id_seq', 1, false);


--
-- TOC entry 5958 (class 0 OID 0)
-- Dependencies: 326
-- Name: queue_wait_time_queue_wait_time_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.queue_wait_time_queue_wait_time_id_seq', 1, false);


--
-- TOC entry 5959 (class 0 OID 0)
-- Dependencies: 328
-- Name: ramp_ramp_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.ramp_ramp_id_seq', 1, false);


--
-- TOC entry 5960 (class 0 OID 0)
-- Dependencies: 330
-- Name: staircase_staircase_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.staircase_staircase_id_seq', 1, false);


--
-- TOC entry 5961 (class 0 OID 0)
-- Dependencies: 332
-- Name: terminus_terminus_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.terminus_terminus_id_seq', 1, false);


--
-- TOC entry 5962 (class 0 OID 0)
-- Dependencies: 334
-- Name: traversal_destination_traversal_destination_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.traversal_destination_traversal_destination_id_seq', 1, false);


--
-- TOC entry 5963 (class 0 OID 0)
-- Dependencies: 336
-- Name: traversal_path_traversal_path_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.traversal_path_traversal_path_id_seq', 1, false);


--
-- TOC entry 5964 (class 0 OID 0)
-- Dependencies: 338
-- Name: weather_forecast_weather_forecast_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.weather_forecast_weather_forecast_id_seq', 1, false);


--
-- TOC entry 5965 (class 0 OID 0)
-- Dependencies: 340
-- Name: weather_update_weather_update_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.weather_update_weather_update_id_seq', 1, false);


--
-- TOC entry 5966 (class 0 OID 0)
-- Dependencies: 343
-- Name: zone_connector_zone_connector_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.zone_connector_zone_connector_id_seq', 1, false);


--
-- TOC entry 5967 (class 0 OID 0)
-- Dependencies: 344
-- Name: zone_zone_id_seq; Type: SEQUENCE SET; Schema: design; Owner: -
--

SELECT pg_catalog.setval('design.zone_zone_id_seq', 1, false);


--
-- TOC entry 5968 (class 0 OID 0)
-- Dependencies: 346
-- Name: acknowledgement_acknowledgement_id_seq; Type: SEQUENCE SET; Schema: messaging; Owner: -
--

SELECT pg_catalog.setval('messaging.acknowledgement_acknowledgement_id_seq', 1, false);


--
-- TOC entry 5969 (class 0 OID 0)
-- Dependencies: 360
-- Name: crew_mls_key_package_key_package_id_seq; Type: SEQUENCE SET; Schema: messaging; Owner: -
--

SELECT pg_catalog.setval('messaging.crew_mls_key_package_key_package_id_seq', 1, false);


--
-- TOC entry 5970 (class 0 OID 0)
-- Dependencies: 348
-- Name: delivery_delivery_id_seq; Type: SEQUENCE SET; Schema: messaging; Owner: -
--

SELECT pg_catalog.setval('messaging.delivery_delivery_id_seq', 1, false);


--
-- TOC entry 5971 (class 0 OID 0)
-- Dependencies: 350
-- Name: message_message_id_seq; Type: SEQUENCE SET; Schema: messaging; Owner: -
--

SELECT pg_catalog.setval('messaging.message_message_id_seq', 1, false);


--
-- TOC entry 5221 (class 2606 OID 33170)
-- Name: assistance_request assistance_request_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.assistance_request
    ADD CONSTRAINT assistance_request_pkey PRIMARY KEY (assistance_request_id);


--
-- TOC entry 5223 (class 2606 OID 33172)
-- Name: navigation_event navigation_event_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_event
    ADD CONSTRAINT navigation_event_pkey PRIMARY KEY (navigation_event_id);


--
-- TOC entry 5225 (class 2606 OID 33174)
-- Name: navigation_segment navigation_segment_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_pkey PRIMARY KEY (navigation_segment_id);


--
-- TOC entry 5227 (class 2606 OID 33176)
-- Name: navigation_segment navigation_segment_session_sequence_unique; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_session_sequence_unique UNIQUE (navigation_session_id, sequence_no);


--
-- TOC entry 5229 (class 2606 OID 33178)
-- Name: navigation_session navigation_session_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_session
    ADD CONSTRAINT navigation_session_pkey PRIMARY KEY (navigation_session_id);


--
-- TOC entry 5231 (class 2606 OID 33180)
-- Name: pal_pinger_session pal_pinger_session_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.pal_pinger_session
    ADD CONSTRAINT pal_pinger_session_pkey PRIMARY KEY (pal_pinger_session_id);


--
-- TOC entry 5233 (class 2606 OID 33182)
-- Name: authority authority_event_name_unique; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority
    ADD CONSTRAINT authority_event_name_unique UNIQUE (event_id, name);


--
-- TOC entry 5235 (class 2606 OID 33184)
-- Name: authority authority_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority
    ADD CONSTRAINT authority_pkey PRIMARY KEY (authority_id);


--
-- TOC entry 5237 (class 2606 OID 33186)
-- Name: event event_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (audit_event_id);


--
-- TOC entry 5243 (class 2606 OID 33188)
-- Name: operator_authority operator_authority_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator_authority
    ADD CONSTRAINT operator_authority_pkey PRIMARY KEY (operator_id, authority_id);


--
-- TOC entry 5239 (class 2606 OID 33190)
-- Name: operator operator_event_firebase_unique; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator
    ADD CONSTRAINT operator_event_firebase_unique UNIQUE (event_id, firebase_uid);


--
-- TOC entry 5241 (class 2606 OID 33192)
-- Name: operator operator_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator
    ADD CONSTRAINT operator_pkey PRIMARY KEY (operator_id);


--
-- TOC entry 5245 (class 2606 OID 33194)
-- Name: communication communication_pkey; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_pkey PRIMARY KEY (communication_id);


--
-- TOC entry 5247 (class 2606 OID 33196)
-- Name: subscription subscription_item_sequence_unique; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_item_sequence_unique UNIQUE (pal_id, item_sequence_id);


--
-- TOC entry 5249 (class 2606 OID 33198)
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (subscription_id);


--
-- TOC entry 5251 (class 2606 OID 33200)
-- Name: subscription subscription_poi_item_unique; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_item_unique UNIQUE (pal_id, poi_item_id);


--
-- TOC entry 5253 (class 2606 OID 33202)
-- Name: subscription subscription_poi_unique; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_unique UNIQUE (pal_id, poi_id);


--
-- TOC entry 5255 (class 2606 OID 41820)
-- Name: crew crew_event_crew_uq; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew
    ADD CONSTRAINT crew_event_crew_uq UNIQUE (event_id, crew_id);


--
-- TOC entry 5427 (class 2606 OID 36413)
-- Name: crew_invitation crew_invitation_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_invitation
    ADD CONSTRAINT crew_invitation_pkey PRIMARY KEY (crew_id);


--
-- TOC entry 5429 (class 2606 OID 36415)
-- Name: crew_invitation crew_invitation_token_hash_key; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_invitation
    ADD CONSTRAINT crew_invitation_token_hash_key UNIQUE (token_hash);


--
-- TOC entry 5439 (class 2606 OID 41895)
-- Name: crew_meetup crew_meetup_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup
    ADD CONSTRAINT crew_meetup_pkey PRIMARY KEY (crew_meetup_id);


--
-- TOC entry 5442 (class 2606 OID 41930)
-- Name: crew_meetup_response crew_meetup_response_one_per_pal_uq; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup_response
    ADD CONSTRAINT crew_meetup_response_one_per_pal_uq UNIQUE (crew_meetup_id, pal_id);


--
-- TOC entry 5445 (class 2606 OID 41928)
-- Name: crew_meetup_response crew_meetup_response_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup_response
    ADD CONSTRAINT crew_meetup_response_pkey PRIMARY KEY (crew_meetup_response_id);


--
-- TOC entry 5262 (class 2606 OID 41826)
-- Name: crew_message crew_message_idempotency_uq; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_idempotency_uq UNIQUE (crew_id, idempotency_key);


--
-- TOC entry 5264 (class 2606 OID 33204)
-- Name: crew_message crew_message_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_pkey PRIMARY KEY (crew_message_id);


--
-- TOC entry 5267 (class 2606 OID 42063)
-- Name: crew_pal crew_pal_id_crew_uq; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_id_crew_uq UNIQUE (crew_pal_id, crew_id);


--
-- TOC entry 5270 (class 2606 OID 41944)
-- Name: crew_pal crew_pal_period_identity_uq; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_period_identity_uq UNIQUE (crew_pal_id, crew_id, pal_id);


--
-- TOC entry 5272 (class 2606 OID 33206)
-- Name: crew_pal crew_pal_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_pkey PRIMARY KEY (crew_pal_id);


--
-- TOC entry 5432 (class 2606 OID 41854)
-- Name: crew_pick crew_pick_one_poi_per_crew_uq; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pick
    ADD CONSTRAINT crew_pick_one_poi_per_crew_uq UNIQUE (crew_id, poi_id);


--
-- TOC entry 5434 (class 2606 OID 41852)
-- Name: crew_pick crew_pick_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pick
    ADD CONSTRAINT crew_pick_pkey PRIMARY KEY (crew_pick_id);


--
-- TOC entry 5257 (class 2606 OID 33208)
-- Name: crew crew_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew
    ADD CONSTRAINT crew_pkey PRIMARY KEY (crew_id);


--
-- TOC entry 5425 (class 2606 OID 33774)
-- Name: event_session event_session_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.event_session
    ADD CONSTRAINT event_session_pkey PRIMARY KEY (event_session_id);


--
-- TOC entry 5274 (class 2606 OID 33210)
-- Name: pal pal_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.pal
    ADD CONSTRAINT pal_pkey PRIMARY KEY (pal_id);


--
-- TOC entry 5276 (class 2606 OID 33212)
-- Name: allergen allergen_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen
    ADD CONSTRAINT allergen_code_unique UNIQUE (code);


--
-- TOC entry 5278 (class 2606 OID 33214)
-- Name: allergen allergen_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen
    ADD CONSTRAINT allergen_name_unique UNIQUE (name);


--
-- TOC entry 5280 (class 2606 OID 33216)
-- Name: allergen allergen_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen
    ADD CONSTRAINT allergen_pkey PRIMARY KEY (allergen_id);


--
-- TOC entry 5282 (class 2606 OID 33218)
-- Name: dietary_attribute dietary_attribute_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute
    ADD CONSTRAINT dietary_attribute_code_unique UNIQUE (code);


--
-- TOC entry 5284 (class 2606 OID 33220)
-- Name: dietary_attribute dietary_attribute_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute
    ADD CONSTRAINT dietary_attribute_name_unique UNIQUE (name);


--
-- TOC entry 5286 (class 2606 OID 33222)
-- Name: dietary_attribute dietary_attribute_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute
    ADD CONSTRAINT dietary_attribute_pkey PRIMARY KEY (dietary_attribute_id);


--
-- TOC entry 5288 (class 2606 OID 33224)
-- Name: elevator elevator_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.elevator
    ADD CONSTRAINT elevator_pkey PRIMARY KEY (elevator_id);


--
-- TOC entry 5290 (class 2606 OID 33226)
-- Name: escalator escalator_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.escalator
    ADD CONSTRAINT escalator_pkey PRIMARY KEY (escalator_id);


--
-- TOC entry 5297 (class 2606 OID 33228)
-- Name: event_beacon_physical event_beacon_physical_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_pkey PRIMARY KEY (event_beacon_physical_id);


--
-- TOC entry 5299 (class 2606 OID 33230)
-- Name: event_beacon_physical event_beacon_physical_unique_assignment; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_unique_assignment UNIQUE (event_beacon_id, physical_beacon_id);


--
-- TOC entry 5294 (class 2606 OID 33232)
-- Name: event_beacon event_beacon_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon
    ADD CONSTRAINT event_beacon_pkey PRIMARY KEY (event_beacon_id);


--
-- TOC entry 5301 (class 2606 OID 33234)
-- Name: event_day event_day_event_date_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_event_date_unique UNIQUE (event_id, date);


--
-- TOC entry 5303 (class 2606 OID 33236)
-- Name: event_day event_day_event_number_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_event_number_unique UNIQUE (event_id, day_number);


--
-- TOC entry 5305 (class 2606 OID 33238)
-- Name: event_day event_day_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_pkey PRIMARY KEY (event_day_id);


--
-- TOC entry 5292 (class 2606 OID 33240)
-- Name: event event_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (event_id);


--
-- TOC entry 5307 (class 2606 OID 33242)
-- Name: flight flight_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_pkey PRIMARY KEY (flight_id);


--
-- TOC entry 5309 (class 2606 OID 33244)
-- Name: flight flight_sequence_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_sequence_unique UNIQUE (staircase_id, sequence_no);


--
-- TOC entry 5311 (class 2606 OID 33246)
-- Name: item_sequence item_sequence_event_day_sequence_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_event_day_sequence_unique UNIQUE (event_day_id, sequence_no);


--
-- TOC entry 5313 (class 2606 OID 33248)
-- Name: item_sequence item_sequence_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_pkey PRIMARY KEY (item_sequence_id);


--
-- TOC entry 5315 (class 2606 OID 33250)
-- Name: junction junction_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction
    ADD CONSTRAINT junction_pkey PRIMARY KEY (junction_id);


--
-- TOC entry 5319 (class 2606 OID 33252)
-- Name: offering_availability offering_availability_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_availability
    ADD CONSTRAINT offering_availability_pkey PRIMARY KEY (offering_availability_id);


--
-- TOC entry 5323 (class 2606 OID 33254)
-- Name: offering_item_allergen offering_item_allergen_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_allergen
    ADD CONSTRAINT offering_item_allergen_pkey PRIMARY KEY (offering_item_id, allergen_id);


--
-- TOC entry 5325 (class 2606 OID 33256)
-- Name: offering_item_dietary_attribute offering_item_dietary_attribute_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_dietary_attribute
    ADD CONSTRAINT offering_item_dietary_attribute_pkey PRIMARY KEY (offering_item_id, dietary_attribute_id);


--
-- TOC entry 5321 (class 2606 OID 33258)
-- Name: offering_item offering_item_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item
    ADD CONSTRAINT offering_item_pkey PRIMARY KEY (offering_item_id);


--
-- TOC entry 5317 (class 2606 OID 33260)
-- Name: offering offering_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering
    ADD CONSTRAINT offering_pkey PRIMARY KEY (offering_id);


--
-- TOC entry 5327 (class 2606 OID 33262)
-- Name: offering_type offering_type_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type
    ADD CONSTRAINT offering_type_code_unique UNIQUE (code);


--
-- TOC entry 5329 (class 2606 OID 33264)
-- Name: offering_type offering_type_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type
    ADD CONSTRAINT offering_type_name_unique UNIQUE (name);


--
-- TOC entry 5331 (class 2606 OID 33266)
-- Name: offering_type offering_type_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type
    ADD CONSTRAINT offering_type_pkey PRIMARY KEY (offering_type_id);


--
-- TOC entry 5335 (class 2606 OID 33268)
-- Name: path_connector path_connector_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_connector
    ADD CONSTRAINT path_connector_pkey PRIMARY KEY (path_connector_id);


--
-- TOC entry 5337 (class 2606 OID 33270)
-- Name: path_endpoint path_endpoint_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_pkey PRIMARY KEY (path_endpoint_id);


--
-- TOC entry 5339 (class 2606 OID 33272)
-- Name: path_endpoint path_endpoint_unique_order; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_unique_order UNIQUE (path_id, endpoint_order);


--
-- TOC entry 5333 (class 2606 OID 33274)
-- Name: path path_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path
    ADD CONSTRAINT path_pkey PRIMARY KEY (path_id);


--
-- TOC entry 5345 (class 2606 OID 33276)
-- Name: path_segment_congestion path_segment_congestion_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment_congestion
    ADD CONSTRAINT path_segment_congestion_pkey PRIMARY KEY (path_segment_congestion_id);


--
-- TOC entry 5341 (class 2606 OID 33278)
-- Name: path_segment path_segment_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment
    ADD CONSTRAINT path_segment_pkey PRIMARY KEY (path_segment_id);


--
-- TOC entry 5343 (class 2606 OID 33280)
-- Name: path_segment path_segment_unique_sequence; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment
    ADD CONSTRAINT path_segment_unique_sequence UNIQUE (path_id, sequence_no);


--
-- TOC entry 5347 (class 2606 OID 33282)
-- Name: physical_beacon physical_beacon_asset_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon
    ADD CONSTRAINT physical_beacon_asset_name_unique UNIQUE (asset_name);


--
-- TOC entry 5349 (class 2606 OID 33284)
-- Name: physical_beacon physical_beacon_ibeacon_identity_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon
    ADD CONSTRAINT physical_beacon_ibeacon_identity_unique UNIQUE (ibeacon_uuid, ibeacon_major, ibeacon_minor);


--
-- TOC entry 5351 (class 2606 OID 33286)
-- Name: physical_beacon physical_beacon_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon
    ADD CONSTRAINT physical_beacon_pkey PRIMARY KEY (physical_beacon_id);


--
-- TOC entry 5357 (class 2606 OID 33288)
-- Name: poi_capability poi_capability_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability
    ADD CONSTRAINT poi_capability_code_unique UNIQUE (code);


--
-- TOC entry 5359 (class 2606 OID 33290)
-- Name: poi_capability poi_capability_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability
    ADD CONSTRAINT poi_capability_name_unique UNIQUE (name);


--
-- TOC entry 5361 (class 2606 OID 33292)
-- Name: poi_capability poi_capability_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability
    ADD CONSTRAINT poi_capability_pkey PRIMARY KEY (poi_capability_id);


--
-- TOC entry 5353 (class 2606 OID 41822)
-- Name: poi poi_event_poi_uq; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_event_poi_uq UNIQUE (event_id, poi_id);


--
-- TOC entry 5363 (class 2606 OID 33294)
-- Name: poi_item poi_item_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_item
    ADD CONSTRAINT poi_item_pkey PRIMARY KEY (poi_item_id);


--
-- TOC entry 5365 (class 2606 OID 33296)
-- Name: poi_path_connector poi_path_connector_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_path_connector
    ADD CONSTRAINT poi_path_connector_pkey PRIMARY KEY (poi_id, path_connector_id);


--
-- TOC entry 5355 (class 2606 OID 33298)
-- Name: poi poi_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_pkey PRIMARY KEY (poi_id);


--
-- TOC entry 5373 (class 2606 OID 33300)
-- Name: poi_type_capability poi_type_capability_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type_capability
    ADD CONSTRAINT poi_type_capability_pkey PRIMARY KEY (poi_type_id, poi_capability_id);


--
-- TOC entry 5367 (class 2606 OID 33302)
-- Name: poi_type poi_type_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type
    ADD CONSTRAINT poi_type_code_unique UNIQUE (code);


--
-- TOC entry 5369 (class 2606 OID 33304)
-- Name: poi_type poi_type_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type
    ADD CONSTRAINT poi_type_name_unique UNIQUE (name);


--
-- TOC entry 5371 (class 2606 OID 33306)
-- Name: poi_type poi_type_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type
    ADD CONSTRAINT poi_type_pkey PRIMARY KEY (poi_type_id);


--
-- TOC entry 5375 (class 2606 OID 33308)
-- Name: queue queue_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_pkey PRIMARY KEY (queue_id);


--
-- TOC entry 5379 (class 2606 OID 33310)
-- Name: queue_source_ble queue_source_ble_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_pkey PRIMARY KEY (queue_source_ble_id);


--
-- TOC entry 5381 (class 2606 OID 33312)
-- Name: queue_source_ble queue_source_ble_source_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_source_unique UNIQUE (queue_source_id);


--
-- TOC entry 5377 (class 2606 OID 33314)
-- Name: queue_source queue_source_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source
    ADD CONSTRAINT queue_source_pkey PRIMARY KEY (queue_source_id);


--
-- TOC entry 5383 (class 2606 OID 33316)
-- Name: queue_source_type queue_source_type_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type
    ADD CONSTRAINT queue_source_type_code_unique UNIQUE (code);


--
-- TOC entry 5385 (class 2606 OID 33318)
-- Name: queue_source_type queue_source_type_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type
    ADD CONSTRAINT queue_source_type_name_unique UNIQUE (name);


--
-- TOC entry 5387 (class 2606 OID 33320)
-- Name: queue_source_type queue_source_type_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type
    ADD CONSTRAINT queue_source_type_pkey PRIMARY KEY (queue_source_type_id);


--
-- TOC entry 5389 (class 2606 OID 33322)
-- Name: queue_wait_time queue_wait_time_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_pkey PRIMARY KEY (queue_wait_time_id);


--
-- TOC entry 5391 (class 2606 OID 33324)
-- Name: ramp ramp_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.ramp
    ADD CONSTRAINT ramp_pkey PRIMARY KEY (ramp_id);


--
-- TOC entry 5393 (class 2606 OID 33326)
-- Name: staircase staircase_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.staircase
    ADD CONSTRAINT staircase_pkey PRIMARY KEY (staircase_id);


--
-- TOC entry 5395 (class 2606 OID 33328)
-- Name: terminus terminus_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.terminus
    ADD CONSTRAINT terminus_pkey PRIMARY KEY (terminus_id);


--
-- TOC entry 5397 (class 2606 OID 33330)
-- Name: traversal_destination traversal_destination_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_destination
    ADD CONSTRAINT traversal_destination_pkey PRIMARY KEY (traversal_destination_id);


--
-- TOC entry 5399 (class 2606 OID 33332)
-- Name: traversal_path traversal_path_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path
    ADD CONSTRAINT traversal_path_pkey PRIMARY KEY (traversal_path_id);


--
-- TOC entry 5401 (class 2606 OID 33334)
-- Name: weather_forecast weather_forecast_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_forecast
    ADD CONSTRAINT weather_forecast_pkey PRIMARY KEY (weather_forecast_id);


--
-- TOC entry 5403 (class 2606 OID 33336)
-- Name: weather_update weather_update_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_update
    ADD CONSTRAINT weather_update_pkey PRIMARY KEY (weather_update_id);


--
-- TOC entry 5407 (class 2606 OID 33338)
-- Name: zone_connector zone_connector_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone_connector
    ADD CONSTRAINT zone_connector_pkey PRIMARY KEY (zone_connector_id);


--
-- TOC entry 5405 (class 2606 OID 33340)
-- Name: zone zone_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone
    ADD CONSTRAINT zone_pkey PRIMARY KEY (zone_id);


--
-- TOC entry 5409 (class 2606 OID 33342)
-- Name: acknowledgement acknowledgement_delivery_unique; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement
    ADD CONSTRAINT acknowledgement_delivery_unique UNIQUE (delivery_id);


--
-- TOC entry 5411 (class 2606 OID 33344)
-- Name: acknowledgement acknowledgement_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement
    ADD CONSTRAINT acknowledgement_pkey PRIMARY KEY (acknowledgement_id);


--
-- TOC entry 5448 (class 2606 OID 42087)
-- Name: crew_mls_group crew_mls_group_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.crew_mls_group
    ADD CONSTRAINT crew_mls_group_pkey PRIMARY KEY (crew_id);


--
-- TOC entry 5453 (class 2606 OID 42149)
-- Name: crew_mls_key_package crew_mls_key_package_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.crew_mls_key_package
    ADD CONSTRAINT crew_mls_key_package_pkey PRIMARY KEY (key_package_id);


--
-- TOC entry 5415 (class 2606 OID 33346)
-- Name: delivery delivery_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_pkey PRIMARY KEY (delivery_id);


--
-- TOC entry 5420 (class 2606 OID 42115)
-- Name: message message_id_crew_uq; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_id_crew_uq UNIQUE (message_id, crew_id);


--
-- TOC entry 5422 (class 2606 OID 33348)
-- Name: message message_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (message_id);


--
-- TOC entry 5436 (class 1259 OID 41911)
-- Name: crew_meetup_event_crew_status_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_meetup_event_crew_status_idx ON community.crew_meetup USING btree (event_id, crew_id, status, created_at DESC);


--
-- TOC entry 5437 (class 1259 OID 41912)
-- Name: crew_meetup_expiry_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_meetup_expiry_idx ON community.crew_meetup USING btree (expires_at) WHERE ((status = 'OPEN'::text) AND (expires_at IS NOT NULL));


--
-- TOC entry 5440 (class 1259 OID 41913)
-- Name: crew_meetup_poi_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_meetup_poi_idx ON community.crew_meetup USING btree (poi_id);


--
-- TOC entry 5443 (class 1259 OID 41941)
-- Name: crew_meetup_response_pal_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_meetup_response_pal_idx ON community.crew_meetup_response USING btree (pal_id, responded_at DESC);


--
-- TOC entry 5258 (class 1259 OID 41942)
-- Name: crew_message_affected_pal_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_message_affected_pal_idx ON community.crew_message USING btree (affected_pal_id) WHERE (affected_pal_id IS NOT NULL);


--
-- TOC entry 5259 (class 1259 OID 41840)
-- Name: crew_message_crew_created_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_message_crew_created_idx ON community.crew_message USING btree (crew_id, created_at, crew_message_id);


--
-- TOC entry 5260 (class 1259 OID 41951)
-- Name: crew_message_crew_membership_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_message_crew_membership_idx ON community.crew_message USING btree (crew_id, crew_pal_id, crew_message_id) WHERE (message_type = 'USER'::text);


--
-- TOC entry 5265 (class 1259 OID 41952)
-- Name: crew_pal_history_lookup_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_pal_history_lookup_idx ON community.crew_pal USING btree (crew_id, pal_id, joined_at, left_at);


--
-- TOC entry 5268 (class 1259 OID 33349)
-- Name: crew_pal_one_active_per_pal; Type: INDEX; Schema: community; Owner: -
--

CREATE UNIQUE INDEX crew_pal_one_active_per_pal ON community.crew_pal USING btree (pal_id) WHERE (left_at IS NULL);


--
-- TOC entry 5972 (class 0 OID 0)
-- Dependencies: 5268
-- Name: INDEX crew_pal_one_active_per_pal; Type: COMMENT; Schema: community; Owner: -
--

COMMENT ON INDEX community.crew_pal_one_active_per_pal IS 'Enforces one open Crew membership period per Pal. The left_at IS NULL predicate intentionally reserves the slot for both PENDING admission attempts and ACTIVE membership periods.';


--
-- TOC entry 5430 (class 1259 OID 41870)
-- Name: crew_pick_event_crew_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_pick_event_crew_idx ON community.crew_pick USING btree (event_id, crew_id);


--
-- TOC entry 5435 (class 1259 OID 41871)
-- Name: crew_pick_poi_idx; Type: INDEX; Schema: community; Owner: -
--

CREATE INDEX crew_pick_poi_idx ON community.crew_pick USING btree (poi_id);


--
-- TOC entry 5423 (class 1259 OID 33785)
-- Name: event_session_one_active_per_pal_event; Type: INDEX; Schema: community; Owner: -
--

CREATE UNIQUE INDEX event_session_one_active_per_pal_event ON community.event_session USING btree (pal_id, event_id) WHERE (status = 'ACTIVE'::text);


--
-- TOC entry 5295 (class 1259 OID 33350)
-- Name: event_beacon_one_primary; Type: INDEX; Schema: design; Owner: -
--

CREATE UNIQUE INDEX event_beacon_one_primary ON design.event_beacon_physical USING btree (event_beacon_id) WHERE (role = 'PRIMARY'::text);


--
-- TOC entry 5446 (class 1259 OID 42098)
-- Name: crew_mls_group_group_id_uq; Type: INDEX; Schema: messaging; Owner: -
--

CREATE UNIQUE INDEX crew_mls_group_group_id_uq ON messaging.crew_mls_group USING btree (group_id);


--
-- TOC entry 5449 (class 1259 OID 42099)
-- Name: crew_mls_group_reservation_id_uq; Type: INDEX; Schema: messaging; Owner: -
--

CREATE UNIQUE INDEX crew_mls_group_reservation_id_uq ON messaging.crew_mls_group USING btree (reservation_id) WHERE (reservation_id IS NOT NULL);


--
-- TOC entry 5450 (class 1259 OID 42155)
-- Name: crew_mls_key_package_available_idx; Type: INDEX; Schema: messaging; Owner: -
--

CREATE INDEX crew_mls_key_package_available_idx ON messaging.crew_mls_key_package USING btree (crew_id, crew_pal_id, expires_at) WHERE (consumed_at IS NULL);


--
-- TOC entry 5451 (class 1259 OID 42156)
-- Name: crew_mls_key_package_consumed_operation_uq; Type: INDEX; Schema: messaging; Owner: -
--

CREATE UNIQUE INDEX crew_mls_key_package_consumed_operation_uq ON messaging.crew_mls_key_package USING btree (crew_id, consumed_by_operation_id) WHERE (consumed_by_operation_id IS NOT NULL);


--
-- TOC entry 5412 (class 1259 OID 42131)
-- Name: delivery_crew_pal_status_idx; Type: INDEX; Schema: messaging; Owner: -
--

CREATE INDEX delivery_crew_pal_status_idx ON messaging.delivery USING btree (crew_id, crew_pal_id, status, queued_at) WHERE (crew_pal_id IS NOT NULL);


--
-- TOC entry 5413 (class 1259 OID 42130)
-- Name: delivery_message_crew_pal_uq; Type: INDEX; Schema: messaging; Owner: -
--

CREATE UNIQUE INDEX delivery_message_crew_pal_uq ON messaging.delivery USING btree (message_id, crew_pal_id) WHERE (crew_pal_id IS NOT NULL);


--
-- TOC entry 5416 (class 1259 OID 42117)
-- Name: message_crew_operation_protocol_uq; Type: INDEX; Schema: messaging; Owner: -
--

CREATE UNIQUE INDEX message_crew_operation_protocol_uq ON messaging.message USING btree (crew_id, operation_id, protocol_type) WHERE (protocol_type IS NOT NULL);


--
-- TOC entry 5417 (class 1259 OID 42118)
-- Name: message_crew_protocol_pending_idx; Type: INDEX; Schema: messaging; Owner: -
--

CREATE INDEX message_crew_protocol_pending_idx ON messaging.message USING btree (crew_id, crew_sequence) WHERE ((protocol_type IS NOT NULL) AND (cancelled_at IS NULL));


--
-- TOC entry 5418 (class 1259 OID 42116)
-- Name: message_crew_sequence_uq; Type: INDEX; Schema: messaging; Owner: -
--

CREATE UNIQUE INDEX message_crew_sequence_uq ON messaging.message USING btree (crew_id, crew_sequence) WHERE ((crew_id IS NOT NULL) AND (crew_sequence IS NOT NULL));


--
-- TOC entry 5554 (class 2620 OID 41954)
-- Name: crew_message crew_message_membership_validate_trg; Type: TRIGGER; Schema: community; Owner: -
--

CREATE TRIGGER crew_message_membership_validate_trg BEFORE INSERT ON community.crew_message FOR EACH ROW EXECUTE FUNCTION community.validate_crew_message_membership();


--
-- TOC entry 5454 (class 2606 OID 33351)
-- Name: assistance_request assistance_request_event_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.assistance_request
    ADD CONSTRAINT assistance_request_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5455 (class 2606 OID 33356)
-- Name: navigation_event navigation_event_navigation_session_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_event
    ADD CONSTRAINT navigation_event_navigation_session_id_fkey FOREIGN KEY (navigation_session_id) REFERENCES activity.navigation_session(navigation_session_id);


--
-- TOC entry 5456 (class 2606 OID 33361)
-- Name: navigation_segment navigation_segment_navigation_session_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_navigation_session_id_fkey FOREIGN KEY (navigation_session_id) REFERENCES activity.navigation_session(navigation_session_id);


--
-- TOC entry 5457 (class 2606 OID 33366)
-- Name: navigation_segment navigation_segment_path_segment_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_path_segment_id_fkey FOREIGN KEY (path_segment_id) REFERENCES design.path_segment(path_segment_id);


--
-- TOC entry 5458 (class 2606 OID 33371)
-- Name: navigation_session navigation_session_event_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_session
    ADD CONSTRAINT navigation_session_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5459 (class 2606 OID 33376)
-- Name: pal_pinger_session pal_pinger_session_event_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.pal_pinger_session
    ADD CONSTRAINT pal_pinger_session_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5460 (class 2606 OID 33381)
-- Name: authority authority_event_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority
    ADD CONSTRAINT authority_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5462 (class 2606 OID 33386)
-- Name: operator_authority operator_authority_authority_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator_authority
    ADD CONSTRAINT operator_authority_authority_id_fkey FOREIGN KEY (authority_id) REFERENCES audit.authority(authority_id);


--
-- TOC entry 5463 (class 2606 OID 33391)
-- Name: operator_authority operator_authority_operator_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator_authority
    ADD CONSTRAINT operator_authority_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES audit.operator(operator_id);


--
-- TOC entry 5461 (class 2606 OID 33396)
-- Name: operator operator_event_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator
    ADD CONSTRAINT operator_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5464 (class 2606 OID 33401)
-- Name: communication communication_event_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5465 (class 2606 OID 33406)
-- Name: communication communication_item_sequence_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_item_sequence_id_fkey FOREIGN KEY (item_sequence_id) REFERENCES design.item_sequence(item_sequence_id);


--
-- TOC entry 5466 (class 2606 OID 33411)
-- Name: communication communication_poi_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5467 (class 2606 OID 33416)
-- Name: communication communication_poi_item_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_poi_item_id_fkey FOREIGN KEY (poi_item_id) REFERENCES design.poi_item(poi_item_id);


--
-- TOC entry 5468 (class 2606 OID 33421)
-- Name: subscription subscription_item_sequence_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_item_sequence_id_fkey FOREIGN KEY (item_sequence_id) REFERENCES design.item_sequence(item_sequence_id);


--
-- TOC entry 5469 (class 2606 OID 33426)
-- Name: subscription subscription_pal_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5470 (class 2606 OID 33431)
-- Name: subscription subscription_poi_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5471 (class 2606 OID 33436)
-- Name: subscription subscription_poi_item_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_item_id_fkey FOREIGN KEY (poi_item_id) REFERENCES design.poi_item(poi_item_id);


--
-- TOC entry 5472 (class 2606 OID 33441)
-- Name: crew crew_event_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew
    ADD CONSTRAINT crew_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5542 (class 2606 OID 36416)
-- Name: crew_invitation crew_invitation_crew_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_invitation
    ADD CONSTRAINT crew_invitation_crew_id_fkey FOREIGN KEY (crew_id) REFERENCES community.crew(crew_id);


--
-- TOC entry 5546 (class 2606 OID 41896)
-- Name: crew_meetup crew_meetup_crew_event_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup
    ADD CONSTRAINT crew_meetup_crew_event_fk FOREIGN KEY (event_id, crew_id) REFERENCES community.crew(event_id, crew_id);


--
-- TOC entry 5547 (class 2606 OID 41906)
-- Name: crew_meetup crew_meetup_organiser_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup
    ADD CONSTRAINT crew_meetup_organiser_fk FOREIGN KEY (organiser_pal_id) REFERENCES community.pal(pal_id) ON DELETE SET NULL;


--
-- TOC entry 5548 (class 2606 OID 41901)
-- Name: crew_meetup crew_meetup_poi_event_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup
    ADD CONSTRAINT crew_meetup_poi_event_fk FOREIGN KEY (event_id, poi_id) REFERENCES design.poi(event_id, poi_id);


--
-- TOC entry 5549 (class 2606 OID 41931)
-- Name: crew_meetup_response crew_meetup_response_meetup_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup_response
    ADD CONSTRAINT crew_meetup_response_meetup_fk FOREIGN KEY (crew_meetup_id) REFERENCES community.crew_meetup(crew_meetup_id) ON DELETE CASCADE;


--
-- TOC entry 5550 (class 2606 OID 41936)
-- Name: crew_meetup_response crew_meetup_response_pal_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_meetup_response
    ADD CONSTRAINT crew_meetup_response_pal_fk FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5473 (class 2606 OID 41830)
-- Name: crew_message crew_message_actor_pal_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_actor_pal_fk FOREIGN KEY (actor_pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5474 (class 2606 OID 41835)
-- Name: crew_message crew_message_affected_pal_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_affected_pal_fk FOREIGN KEY (affected_pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5475 (class 2606 OID 33446)
-- Name: crew_message crew_message_crew_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_crew_id_fkey FOREIGN KEY (crew_id) REFERENCES community.crew(crew_id);


--
-- TOC entry 5476 (class 2606 OID 41946)
-- Name: crew_message crew_message_membership_period_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_membership_period_fk FOREIGN KEY (crew_pal_id, crew_id, pal_id) REFERENCES community.crew_pal(crew_pal_id, crew_id, pal_id) ON DELETE RESTRICT;


--
-- TOC entry 5477 (class 2606 OID 33451)
-- Name: crew_message crew_message_pal_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5478 (class 2606 OID 33456)
-- Name: crew_pal crew_pal_crew_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_crew_id_fkey FOREIGN KEY (crew_id) REFERENCES community.crew(crew_id);


--
-- TOC entry 5479 (class 2606 OID 33461)
-- Name: crew_pal crew_pal_pal_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5543 (class 2606 OID 41865)
-- Name: crew_pick crew_pick_creator_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pick
    ADD CONSTRAINT crew_pick_creator_fk FOREIGN KEY (created_by_pal_id) REFERENCES community.pal(pal_id) ON DELETE SET NULL;


--
-- TOC entry 5544 (class 2606 OID 41855)
-- Name: crew_pick crew_pick_crew_event_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pick
    ADD CONSTRAINT crew_pick_crew_event_fk FOREIGN KEY (event_id, crew_id) REFERENCES community.crew(event_id, crew_id);


--
-- TOC entry 5545 (class 2606 OID 41860)
-- Name: crew_pick crew_pick_poi_event_fk; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pick
    ADD CONSTRAINT crew_pick_poi_event_fk FOREIGN KEY (event_id, poi_id) REFERENCES design.poi(event_id, poi_id);


--
-- TOC entry 5540 (class 2606 OID 33780)
-- Name: event_session event_session_event_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.event_session
    ADD CONSTRAINT event_session_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5541 (class 2606 OID 33775)
-- Name: event_session event_session_pal_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.event_session
    ADD CONSTRAINT event_session_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5480 (class 2606 OID 33466)
-- Name: elevator elevator_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.elevator
    ADD CONSTRAINT elevator_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- TOC entry 5481 (class 2606 OID 33471)
-- Name: escalator escalator_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.escalator
    ADD CONSTRAINT escalator_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- TOC entry 5482 (class 2606 OID 33476)
-- Name: event_beacon event_beacon_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon
    ADD CONSTRAINT event_beacon_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5484 (class 2606 OID 33481)
-- Name: event_beacon_physical event_beacon_physical_event_beacon_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_event_beacon_id_fkey FOREIGN KEY (event_beacon_id) REFERENCES design.event_beacon(event_beacon_id);


--
-- TOC entry 5485 (class 2606 OID 33486)
-- Name: event_beacon_physical event_beacon_physical_physical_beacon_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_physical_beacon_id_fkey FOREIGN KEY (physical_beacon_id) REFERENCES design.physical_beacon(physical_beacon_id);


--
-- TOC entry 5483 (class 2606 OID 33491)
-- Name: event_beacon event_beacon_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon
    ADD CONSTRAINT event_beacon_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5486 (class 2606 OID 33496)
-- Name: event_day event_day_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5487 (class 2606 OID 33501)
-- Name: flight flight_staircase_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_staircase_id_fkey FOREIGN KEY (staircase_id) REFERENCES design.staircase(staircase_id);


--
-- TOC entry 5488 (class 2606 OID 33506)
-- Name: item_sequence item_sequence_event_day_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_event_day_id_fkey FOREIGN KEY (event_day_id) REFERENCES design.event_day(event_day_id);


--
-- TOC entry 5489 (class 2606 OID 33511)
-- Name: item_sequence item_sequence_poi_item_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_poi_item_id_fkey FOREIGN KEY (poi_item_id) REFERENCES design.poi_item(poi_item_id);


--
-- TOC entry 5490 (class 2606 OID 33516)
-- Name: junction junction_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction
    ADD CONSTRAINT junction_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5493 (class 2606 OID 33521)
-- Name: offering_availability offering_availability_offering_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_availability
    ADD CONSTRAINT offering_availability_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES design.offering(offering_id);


--
-- TOC entry 5495 (class 2606 OID 33526)
-- Name: offering_item_allergen offering_item_allergen_allergen_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_allergen
    ADD CONSTRAINT offering_item_allergen_allergen_id_fkey FOREIGN KEY (allergen_id) REFERENCES design.allergen(allergen_id);


--
-- TOC entry 5496 (class 2606 OID 33531)
-- Name: offering_item_allergen offering_item_allergen_offering_item_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_allergen
    ADD CONSTRAINT offering_item_allergen_offering_item_id_fkey FOREIGN KEY (offering_item_id) REFERENCES design.offering_item(offering_item_id);


--
-- TOC entry 5497 (class 2606 OID 33536)
-- Name: offering_item_dietary_attribute offering_item_dietary_attribute_dietary_attribute_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_dietary_attribute
    ADD CONSTRAINT offering_item_dietary_attribute_dietary_attribute_id_fkey FOREIGN KEY (dietary_attribute_id) REFERENCES design.dietary_attribute(dietary_attribute_id);


--
-- TOC entry 5498 (class 2606 OID 33541)
-- Name: offering_item_dietary_attribute offering_item_dietary_attribute_offering_item_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_dietary_attribute
    ADD CONSTRAINT offering_item_dietary_attribute_offering_item_id_fkey FOREIGN KEY (offering_item_id) REFERENCES design.offering_item(offering_item_id);


--
-- TOC entry 5494 (class 2606 OID 33546)
-- Name: offering_item offering_item_offering_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item
    ADD CONSTRAINT offering_item_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES design.offering(offering_id);


--
-- TOC entry 5491 (class 2606 OID 33551)
-- Name: offering offering_offering_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering
    ADD CONSTRAINT offering_offering_type_id_fkey FOREIGN KEY (offering_type_id) REFERENCES design.offering_type(offering_type_id);


--
-- TOC entry 5492 (class 2606 OID 33556)
-- Name: offering offering_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering
    ADD CONSTRAINT offering_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5500 (class 2606 OID 33561)
-- Name: path_connector path_connector_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_connector
    ADD CONSTRAINT path_connector_path_id_fkey FOREIGN KEY (path_id) REFERENCES design.path(path_id);


--
-- TOC entry 5501 (class 2606 OID 33566)
-- Name: path_endpoint path_endpoint_junction_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_junction_id_fkey FOREIGN KEY (junction_id) REFERENCES design.junction(junction_id);


--
-- TOC entry 5502 (class 2606 OID 33571)
-- Name: path_endpoint path_endpoint_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_path_id_fkey FOREIGN KEY (path_id) REFERENCES design.path(path_id);


--
-- TOC entry 5503 (class 2606 OID 33576)
-- Name: path_endpoint path_endpoint_terminus_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_terminus_id_fkey FOREIGN KEY (terminus_id) REFERENCES design.terminus(terminus_id);


--
-- TOC entry 5504 (class 2606 OID 33581)
-- Name: path_endpoint path_endpoint_zone_connector_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_zone_connector_id_fkey FOREIGN KEY (zone_connector_id) REFERENCES design.zone_connector(zone_connector_id);


--
-- TOC entry 5499 (class 2606 OID 33586)
-- Name: path path_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path
    ADD CONSTRAINT path_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5506 (class 2606 OID 33591)
-- Name: path_segment_congestion path_segment_congestion_path_segment_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment_congestion
    ADD CONSTRAINT path_segment_congestion_path_segment_id_fkey FOREIGN KEY (path_segment_id) REFERENCES design.path_segment(path_segment_id);


--
-- TOC entry 5505 (class 2606 OID 33596)
-- Name: path_segment path_segment_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment
    ADD CONSTRAINT path_segment_path_id_fkey FOREIGN KEY (path_id) REFERENCES design.path(path_id);


--
-- TOC entry 5507 (class 2606 OID 33601)
-- Name: poi poi_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5509 (class 2606 OID 33606)
-- Name: poi_item poi_item_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_item
    ADD CONSTRAINT poi_item_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5510 (class 2606 OID 33611)
-- Name: poi_path_connector poi_path_connector_path_connector_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_path_connector
    ADD CONSTRAINT poi_path_connector_path_connector_id_fkey FOREIGN KEY (path_connector_id) REFERENCES design.path_connector(path_connector_id);


--
-- TOC entry 5511 (class 2606 OID 33616)
-- Name: poi_path_connector poi_path_connector_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_path_connector
    ADD CONSTRAINT poi_path_connector_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5508 (class 2606 OID 33621)
-- Name: poi poi_poi_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_poi_type_id_fkey FOREIGN KEY (poi_type_id) REFERENCES design.poi_type(poi_type_id);


--
-- TOC entry 5512 (class 2606 OID 33626)
-- Name: poi_type_capability poi_type_capability_poi_capability_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type_capability
    ADD CONSTRAINT poi_type_capability_poi_capability_id_fkey FOREIGN KEY (poi_capability_id) REFERENCES design.poi_capability(poi_capability_id);


--
-- TOC entry 5513 (class 2606 OID 33631)
-- Name: poi_type_capability poi_type_capability_poi_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type_capability
    ADD CONSTRAINT poi_type_capability_poi_type_id_fkey FOREIGN KEY (poi_type_id) REFERENCES design.poi_type(poi_type_id);


--
-- TOC entry 5514 (class 2606 OID 33636)
-- Name: queue queue_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5515 (class 2606 OID 33641)
-- Name: queue queue_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5518 (class 2606 OID 33646)
-- Name: queue_source_ble queue_source_ble_event_beacon_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_event_beacon_id_fkey FOREIGN KEY (event_beacon_id) REFERENCES design.event_beacon(event_beacon_id);


--
-- TOC entry 5519 (class 2606 OID 33651)
-- Name: queue_source_ble queue_source_ble_queue_source_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_queue_source_id_fkey FOREIGN KEY (queue_source_id) REFERENCES design.queue_source(queue_source_id);


--
-- TOC entry 5516 (class 2606 OID 33656)
-- Name: queue_source queue_source_queue_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source
    ADD CONSTRAINT queue_source_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES design.queue(queue_id);


--
-- TOC entry 5517 (class 2606 OID 33661)
-- Name: queue_source queue_source_queue_source_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source
    ADD CONSTRAINT queue_source_queue_source_type_id_fkey FOREIGN KEY (queue_source_type_id) REFERENCES design.queue_source_type(queue_source_type_id);


--
-- TOC entry 5520 (class 2606 OID 33666)
-- Name: queue_wait_time queue_wait_time_queue_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES design.queue(queue_id);


--
-- TOC entry 5521 (class 2606 OID 33671)
-- Name: queue_wait_time queue_wait_time_queue_source_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_queue_source_id_fkey FOREIGN KEY (queue_source_id) REFERENCES design.queue_source(queue_source_id);


--
-- TOC entry 5522 (class 2606 OID 33676)
-- Name: ramp ramp_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.ramp
    ADD CONSTRAINT ramp_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- TOC entry 5523 (class 2606 OID 33681)
-- Name: staircase staircase_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.staircase
    ADD CONSTRAINT staircase_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- TOC entry 5524 (class 2606 OID 33686)
-- Name: terminus terminus_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.terminus
    ADD CONSTRAINT terminus_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5525 (class 2606 OID 33691)
-- Name: traversal_destination traversal_destination_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_destination
    ADD CONSTRAINT traversal_destination_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- TOC entry 5526 (class 2606 OID 33696)
-- Name: traversal_path traversal_path_path_connector_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path
    ADD CONSTRAINT traversal_path_path_connector_id_fkey FOREIGN KEY (path_connector_id) REFERENCES design.path_connector(path_connector_id);


--
-- TOC entry 5527 (class 2606 OID 33701)
-- Name: traversal_path traversal_path_traversal_destination_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path
    ADD CONSTRAINT traversal_path_traversal_destination_id_fkey FOREIGN KEY (traversal_destination_id) REFERENCES design.traversal_destination(traversal_destination_id);


--
-- TOC entry 5528 (class 2606 OID 33706)
-- Name: weather_forecast weather_forecast_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_forecast
    ADD CONSTRAINT weather_forecast_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5529 (class 2606 OID 33711)
-- Name: weather_update weather_update_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_update
    ADD CONSTRAINT weather_update_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5531 (class 2606 OID 33716)
-- Name: zone_connector zone_connector_zone_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone_connector
    ADD CONSTRAINT zone_connector_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES design.zone(zone_id);


--
-- TOC entry 5530 (class 2606 OID 33721)
-- Name: zone zone_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone
    ADD CONSTRAINT zone_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5532 (class 2606 OID 33726)
-- Name: acknowledgement acknowledgement_delivery_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement
    ADD CONSTRAINT acknowledgement_delivery_id_fkey FOREIGN KEY (delivery_id) REFERENCES messaging.delivery(delivery_id);


--
-- TOC entry 5551 (class 2606 OID 42088)
-- Name: crew_mls_group crew_mls_group_crew_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.crew_mls_group
    ADD CONSTRAINT crew_mls_group_crew_fk FOREIGN KEY (crew_id) REFERENCES community.crew(crew_id) ON DELETE RESTRICT;


--
-- TOC entry 5552 (class 2606 OID 42093)
-- Name: crew_mls_group crew_mls_group_reservation_owner_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.crew_mls_group
    ADD CONSTRAINT crew_mls_group_reservation_owner_fk FOREIGN KEY (reservation_owner_crew_pal_id, crew_id) REFERENCES community.crew_pal(crew_pal_id, crew_id) ON DELETE RESTRICT;


--
-- TOC entry 5553 (class 2606 OID 42150)
-- Name: crew_mls_key_package crew_mls_key_package_membership_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.crew_mls_key_package
    ADD CONSTRAINT crew_mls_key_package_membership_fk FOREIGN KEY (crew_pal_id, crew_id) REFERENCES community.crew_pal(crew_pal_id, crew_id) ON DELETE RESTRICT;


--
-- TOC entry 5533 (class 2606 OID 42120)
-- Name: delivery delivery_crew_membership_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_crew_membership_fk FOREIGN KEY (crew_pal_id, crew_id) REFERENCES community.crew_pal(crew_pal_id, crew_id) ON DELETE RESTRICT;


--
-- TOC entry 5534 (class 2606 OID 42125)
-- Name: delivery delivery_message_crew_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_message_crew_fk FOREIGN KEY (message_id, crew_id) REFERENCES messaging.message(message_id, crew_id) ON DELETE RESTRICT;


--
-- TOC entry 5535 (class 2606 OID 33731)
-- Name: delivery delivery_message_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_message_id_fkey FOREIGN KEY (message_id) REFERENCES messaging.message(message_id);


--
-- TOC entry 5536 (class 2606 OID 33736)
-- Name: delivery delivery_pal_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- TOC entry 5537 (class 2606 OID 42100)
-- Name: message message_crew_event_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_crew_event_fk FOREIGN KEY (event_id, crew_id) REFERENCES community.crew(event_id, crew_id) ON DELETE RESTRICT;


--
-- TOC entry 5538 (class 2606 OID 33741)
-- Name: message message_event_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- TOC entry 5539 (class 2606 OID 42105)
-- Name: message message_sender_crew_pal_fk; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_sender_crew_pal_fk FOREIGN KEY (sender_crew_pal_id, crew_id) REFERENCES community.crew_pal(crew_pal_id, crew_id) ON DELETE RESTRICT;


-- Completed on 2026-10-31 14:50:50 GMT

--
-- PostgreSQL database dump complete
--

\unrestrict BkkRVtSDg7AZeP7ujYoVFQKsZGk4iKPC4RRuDUwoThr1VsYtOnPbIUezafmwcOJ

