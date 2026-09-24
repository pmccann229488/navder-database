--
-- PostgreSQL database dump
--

\restrict 6P9qJexTy5BFlAebF8VfeUWW8KNI6B1x076bkfDEc3xKVWdqt5p6Wa4sWRNM9sA

-- Dumped from database version 18.6 (Homebrew)
-- Dumped by pg_dump version 18.6 (Homebrew)

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
-- Name: activity; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA activity;


--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: communications; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA communications;


--
-- Name: community; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA community;


--
-- Name: content; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA content;


--
-- Name: design; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA design;


--
-- Name: intelligence; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA intelligence;


--
-- Name: messaging; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA messaging;


--
-- Name: operations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA operations;


--
-- Name: survey; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA survey;


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
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
-- Name: assistance_request_assistance_request_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.assistance_request_assistance_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assistance_request_assistance_request_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.assistance_request_assistance_request_id_seq OWNED BY activity.assistance_request.assistance_request_id;


--
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
-- Name: navigation_event_navigation_event_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.navigation_event_navigation_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: navigation_event_navigation_event_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.navigation_event_navigation_event_id_seq OWNED BY activity.navigation_event.navigation_event_id;


--
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
-- Name: navigation_segment_navigation_segment_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.navigation_segment_navigation_segment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: navigation_segment_navigation_segment_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.navigation_segment_navigation_segment_id_seq OWNED BY activity.navigation_segment.navigation_segment_id;


--
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
-- Name: navigation_session_navigation_session_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.navigation_session_navigation_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: navigation_session_navigation_session_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.navigation_session_navigation_session_id_seq OWNED BY activity.navigation_session.navigation_session_id;


--
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
-- Name: pal_pinger_session_pal_pinger_session_id_seq; Type: SEQUENCE; Schema: activity; Owner: -
--

CREATE SEQUENCE activity.pal_pinger_session_pal_pinger_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pal_pinger_session_pal_pinger_session_id_seq; Type: SEQUENCE OWNED BY; Schema: activity; Owner: -
--

ALTER SEQUENCE activity.pal_pinger_session_pal_pinger_session_id_seq OWNED BY activity.pal_pinger_session.pal_pinger_session_id;


--
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
-- Name: authority_authority_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.authority_authority_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authority_authority_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.authority_authority_id_seq OWNED BY audit.authority.authority_id;


--
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
-- Name: event_audit_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.event_audit_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_audit_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.event_audit_event_id_seq OWNED BY audit.event.audit_event_id;


