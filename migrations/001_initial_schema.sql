--
-- PostgreSQL database dump
--

\restrict 3nShoLVEFyhhpS3NbrDfYr35knjELa4nrOKK5MjWijoVTn1ui5KEf1I0RA1sDbr

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
    CONSTRAINT event_dates_valid CHECK ((end_at > start_at))
);


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
-- Name: junction; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.junction (
    junction_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text,
    geometry public.geometry(Point,4326) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
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
-- Name: poi; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.poi (
    poi_id bigint NOT NULL,
    event_id bigint NOT NULL,
    name text NOT NULL,
    poi_type text NOT NULL,
    description text,
    geometry public.geometry(Point,4326) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


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
-- Name: queue_wait_time; Type: TABLE; Schema: design; Owner: -
--

CREATE TABLE design.queue_wait_time (
    queue_wait_time_id bigint NOT NULL,
    queue_id bigint NOT NULL,
    wait_seconds integer NOT NULL,
    observed_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
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
-- Name: flight flight_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight ALTER COLUMN flight_id SET DEFAULT nextval('design.flight_flight_id_seq'::regclass);


--
-- Name: junction junction_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction ALTER COLUMN junction_id SET DEFAULT nextval('design.junction_junction_id_seq'::regclass);


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
-- Name: poi poi_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.poi ALTER COLUMN poi_id SET DEFAULT nextval('design.poi_poi_id_seq'::regclass);


--
-- Name: queue queue_id; Type: DEFAULT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue ALTER COLUMN queue_id SET DEFAULT nextval('design.queue_queue_id_seq'::regclass);


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
-- Name: junction junction_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction
    ADD CONSTRAINT junction_pkey PRIMARY KEY (junction_id);


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
-- Name: queue queue_pkey; Type: CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_pkey PRIMARY KEY (queue_id);


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
-- Name: crew_pal_one_active_per_pal; Type: INDEX; Schema: community; Owner: -
--

CREATE UNIQUE INDEX crew_pal_one_active_per_pal ON community.crew_pal USING btree (pal_id) WHERE (left_at IS NULL);


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
-- Name: flight flight_staircase_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.flight
    ADD CONSTRAINT flight_staircase_id_fkey FOREIGN KEY (staircase_id) REFERENCES design.staircase(staircase_id);


--
-- Name: junction junction_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.junction
    ADD CONSTRAINT junction_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


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
-- Name: queue queue_event_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue
    ADD CONSTRAINT queue_event_id_fkey FOREIGN KEY (event_id) REFERENCES design.event(event_id);


--
-- Name: queue_wait_time queue_wait_time_queue_id_fkey; Type: FK CONSTRAINT; Schema: design; Owner: -
--

ALTER TABLE ONLY design.queue_wait_time
    ADD CONSTRAINT queue_wait_time_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES design.queue(queue_id);


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
-- PostgreSQL database dump complete
--

\unrestrict 3nShoLVEFyhhpS3NbrDfYr35knjELa4nrOKK5MjWijoVTn1ui5KEf1I0RA1sDbr