--
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
-- Name: operator_authority; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.operator_authority (
    operator_id bigint NOT NULL,
    authority_id bigint NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: operator_operator_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.operator_operator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_operator_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.operator_operator_id_seq OWNED BY audit.operator.operator_id;


--
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
-- Name: communication_communication_id_seq; Type: SEQUENCE; Schema: communications; Owner: -
--

CREATE SEQUENCE communications.communication_communication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: communication_communication_id_seq; Type: SEQUENCE OWNED BY; Schema: communications; Owner: -
--

ALTER SEQUENCE communications.communication_communication_id_seq OWNED BY communications.communication.communication_id;


--
-- Name: subscription; Type: TABLE; Schema: communications; Owner: -
--

CREATE TABLE communications.subscription (
    subscription_id bigint NOT NULL,
    pal_id bigint NOT NULL,
    poi_id bigint,
    poi_item_id bigint,
    subscribed_at timestamp with time zone DEFAULT now() NOT NULL,
    item_sequence_id bigint,
    CONSTRAINT subscription_target_valid CHECK ((((poi_id IS NOT NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NULL) AND (poi_item_id IS NOT NULL) AND (item_sequence_id IS NULL)) OR ((poi_id IS NULL) AND (poi_item_id IS NULL) AND (item_sequence_id IS NOT NULL))))
);


--
-- Name: subscription_subscription_id_seq; Type: SEQUENCE; Schema: communications; Owner: -
--

CREATE SEQUENCE communications.subscription_subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscription_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: communications; Owner: -
--

ALTER SEQUENCE communications.subscription_subscription_id_seq OWNED BY communications.subscription.subscription_id;


--
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
-- Name: crew_crew_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.crew_crew_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crew_crew_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.crew_crew_id_seq OWNED BY community.crew.crew_id;


--
-- Name: crew_message; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_message (
    crew_message_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    pal_id bigint NOT NULL,
    message text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: crew_message_crew_message_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.crew_message_crew_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crew_message_crew_message_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.crew_message_crew_message_id_seq OWNED BY community.crew_message.crew_message_id;


--
-- Name: crew_pal; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.crew_pal (
    crew_pal_id bigint NOT NULL,
    crew_id bigint NOT NULL,
    pal_id bigint NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    left_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    display_name text NOT NULL,
    CONSTRAINT crew_pal_dates_valid CHECK (((left_at IS NULL) OR (left_at > joined_at)))
);


--
-- Name: crew_pal_crew_pal_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.crew_pal_crew_pal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crew_pal_crew_pal_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.crew_pal_crew_pal_id_seq OWNED BY community.crew_pal.crew_pal_id;


--
-- Name: pal; Type: TABLE; Schema: community; Owner: -
--

CREATE TABLE community.pal (
    pal_id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pal_pal_id_seq; Type: SEQUENCE; Schema: community; Owner: -
--

CREATE SEQUENCE community.pal_pal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pal_pal_id_seq; Type: SEQUENCE OWNED BY; Schema: community; Owner: -
--

ALTER SEQUENCE community.pal_pal_id_seq OWNED BY community.pal.pal_id;


--
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
-- Name: allergen_allergen_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.allergen_allergen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allergen_allergen_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.allergen_allergen_id_seq OWNED BY design.allergen.allergen_id;


--
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
-- Name: dietary_attribute_dietary_attribute_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.dietary_attribute_dietary_attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dietary_attribute_dietary_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.dietary_attribute_dietary_attribute_id_seq OWNED BY design.dietary_attribute.dietary_attribute_id;


--
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
-- Name: elevator_elevator_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.elevator_elevator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: elevator_elevator_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.elevator_elevator_id_seq OWNED BY design.elevator.elevator_id;


--
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
-- Name: escalator_escalator_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.escalator_escalator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: escalator_escalator_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.escalator_escalator_id_seq OWNED BY design.escalator.escalator_id;


--
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
    CONSTRAINT event_dates_valid CHECK ((end_at > start_at))
);


--
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
-- Name: event_beacon_event_beacon_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_beacon_event_beacon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_beacon_event_beacon_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_beacon_event_beacon_id_seq OWNED BY design.event_beacon.event_beacon_id;


--
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
-- Name: event_beacon_physical_event_beacon_physical_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_beacon_physical_event_beacon_physical_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_beacon_physical_event_beacon_physical_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_beacon_physical_event_beacon_physical_id_seq OWNED BY design.event_beacon_physical.event_beacon_physical_id;


--
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
-- Name: event_day_event_day_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_day_event_day_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_day_event_day_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_day_event_day_id_seq OWNED BY design.event_day.event_day_id;


--
-- Name: event_event_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.event_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_event_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.event_event_id_seq OWNED BY design.event.event_id;


--
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
-- Name: flight_flight_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.flight_flight_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flight_flight_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.flight_flight_id_seq OWNED BY design.flight.flight_id;


--
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
-- Name: item_sequence_item_sequence_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.item_sequence_item_sequence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_sequence_item_sequence_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.item_sequence_item_sequence_id_seq OWNED BY design.item_sequence.item_sequence_id;


--
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
-- Name: junction_junction_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.junction_junction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: junction_junction_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.junction_junction_id_seq OWNED BY design.junction.junction_id;


--
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
-- Name: offering_availability_offering_availability_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_availability_offering_availability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offering_availability_offering_availability_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_availability_offering_availability_id_seq OWNED BY design.offering_availability.offering_availability_id;


--
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
-- Name: offering_item_allergen; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_item_allergen (
    offering_item_id bigint NOT NULL,
    allergen_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: offering_item_dietary_attribute; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.offering_item_dietary_attribute (
    offering_item_id bigint NOT NULL,
    dietary_attribute_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: offering_item_offering_item_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_item_offering_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offering_item_offering_item_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_item_offering_item_id_seq OWNED BY design.offering_item.offering_item_id;


--
-- Name: offering_offering_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_offering_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offering_offering_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_offering_id_seq OWNED BY design.offering.offering_id;


--
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
-- Name: offering_type_offering_type_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.offering_type_offering_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offering_type_offering_type_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.offering_type_offering_type_id_seq OWNED BY design.offering_type.offering_type_id;


--
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
-- Name: path_connector_path_connector_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_connector_path_connector_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: path_connector_path_connector_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_connector_path_connector_id_seq OWNED BY design.path_connector.path_connector_id;


--
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
-- Name: path_endpoint_path_endpoint_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_endpoint_path_endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: path_endpoint_path_endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_endpoint_path_endpoint_id_seq OWNED BY design.path_endpoint.path_endpoint_id;


--
-- Name: path_path_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_path_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: path_path_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_path_id_seq OWNED BY design.path.path_id;


--
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
-- Name: path_segment_congestion_path_segment_congestion_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_segment_congestion_path_segment_congestion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: path_segment_congestion_path_segment_congestion_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_segment_congestion_path_segment_congestion_id_seq OWNED BY design.path_segment_congestion.path_segment_congestion_id;


--
-- Name: path_segment_path_segment_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.path_segment_path_segment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: path_segment_path_segment_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.path_segment_path_segment_id_seq OWNED BY design.path_segment.path_segment_id;


--
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
-- Name: physical_beacon_physical_beacon_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.physical_beacon_physical_beacon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: physical_beacon_physical_beacon_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.physical_beacon_physical_beacon_id_seq OWNED BY design.physical_beacon.physical_beacon_id;


--
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
-- Name: poi_capability_poi_capability_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_capability_poi_capability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poi_capability_poi_capability_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_capability_poi_capability_id_seq OWNED BY design.poi_capability.poi_capability_id;


--
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
-- Name: poi_item_poi_item_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_item_poi_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poi_item_poi_item_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_item_poi_item_id_seq OWNED BY design.poi_item.poi_item_id;


--
-- Name: poi_path_connector; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_path_connector (
    poi_id bigint NOT NULL,
    path_connector_id bigint NOT NULL,
    is_primary boolean DEFAULT false NOT NULL
);


--
-- Name: poi_poi_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_poi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poi_poi_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_poi_id_seq OWNED BY design.poi.poi_id;


--
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
-- Name: poi_type_capability; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi_type_capability (
    poi_type_id bigint NOT NULL,
    poi_capability_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: poi_type_poi_type_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.poi_type_poi_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: poi_type_poi_type_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.poi_type_poi_type_id_seq OWNED BY design.poi_type.poi_type_id;


--
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
-- Name: queue_queue_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_queue_id_seq OWNED BY design.queue.queue_id;


--
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
-- Name: queue_source_ble_queue_source_ble_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_source_ble_queue_source_ble_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_source_ble_queue_source_ble_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_source_ble_queue_source_ble_id_seq OWNED BY design.queue_source_ble.queue_source_ble_id;


--
-- Name: queue_source_queue_source_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_source_queue_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_source_queue_source_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_source_queue_source_id_seq OWNED BY design.queue_source.queue_source_id;


--
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
-- Name: queue_source_type_queue_source_type_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_source_type_queue_source_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_source_type_queue_source_type_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_source_type_queue_source_type_id_seq OWNED BY design.queue_source_type.queue_source_type_id;


--
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
-- Name: queue_wait_time_queue_wait_time_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.queue_wait_time_queue_wait_time_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queue_wait_time_queue_wait_time_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.queue_wait_time_queue_wait_time_id_seq OWNED BY design.queue_wait_time.queue_wait_time_id;


--
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
-- Name: ramp_ramp_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.ramp_ramp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ramp_ramp_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.ramp_ramp_id_seq OWNED BY design.ramp.ramp_id;


--
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
-- Name: staircase_staircase_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.staircase_staircase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staircase_staircase_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.staircase_staircase_id_seq OWNED BY design.staircase.staircase_id;


--
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
-- Name: terminus_terminus_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.terminus_terminus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: terminus_terminus_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.terminus_terminus_id_seq OWNED BY design.terminus.terminus_id;


--
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
-- Name: traversal_destination_traversal_destination_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.traversal_destination_traversal_destination_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: traversal_destination_traversal_destination_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.traversal_destination_traversal_destination_id_seq OWNED BY design.traversal_destination.traversal_destination_id;


--
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
-- Name: traversal_path_traversal_path_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.traversal_path_traversal_path_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: traversal_path_traversal_path_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.traversal_path_traversal_path_id_seq OWNED BY design.traversal_path.traversal_path_id;


--
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
-- Name: weather_forecast_weather_forecast_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.weather_forecast_weather_forecast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weather_forecast_weather_forecast_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.weather_forecast_weather_forecast_id_seq OWNED BY design.weather_forecast.weather_forecast_id;


--
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
-- Name: weather_update_weather_update_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.weather_update_weather_update_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weather_update_weather_update_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.weather_update_weather_update_id_seq OWNED BY design.weather_update.weather_update_id;


--
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
-- Name: zone_connector_zone_connector_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.zone_connector_zone_connector_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zone_connector_zone_connector_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.zone_connector_zone_connector_id_seq OWNED BY design.zone_connector.zone_connector_id;


--
-- Name: zone_zone_id_seq; Type: SEQUENCE; Schema: design; Owner: -
--

CREATE SEQUENCE design.zone_zone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zone_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: design; Owner: -
--

ALTER SEQUENCE design.zone_zone_id_seq OWNED BY design.zone.zone_id;


--
-- Name: acknowledgement; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.acknowledgement (
    acknowledgement_id bigint NOT NULL,
    delivery_id bigint NOT NULL,
    acknowledged_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: acknowledgement_acknowledgement_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

CREATE SEQUENCE messaging.acknowledgement_acknowledgement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acknowledgement_acknowledgement_id_seq; Type: SEQUENCE OWNED BY; Schema: messaging; Owner: -
--

ALTER SEQUENCE messaging.acknowledgement_acknowledgement_id_seq OWNED BY messaging.acknowledgement.acknowledgement_id;


--
-- Name: delivery; Type: TABLE; Schema: messaging; Owner: -
--

CREATE TABLE messaging.delivery (
    delivery_id bigint NOT NULL,
    message_id bigint NOT NULL,
    pal_id bigint,
    status text DEFAULT 'QUEUED'::text NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    delivered_at timestamp with time zone,
    expires_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_attempt_at timestamp with time zone,
    CONSTRAINT delivery_attempt_count_nonnegative CHECK ((attempt_count >= 0)),
    CONSTRAINT delivery_cancelled_after_queue CHECK (((cancelled_at IS NULL) OR (cancelled_at >= queued_at))),
    CONSTRAINT delivery_delivered_after_queue CHECK (((delivered_at IS NULL) OR (delivered_at >= queued_at))),
    CONSTRAINT delivery_expiry_after_queue CHECK (((expires_at IS NULL) OR (expires_at >= queued_at))),
    CONSTRAINT delivery_status_valid CHECK ((status = ANY (ARRAY['QUEUED'::text, 'DELIVERING'::text, 'DELIVERED'::text, 'EXPIRED'::text, 'CANCELLED'::text])))
);


--
-- Name: delivery_delivery_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

CREATE SEQUENCE messaging.delivery_delivery_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delivery_delivery_id_seq; Type: SEQUENCE OWNED BY; Schema: messaging; Owner: -
--

ALTER SEQUENCE messaging.delivery_delivery_id_seq OWNED BY messaging.delivery.delivery_id;


--
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
    CONSTRAINT message_cancelled_after_creation CHECK (((cancelled_at IS NULL) OR (cancelled_at >= created_at))),
    CONSTRAINT message_expiry_after_creation CHECK (((expires_at IS NULL) OR (expires_at > created_at)))
);


--
-- Name: message_message_id_seq; Type: SEQUENCE; Schema: messaging; Owner: -
--

CREATE SEQUENCE messaging.message_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_message_id_seq; Type: SEQUENCE OWNED BY; Schema: messaging; Owner: -
--

ALTER SEQUENCE messaging.message_message_id_seq OWNED BY messaging.message.message_id;


--
-- Name: assistance_request assistance_request_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.assistance_request ALTER COLUMN assistance_request_id SET DEFAULT nextval('activity.assistance_request_assistance_request_id_seq'::regclass);


--
-- Name: navigation_event navigation_event_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_event ALTER COLUMN navigation_event_id SET DEFAULT nextval('activity.navigation_event_navigation_event_id_seq'::regclass);


--
-- Name: navigation_segment navigation_segment_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment ALTER COLUMN navigation_segment_id SET DEFAULT nextval('activity.navigation_segment_navigation_segment_id_seq'::regclass);


--
-- Name: navigation_session navigation_session_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_session ALTER COLUMN navigation_session_id SET DEFAULT nextval('activity.navigation_session_navigation_session_id_seq'::regclass);


--
-- Name: pal_pinger_session pal_pinger_session_id; Type: DEFAULT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.pal_pinger_session ALTER COLUMN pal_pinger_session_id SET DEFAULT nextval('activity.pal_pinger_session_pal_pinger_session_id_seq'::regclass);


--
-- Name: authority authority_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority ALTER COLUMN authority_id SET DEFAULT nextval('audit.authority_authority_id_seq'::regclass);


--
-- Name: event audit_event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.event ALTER COLUMN audit_event_id SET DEFAULT nextval('audit.event_audit_event_id_seq'::regclass);


--
-- Name: operator operator_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator ALTER COLUMN operator_id SET DEFAULT nextval('audit.operator_operator_id_seq'::regclass);


--
-- Name: communication communication_id; Type: DEFAULT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication ALTER COLUMN communication_id SET DEFAULT nextval('communications.communication_communication_id_seq'::regclass);


--
-- Name: subscription subscription_id; Type: DEFAULT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription ALTER COLUMN subscription_id SET DEFAULT nextval('communications.subscription_subscription_id_seq'::regclass);


--
-- Name: crew crew_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew ALTER COLUMN crew_id SET DEFAULT nextval('community.crew_crew_id_seq'::regclass);


--
-- Name: crew_message crew_message_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message ALTER COLUMN crew_message_id SET DEFAULT nextval('community.crew_message_crew_message_id_seq'::regclass);


--
-- Name: crew_pal crew_pal_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal ALTER COLUMN crew_pal_id SET DEFAULT nextval('community.crew_pal_crew_pal_id_seq'::regclass);


--
-- Name: pal pal_id; Type: DEFAULT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.pal ALTER COLUMN pal_id SET DEFAULT nextval('community.pal_pal_id_seq'::regclass);


--
-- Name: allergen allergen_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen ALTER COLUMN allergen_id SET DEFAULT nextval('design.allergen_allergen_id_seq'::regclass);


--
-- Name: dietary_attribute dietary_attribute_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute ALTER COLUMN dietary_attribute_id SET DEFAULT nextval('design.dietary_attribute_dietary_attribute_id_seq'::regclass);


--
-- Name: elevator elevator_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.elevator ALTER COLUMN elevator_id SET DEFAULT nextval('design.elevator_elevator_id_seq'::regclass);


--
-- Name: escalator escalator_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.escalator ALTER COLUMN escalator_id SET DEFAULT nextval('design.escalator_escalator_id_seq'::regclass);


--
-- Name: event event_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event ALTER COLUMN event_id SET DEFAULT nextval('design.event_event_id_seq'::regclass);


--
-- Name: event_beacon event_beacon_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon ALTER COLUMN event_beacon_id SET DEFAULT nextval('design.event_beacon_event_beacon_id_seq'::regclass);


--
-- Name: event_beacon_physical event_beacon_physical_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical ALTER COLUMN event_beacon_physical_id SET DEFAULT nextval('design.event_beacon_physical_event_beacon_physical_id_seq'::regclass);


--
-- Name: event_day event_day_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day ALTER COLUMN event_day_id SET DEFAULT nextval('design.event_day_event_day_id_seq'::regclass);


--
-- Name: flight flight_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight ALTER COLUMN flight_id SET DEFAULT nextval('design.flight_flight_id_seq'::regclass);


--
-- Name: item_sequence item_sequence_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence ALTER COLUMN item_sequence_id SET DEFAULT nextval('design.item_sequence_item_sequence_id_seq'::regclass);


--
-- Name: junction junction_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction ALTER COLUMN junction_id SET DEFAULT nextval('design.junction_junction_id_seq'::regclass);


--
-- Name: offering offering_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering ALTER COLUMN offering_id SET DEFAULT nextval('design.offering_offering_id_seq'::regclass);


--
-- Name: offering_availability offering_availability_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_availability ALTER COLUMN offering_availability_id SET DEFAULT nextval('design.offering_availability_offering_availability_id_seq'::regclass);


--
-- Name: offering_item offering_item_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item ALTER COLUMN offering_item_id SET DEFAULT nextval('design.offering_item_offering_item_id_seq'::regclass);


--
-- Name: offering_type offering_type_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type ALTER COLUMN offering_type_id SET DEFAULT nextval('design.offering_type_offering_type_id_seq'::regclass);


--
-- Name: path path_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path ALTER COLUMN path_id SET DEFAULT nextval('design.path_path_id_seq'::regclass);


--
-- Name: path_connector path_connector_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_connector ALTER COLUMN path_connector_id SET DEFAULT nextval('design.path_connector_path_connector_id_seq'::regclass);


--
-- Name: path_endpoint path_endpoint_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint ALTER COLUMN path_endpoint_id SET DEFAULT nextval('design.path_endpoint_path_endpoint_id_seq'::regclass);


--
-- Name: path_segment path_segment_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment ALTER COLUMN path_segment_id SET DEFAULT nextval('design.path_segment_path_segment_id_seq'::regclass);


--
-- Name: path_segment_congestion path_segment_congestion_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment_congestion ALTER COLUMN path_segment_congestion_id SET DEFAULT nextval('design.path_segment_congestion_path_segment_congestion_id_seq'::regclass);


--
-- Name: physical_beacon physical_beacon_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon ALTER COLUMN physical_beacon_id SET DEFAULT nextval('design.physical_beacon_physical_beacon_id_seq'::regclass);


--
-- Name: poi poi_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi ALTER COLUMN poi_id SET DEFAULT nextval('design.poi_poi_id_seq'::regclass);


--
-- Name: poi_capability poi_capability_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability ALTER COLUMN poi_capability_id SET DEFAULT nextval('design.poi_capability_poi_capability_id_seq'::regclass);


--
-- Name: poi_item poi_item_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_item ALTER COLUMN poi_item_id SET DEFAULT nextval('design.poi_item_poi_item_id_seq'::regclass);


--
-- Name: poi_type poi_type_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type ALTER COLUMN poi_type_id SET DEFAULT nextval('design.poi_type_poi_type_id_seq'::regclass);


--
-- Name: queue queue_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue ALTER COLUMN queue_id SET DEFAULT nextval('design.queue_queue_id_seq'::regclass);


--
-- Name: queue_source queue_source_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source ALTER COLUMN queue_source_id SET DEFAULT nextval('design.queue_source_queue_source_id_seq'::regclass);


--
-- Name: queue_source_ble queue_source_ble_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble ALTER COLUMN queue_source_ble_id SET DEFAULT nextval('design.queue_source_ble_queue_source_ble_id_seq'::regclass);


--
-- Name: queue_source_type queue_source_type_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type ALTER COLUMN queue_source_type_id SET DEFAULT nextval('design.queue_source_type_queue_source_type_id_seq'::regclass);


--
-- Name: queue_wait_time queue_wait_time_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time ALTER COLUMN queue_wait_time_id SET DEFAULT nextval('design.queue_wait_time_queue_wait_time_id_seq'::regclass);


--
-- Name: ramp ramp_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.ramp ALTER COLUMN ramp_id SET DEFAULT nextval('design.ramp_ramp_id_seq'::regclass);


--
-- Name: staircase staircase_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.staircase ALTER COLUMN staircase_id SET DEFAULT nextval('design.staircase_staircase_id_seq'::regclass);


--
-- Name: terminus terminus_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.terminus ALTER COLUMN terminus_id SET DEFAULT nextval('design.terminus_terminus_id_seq'::regclass);


--
-- Name: traversal_destination traversal_destination_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_destination ALTER COLUMN traversal_destination_id SET DEFAULT nextval('design.traversal_destination_traversal_destination_id_seq'::regclass);


--
-- Name: traversal_path traversal_path_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path ALTER COLUMN traversal_path_id SET DEFAULT nextval('design.traversal_path_traversal_path_id_seq'::regclass);


--
-- Name: weather_forecast weather_forecast_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_forecast ALTER COLUMN weather_forecast_id SET DEFAULT nextval('design.weather_forecast_weather_forecast_id_seq'::regclass);


--
-- Name: weather_update weather_update_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_update ALTER COLUMN weather_update_id SET DEFAULT nextval('design.weather_update_weather_update_id_seq'::regclass);


--
-- Name: zone zone_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone ALTER COLUMN zone_id SET DEFAULT nextval('design.zone_zone_id_seq'::regclass);


--
-- Name: zone_connector zone_connector_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone_connector ALTER COLUMN zone_connector_id SET DEFAULT nextval('design.zone_connector_zone_connector_id_seq'::regclass);


--
-- Name: acknowledgement acknowledgement_id; Type: DEFAULT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement ALTER COLUMN acknowledgement_id SET DEFAULT nextval('messaging.acknowledgement_acknowledgement_id_seq'::regclass);


--
-- Name: delivery delivery_id; Type: DEFAULT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery ALTER COLUMN delivery_id SET DEFAULT nextval('messaging.delivery_delivery_id_seq'::regclass);


--
-- Name: message message_id; Type: DEFAULT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message ALTER COLUMN message_id SET DEFAULT nextval('messaging.message_message_id_seq'::regclass);


--
-- Name: assistance_request assistance_request_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.assistance_request
    ADD CONSTRAINT assistance_request_pkey PRIMARY KEY (assistance_request_id);


--
-- Name: navigation_event navigation_event_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_event
    ADD CONSTRAINT navigation_event_pkey PRIMARY KEY (navigation_event_id);


--
-- Name: navigation_segment navigation_segment_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_pkey PRIMARY KEY (navigation_segment_id);


--
-- Name: navigation_segment navigation_segment_session_sequence_unique; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_session_sequence_unique UNIQUE (navigation_session_id, sequence_no);


--
-- Name: navigation_session navigation_session_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_session
    ADD CONSTRAINT navigation_session_pkey PRIMARY KEY (navigation_session_id);


--
-- Name: pal_pinger_session pal_pinger_session_pkey; Type: CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.pal_pinger_session
    ADD CONSTRAINT pal_pinger_session_pkey PRIMARY KEY (pal_pinger_session_id);


--
-- Name: authority authority_event_name_unique; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority
    ADD CONSTRAINT authority_event_name_unique UNIQUE (event_id, name);


--
-- Name: authority authority_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority
    ADD CONSTRAINT authority_pkey PRIMARY KEY (authority_id);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (audit_event_id);


--
-- Name: operator_authority operator_authority_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator_authority
    ADD CONSTRAINT operator_authority_pkey PRIMARY KEY (operator_id, authority_id);


--
-- Name: operator operator_event_firebase_unique; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator
    ADD CONSTRAINT operator_event_firebase_unique UNIQUE (event_id, firebase_uid);


--
-- Name: operator operator_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator
    ADD CONSTRAINT operator_pkey PRIMARY KEY (operator_id);


--
-- Name: communication communication_pkey; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_pkey PRIMARY KEY (communication_id);


--
-- Name: subscription subscription_item_sequence_unique; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_item_sequence_unique UNIQUE (pal_id, item_sequence_id);


--
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (subscription_id);


--
-- Name: subscription subscription_poi_item_unique; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_item_unique UNIQUE (pal_id, poi_item_id);


--
-- Name: subscription subscription_poi_unique; Type: CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_unique UNIQUE (pal_id, poi_id);


--
-- Name: crew_message crew_message_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_pkey PRIMARY KEY (crew_message_id);


--
-- Name: crew_pal crew_pal_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_pkey PRIMARY KEY (crew_pal_id);


--
-- Name: crew crew_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew
    ADD CONSTRAINT crew_pkey PRIMARY KEY (crew_id);


--
-- Name: pal pal_pkey; Type: CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.pal
    ADD CONSTRAINT pal_pkey PRIMARY KEY (pal_id);


--
-- Name: allergen allergen_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen
    ADD CONSTRAINT allergen_code_unique UNIQUE (code);


--
-- Name: allergen allergen_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen
    ADD CONSTRAINT allergen_name_unique UNIQUE (name);


--
-- Name: allergen allergen_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.allergen
    ADD CONSTRAINT allergen_pkey PRIMARY KEY (allergen_id);


--
-- Name: dietary_attribute dietary_attribute_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute
    ADD CONSTRAINT dietary_attribute_code_unique UNIQUE (code);


--
-- Name: dietary_attribute dietary_attribute_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute
    ADD CONSTRAINT dietary_attribute_name_unique UNIQUE (name);


--
-- Name: dietary_attribute dietary_attribute_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.dietary_attribute
    ADD CONSTRAINT dietary_attribute_pkey PRIMARY KEY (dietary_attribute_id);


--
-- Name: elevator elevator_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.elevator
    ADD CONSTRAINT elevator_pkey PRIMARY KEY (elevator_id);


--
-- Name: escalator escalator_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.escalator
    ADD CONSTRAINT escalator_pkey PRIMARY KEY (escalator_id);


--
-- Name: event_beacon_physical event_beacon_physical_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_pkey PRIMARY KEY (event_beacon_physical_id);


--
-- Name: event_beacon_physical event_beacon_physical_unique_assignment; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_unique_assignment UNIQUE (event_beacon_id, physical_beacon_id);


--
-- Name: event_beacon event_beacon_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon
    ADD CONSTRAINT event_beacon_pkey PRIMARY KEY (event_beacon_id);


--
-- Name: event_day event_day_event_date_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_event_date_unique UNIQUE (event_id, date);


--
-- Name: event_day event_day_event_number_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_event_number_unique UNIQUE (event_id, day_number);


--
-- Name: event_day event_day_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_pkey PRIMARY KEY (event_day_id);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (event_id);


--
-- Name: flight flight_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_pkey PRIMARY KEY (flight_id);


--
-- Name: flight flight_sequence_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_sequence_unique UNIQUE (staircase_id, sequence_no);


--
-- Name: item_sequence item_sequence_event_day_sequence_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_event_day_sequence_unique UNIQUE (event_day_id, sequence_no);


--
-- Name: item_sequence item_sequence_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_pkey PRIMARY KEY (item_sequence_id);


--
-- Name: junction junction_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction
    ADD CONSTRAINT junction_pkey PRIMARY KEY (junction_id);


--
-- Name: offering_availability offering_availability_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_availability
    ADD CONSTRAINT offering_availability_pkey PRIMARY KEY (offering_availability_id);


--
-- Name: offering_item_allergen offering_item_allergen_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_allergen
    ADD CONSTRAINT offering_item_allergen_pkey PRIMARY KEY (offering_item_id, allergen_id);


--
-- Name: offering_item_dietary_attribute offering_item_dietary_attribute_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_dietary_attribute
    ADD CONSTRAINT offering_item_dietary_attribute_pkey PRIMARY KEY (offering_item_id, dietary_attribute_id);


--
-- Name: offering_item offering_item_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item
    ADD CONSTRAINT offering_item_pkey PRIMARY KEY (offering_item_id);


--
-- Name: offering offering_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering
    ADD CONSTRAINT offering_pkey PRIMARY KEY (offering_id);


--
-- Name: offering_type offering_type_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type
    ADD CONSTRAINT offering_type_code_unique UNIQUE (code);


--
-- Name: offering_type offering_type_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type
    ADD CONSTRAINT offering_type_name_unique UNIQUE (name);


--
-- Name: offering_type offering_type_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_type
    ADD CONSTRAINT offering_type_pkey PRIMARY KEY (offering_type_id);


--
-- Name: path_connector path_connector_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_connector
    ADD CONSTRAINT path_connector_pkey PRIMARY KEY (path_connector_id);


--
-- Name: path_endpoint path_endpoint_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_pkey PRIMARY KEY (path_endpoint_id);


--
-- Name: path_endpoint path_endpoint_unique_order; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_unique_order UNIQUE (path_id, endpoint_order);


--
-- Name: path path_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path
    ADD CONSTRAINT path_pkey PRIMARY KEY (path_id);


--
-- Name: path_segment_congestion path_segment_congestion_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment_congestion
    ADD CONSTRAINT path_segment_congestion_pkey PRIMARY KEY (path_segment_congestion_id);


--
-- Name: path_segment path_segment_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment
    ADD CONSTRAINT path_segment_pkey PRIMARY KEY (path_segment_id);


--
-- Name: path_segment path_segment_unique_sequence; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment
    ADD CONSTRAINT path_segment_unique_sequence UNIQUE (path_id, sequence_no);


--
-- Name: physical_beacon physical_beacon_asset_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon
    ADD CONSTRAINT physical_beacon_asset_name_unique UNIQUE (asset_name);


--
-- Name: physical_beacon physical_beacon_ibeacon_identity_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon
    ADD CONSTRAINT physical_beacon_ibeacon_identity_unique UNIQUE (ibeacon_uuid, ibeacon_major, ibeacon_minor);


--
-- Name: physical_beacon physical_beacon_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.physical_beacon
    ADD CONSTRAINT physical_beacon_pkey PRIMARY KEY (physical_beacon_id);


--
-- Name: poi_capability poi_capability_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability
    ADD CONSTRAINT poi_capability_code_unique UNIQUE (code);


--
-- Name: poi_capability poi_capability_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability
    ADD CONSTRAINT poi_capability_name_unique UNIQUE (name);


--
-- Name: poi_capability poi_capability_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_capability
    ADD CONSTRAINT poi_capability_pkey PRIMARY KEY (poi_capability_id);


--
-- Name: poi_item poi_item_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_item
    ADD CONSTRAINT poi_item_pkey PRIMARY KEY (poi_item_id);


--
-- Name: poi_path_connector poi_path_connector_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_path_connector
    ADD CONSTRAINT poi_path_connector_pkey PRIMARY KEY (poi_id, path_connector_id);


--
-- Name: poi poi_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_pkey PRIMARY KEY (poi_id);


--
-- Name: poi_type_capability poi_type_capability_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type_capability
    ADD CONSTRAINT poi_type_capability_pkey PRIMARY KEY (poi_type_id, poi_capability_id);


--
-- Name: poi_type poi_type_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type
    ADD CONSTRAINT poi_type_code_unique UNIQUE (code);


--
-- Name: poi_type poi_type_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type
    ADD CONSTRAINT poi_type_name_unique UNIQUE (name);


--
-- Name: poi_type poi_type_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type
    ADD CONSTRAINT poi_type_pkey PRIMARY KEY (poi_type_id);


--
-- Name: queue queue_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_pkey PRIMARY KEY (queue_id);


--
-- Name: queue_source_ble queue_source_ble_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_pkey PRIMARY KEY (queue_source_ble_id);


--
-- Name: queue_source_ble queue_source_ble_source_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_source_unique UNIQUE (queue_source_id);


--
-- Name: queue_source queue_source_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source
    ADD CONSTRAINT queue_source_pkey PRIMARY KEY (queue_source_id);


--
-- Name: queue_source_type queue_source_type_code_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type
    ADD CONSTRAINT queue_source_type_code_unique UNIQUE (code);


--
-- Name: queue_source_type queue_source_type_name_unique; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type
    ADD CONSTRAINT queue_source_type_name_unique UNIQUE (name);


--
-- Name: queue_source_type queue_source_type_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_type
    ADD CONSTRAINT queue_source_type_pkey PRIMARY KEY (queue_source_type_id);


--
-- Name: queue_wait_time queue_wait_time_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_pkey PRIMARY KEY (queue_wait_time_id);


--
-- Name: ramp ramp_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.ramp
    ADD CONSTRAINT ramp_pkey PRIMARY KEY (ramp_id);


--
-- Name: staircase staircase_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.staircase
    ADD CONSTRAINT staircase_pkey PRIMARY KEY (staircase_id);


--
-- Name: terminus terminus_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.terminus
    ADD CONSTRAINT terminus_pkey PRIMARY KEY (terminus_id);


--
-- Name: traversal_destination traversal_destination_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_destination
    ADD CONSTRAINT traversal_destination_pkey PRIMARY KEY (traversal_destination_id);


--
-- Name: traversal_path traversal_path_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path
    ADD CONSTRAINT traversal_path_pkey PRIMARY KEY (traversal_path_id);


--
-- Name: weather_forecast weather_forecast_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_forecast
    ADD CONSTRAINT weather_forecast_pkey PRIMARY KEY (weather_forecast_id);


--
-- Name: weather_update weather_update_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_update
    ADD CONSTRAINT weather_update_pkey PRIMARY KEY (weather_update_id);


--
-- Name: zone_connector zone_connector_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone_connector
    ADD CONSTRAINT zone_connector_pkey PRIMARY KEY (zone_connector_id);


--
-- Name: zone zone_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone
    ADD CONSTRAINT zone_pkey PRIMARY KEY (zone_id);


--
-- Name: acknowledgement acknowledgement_delivery_unique; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement
    ADD CONSTRAINT acknowledgement_delivery_unique UNIQUE (delivery_id);


--
-- Name: acknowledgement acknowledgement_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement
    ADD CONSTRAINT acknowledgement_pkey PRIMARY KEY (acknowledgement_id);


--
-- Name: delivery delivery_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_pkey PRIMARY KEY (delivery_id);


--
-- Name: message message_pkey; Type: CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (message_id);


--
-- Name: crew_pal_one_active_per_pal; Type: INDEX; Schema: community; Owner: -
--

CREATE UNIQUE INDEX crew_pal_one_active_per_pal ON community.crew_pal USING btree (pal_id) WHERE (left_at IS NULL);


--
-- Name: event_beacon_one_primary; Type: INDEX; Schema: design; Owner: -
--

CREATE UNIQUE INDEX event_beacon_one_primary ON design.event_beacon_physical USING btree (event_beacon_id) WHERE (role = 'PRIMARY'::text);


--
-- Name: assistance_request assistance_request_event_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.assistance_request
    ADD CONSTRAINT assistance_request_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: navigation_event navigation_event_navigation_session_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_event
    ADD CONSTRAINT navigation_event_navigation_session_id_fkey FOREIGN KEY (navigation_session_id) REFERENCES activity.navigation_session(navigation_session_id);


--
-- Name: navigation_segment navigation_segment_navigation_session_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_navigation_session_id_fkey FOREIGN KEY (navigation_session_id) REFERENCES activity.navigation_session(navigation_session_id);


--
-- Name: navigation_segment navigation_segment_path_segment_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_segment
    ADD CONSTRAINT navigation_segment_path_segment_id_fkey FOREIGN KEY (path_segment_id) REFERENCES design.path_segment(path_segment_id);


--
-- Name: navigation_session navigation_session_event_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.navigation_session
    ADD CONSTRAINT navigation_session_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: pal_pinger_session pal_pinger_session_event_id_fkey; Type: FK CONSTRAINT; Schema: activity; Owner: -
--

ALTER TABLE ONLY activity.pal_pinger_session
    ADD CONSTRAINT pal_pinger_session_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: authority authority_event_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.authority
    ADD CONSTRAINT authority_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: operator_authority operator_authority_authority_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator_authority
    ADD CONSTRAINT operator_authority_authority_id_fkey FOREIGN KEY (authority_id) REFERENCES audit.authority(authority_id);


--
-- Name: operator_authority operator_authority_operator_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator_authority
    ADD CONSTRAINT operator_authority_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES audit.operator(operator_id);


--
-- Name: operator operator_event_id_fkey; Type: FK CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.operator
    ADD CONSTRAINT operator_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: communication communication_event_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: communication communication_item_sequence_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_item_sequence_id_fkey FOREIGN KEY (item_sequence_id) REFERENCES design.item_sequence(item_sequence_id);


--
-- Name: communication communication_poi_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: communication communication_poi_item_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.communication
    ADD CONSTRAINT communication_poi_item_id_fkey FOREIGN KEY (poi_item_id) REFERENCES design.poi_item(poi_item_id);


--
-- Name: subscription subscription_item_sequence_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_item_sequence_id_fkey FOREIGN KEY (item_sequence_id) REFERENCES design.item_sequence(item_sequence_id);


--
-- Name: subscription subscription_pal_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- Name: subscription subscription_poi_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: subscription subscription_poi_item_id_fkey; Type: FK CONSTRAINT; Schema: communications; Owner: -
--

ALTER TABLE ONLY communications.subscription
    ADD CONSTRAINT subscription_poi_item_id_fkey FOREIGN KEY (poi_item_id) REFERENCES design.poi_item(poi_item_id);


--
-- Name: crew crew_event_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew
    ADD CONSTRAINT crew_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: crew_message crew_message_crew_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_crew_id_fkey FOREIGN KEY (crew_id) REFERENCES community.crew(crew_id);


--
-- Name: crew_message crew_message_pal_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_message
    ADD CONSTRAINT crew_message_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- Name: crew_pal crew_pal_crew_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_crew_id_fkey FOREIGN KEY (crew_id) REFERENCES community.crew(crew_id);


--
-- Name: crew_pal crew_pal_pal_id_fkey; Type: FK CONSTRAINT; Schema: community; Owner: -
--

ALTER TABLE ONLY community.crew_pal
    ADD CONSTRAINT crew_pal_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- Name: elevator elevator_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.elevator
    ADD CONSTRAINT elevator_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- Name: escalator escalator_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.escalator
    ADD CONSTRAINT escalator_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- Name: event_beacon event_beacon_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon
    ADD CONSTRAINT event_beacon_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: event_beacon_physical event_beacon_physical_event_beacon_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_event_beacon_id_fkey FOREIGN KEY (event_beacon_id) REFERENCES design.event_beacon(event_beacon_id);


--
-- Name: event_beacon_physical event_beacon_physical_physical_beacon_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon_physical
    ADD CONSTRAINT event_beacon_physical_physical_beacon_id_fkey FOREIGN KEY (physical_beacon_id) REFERENCES design.physical_beacon(physical_beacon_id);


--
-- Name: event_beacon event_beacon_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_beacon
    ADD CONSTRAINT event_beacon_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: event_day event_day_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.event_day
    ADD CONSTRAINT event_day_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: flight flight_staircase_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_staircase_id_fkey FOREIGN KEY (staircase_id) REFERENCES design.staircase(staircase_id);


--
-- Name: item_sequence item_sequence_event_day_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_event_day_id_fkey FOREIGN KEY (event_day_id) REFERENCES design.event_day(event_day_id);


--
-- Name: item_sequence item_sequence_poi_item_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.item_sequence
    ADD CONSTRAINT item_sequence_poi_item_id_fkey FOREIGN KEY (poi_item_id) REFERENCES design.poi_item(poi_item_id);


--
-- Name: junction junction_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction
    ADD CONSTRAINT junction_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: offering_availability offering_availability_offering_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_availability
    ADD CONSTRAINT offering_availability_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES design.offering(offering_id);


--
-- Name: offering_item_allergen offering_item_allergen_allergen_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_allergen
    ADD CONSTRAINT offering_item_allergen_allergen_id_fkey FOREIGN KEY (allergen_id) REFERENCES design.allergen(allergen_id);


--
-- Name: offering_item_allergen offering_item_allergen_offering_item_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_allergen
    ADD CONSTRAINT offering_item_allergen_offering_item_id_fkey FOREIGN KEY (offering_item_id) REFERENCES design.offering_item(offering_item_id);


--
-- Name: offering_item_dietary_attribute offering_item_dietary_attribute_dietary_attribute_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_dietary_attribute
    ADD CONSTRAINT offering_item_dietary_attribute_dietary_attribute_id_fkey FOREIGN KEY (dietary_attribute_id) REFERENCES design.dietary_attribute(dietary_attribute_id);


--
-- Name: offering_item_dietary_attribute offering_item_dietary_attribute_offering_item_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item_dietary_attribute
    ADD CONSTRAINT offering_item_dietary_attribute_offering_item_id_fkey FOREIGN KEY (offering_item_id) REFERENCES design.offering_item(offering_item_id);


--
-- Name: offering_item offering_item_offering_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering_item
    ADD CONSTRAINT offering_item_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES design.offering(offering_id);


--
-- Name: offering offering_offering_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering
    ADD CONSTRAINT offering_offering_type_id_fkey FOREIGN KEY (offering_type_id) REFERENCES design.offering_type(offering_type_id);


--
-- Name: offering offering_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.offering
    ADD CONSTRAINT offering_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: path_connector path_connector_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_connector
    ADD CONSTRAINT path_connector_path_id_fkey FOREIGN KEY (path_id) REFERENCES design.path(path_id);


--
-- Name: path_endpoint path_endpoint_junction_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_junction_id_fkey FOREIGN KEY (junction_id) REFERENCES design.junction(junction_id);


--
-- Name: path_endpoint path_endpoint_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_path_id_fkey FOREIGN KEY (path_id) REFERENCES design.path(path_id);


--
-- Name: path_endpoint path_endpoint_terminus_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_terminus_id_fkey FOREIGN KEY (terminus_id) REFERENCES design.terminus(terminus_id);


--
-- Name: path_endpoint path_endpoint_zone_connector_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_endpoint
    ADD CONSTRAINT path_endpoint_zone_connector_id_fkey FOREIGN KEY (zone_connector_id) REFERENCES design.zone_connector(zone_connector_id);


--
-- Name: path path_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path
    ADD CONSTRAINT path_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: path_segment_congestion path_segment_congestion_path_segment_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment_congestion
    ADD CONSTRAINT path_segment_congestion_path_segment_id_fkey FOREIGN KEY (path_segment_id) REFERENCES design.path_segment(path_segment_id);


--
-- Name: path_segment path_segment_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.path_segment
    ADD CONSTRAINT path_segment_path_id_fkey FOREIGN KEY (path_id) REFERENCES design.path(path_id);


--
-- Name: poi poi_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: poi_item poi_item_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_item
    ADD CONSTRAINT poi_item_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: poi_path_connector poi_path_connector_path_connector_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_path_connector
    ADD CONSTRAINT poi_path_connector_path_connector_id_fkey FOREIGN KEY (path_connector_id) REFERENCES design.path_connector(path_connector_id);


--
-- Name: poi_path_connector poi_path_connector_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_path_connector
    ADD CONSTRAINT poi_path_connector_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: poi poi_poi_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi
    ADD CONSTRAINT poi_poi_type_id_fkey FOREIGN KEY (poi_type_id) REFERENCES design.poi_type(poi_type_id);


--
-- Name: poi_type_capability poi_type_capability_poi_capability_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type_capability
    ADD CONSTRAINT poi_type_capability_poi_capability_id_fkey FOREIGN KEY (poi_capability_id) REFERENCES design.poi_capability(poi_capability_id);


--
-- Name: poi_type_capability poi_type_capability_poi_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi_type_capability
    ADD CONSTRAINT poi_type_capability_poi_type_id_fkey FOREIGN KEY (poi_type_id) REFERENCES design.poi_type(poi_type_id);


--
-- Name: queue queue_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: queue queue_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: queue_source_ble queue_source_ble_event_beacon_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_event_beacon_id_fkey FOREIGN KEY (event_beacon_id) REFERENCES design.event_beacon(event_beacon_id);


--
-- Name: queue_source_ble queue_source_ble_queue_source_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source_ble
    ADD CONSTRAINT queue_source_ble_queue_source_id_fkey FOREIGN KEY (queue_source_id) REFERENCES design.queue_source(queue_source_id);


--
-- Name: queue_source queue_source_queue_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source
    ADD CONSTRAINT queue_source_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES design.queue(queue_id);


--
-- Name: queue_source queue_source_queue_source_type_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_source
    ADD CONSTRAINT queue_source_queue_source_type_id_fkey FOREIGN KEY (queue_source_type_id) REFERENCES design.queue_source_type(queue_source_type_id);


--
-- Name: queue_wait_time queue_wait_time_queue_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES design.queue(queue_id);


--
-- Name: queue_wait_time queue_wait_time_queue_source_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_queue_source_id_fkey FOREIGN KEY (queue_source_id) REFERENCES design.queue_source(queue_source_id);


--
-- Name: ramp ramp_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.ramp
    ADD CONSTRAINT ramp_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- Name: staircase staircase_traversal_path_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.staircase
    ADD CONSTRAINT staircase_traversal_path_id_fkey FOREIGN KEY (traversal_path_id) REFERENCES design.traversal_path(traversal_path_id);


--
-- Name: terminus terminus_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.terminus
    ADD CONSTRAINT terminus_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: traversal_destination traversal_destination_poi_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_destination
    ADD CONSTRAINT traversal_destination_poi_id_fkey FOREIGN KEY (poi_id) REFERENCES design.poi(poi_id);


--
-- Name: traversal_path traversal_path_path_connector_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path
    ADD CONSTRAINT traversal_path_path_connector_id_fkey FOREIGN KEY (path_connector_id) REFERENCES design.path_connector(path_connector_id);


--
-- Name: traversal_path traversal_path_traversal_destination_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.traversal_path
    ADD CONSTRAINT traversal_path_traversal_destination_id_fkey FOREIGN KEY (traversal_destination_id) REFERENCES design.traversal_destination(traversal_destination_id);


--
-- Name: weather_forecast weather_forecast_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_forecast
    ADD CONSTRAINT weather_forecast_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: weather_update weather_update_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.weather_update
    ADD CONSTRAINT weather_update_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: zone_connector zone_connector_zone_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone_connector
    ADD CONSTRAINT zone_connector_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES design.zone(zone_id);


--
-- Name: zone zone_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.zone
    ADD CONSTRAINT zone_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: acknowledgement acknowledgement_delivery_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.acknowledgement
    ADD CONSTRAINT acknowledgement_delivery_id_fkey FOREIGN KEY (delivery_id) REFERENCES messaging.delivery(delivery_id);


--
-- Name: delivery delivery_message_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_message_id_fkey FOREIGN KEY (message_id) REFERENCES messaging.message(message_id);


--
-- Name: delivery delivery_pal_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.delivery
    ADD CONSTRAINT delivery_pal_id_fkey FOREIGN KEY (pal_id) REFERENCES community.pal(pal_id);


--
-- Name: message message_event_id_fkey; Type: FK CONSTRAINT; Schema: messaging; Owner: -
--

ALTER TABLE ONLY messaging.message
    ADD CONSTRAINT message_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 6P9qJexTy5BFlAebF8VfeUWW8KNI6B1x076bkfDEc3xKVWdqt5p6Wa4sWRNM9sA

