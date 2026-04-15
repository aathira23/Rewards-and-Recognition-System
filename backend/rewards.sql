--
-- PostgreSQL database dump
--

\restrict mw8uZbTtQaL5yzY5Yk2bsSPny4WRtLmh3PNbccpRkVsib2fQQpM0CjEQg640SKE

-- Dumped from database version 18.1 (Ubuntu 18.1-1.pgdg22.04+2)
-- Dumped by pg_dump version 18.1 (Ubuntu 18.1-1.pgdg22.04+2)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: award_approvals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.award_approvals (
    id bigint NOT NULL,
    award_id bigint NOT NULL,
    approver_id bigint NOT NULL,
    approval_level character varying NOT NULL,
    status character varying NOT NULL,
    comments text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.award_approvals OWNER TO postgres;

--
-- Name: award_approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.award_approvals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.award_approvals_id_seq OWNER TO postgres;

--
-- Name: award_approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.award_approvals_id_seq OWNED BY public.award_approvals.id;


--
-- Name: award_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.award_types (
    id bigint NOT NULL,
    award_key character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    points integer NOT NULL,
    frequency character varying NOT NULL,
    eligibility_rule character varying NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    approval_workflow character varying
);


ALTER TABLE public.award_types OWNER TO postgres;

--
-- Name: award_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.award_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.award_types_id_seq OWNER TO postgres;

--
-- Name: award_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.award_types_id_seq OWNED BY public.award_types.id;


--
-- Name: awards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.awards (
    id bigint NOT NULL,
    nominee_id bigint NOT NULL,
    nominator_id bigint NOT NULL,
    award_type_id bigint NOT NULL,
    status character varying NOT NULL,
    points_awarded integer,
    created_at timestamp with time zone DEFAULT now(),
    citation text,
    next_required_level character varying,
    persona_type character varying(20),
    persona_label character varying(120)
);


ALTER TABLE public.awards OWNER TO postgres;

--
-- Name: awards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.awards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.awards_id_seq OWNER TO postgres;

--
-- Name: awards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.awards_id_seq OWNED BY public.awards.id;


--
-- Name: badges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.badges (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying,
    icon_url character varying,
    is_active boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    points integer
);


ALTER TABLE public.badges OWNER TO postgres;

--
-- Name: badges_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.badges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.badges_id_seq OWNER TO postgres;

--
-- Name: badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.badges_id_seq OWNED BY public.badges.id;


--
-- Name: celebrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.celebrations (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    celebration_type character varying NOT NULL,
    year integer NOT NULL,
    points_awarded integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.celebrations OWNER TO postgres;

--
-- Name: celebrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.celebrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.celebrations_id_seq OWNER TO postgres;

--
-- Name: celebrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.celebrations_id_seq OWNED BY public.celebrations.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    id bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.departments_id_seq OWNER TO postgres;

--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: ecards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ecards (
    id bigint NOT NULL,
    sender_id bigint NOT NULL,
    badge_id bigint NOT NULL,
    points_awarded integer NOT NULL,
    message text,
    created_at timestamp with time zone DEFAULT now(),
    receiver_id bigint NOT NULL,
    persona_type character varying(20) DEFAULT 'PERSONAL'::character varying NOT NULL,
    persona_label character varying(120)
);


ALTER TABLE public.ecards OWNER TO postgres;

--
-- Name: ecards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ecards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ecards_id_seq OWNER TO postgres;

--
-- Name: ecards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ecards_id_seq OWNED BY public.ecards.id;


--
-- Name: email_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_logs (
    id bigint NOT NULL,
    recipient_email character varying NOT NULL,
    user_id bigint,
    template_key character varying NOT NULL,
    subject character varying NOT NULL,
    body_html text,
    status character varying DEFAULT 'QUEUED'::character varying NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    sent_at timestamp with time zone
);


ALTER TABLE public.email_logs OWNER TO postgres;

--
-- Name: email_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_logs_id_seq OWNER TO postgres;

--
-- Name: email_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_logs_id_seq OWNED BY public.email_logs.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    message text NOT NULL,
    source_type character varying NOT NULL,
    source_id bigint NOT NULL,
    is_read boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: points_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.points_batches (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    points integer NOT NULL,
    remaining_points integer NOT NULL,
    source_type character varying NOT NULL,
    source_id bigint NOT NULL,
    expiry_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.points_batches OWNER TO postgres;

--
-- Name: points_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.points_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.points_batches_id_seq OWNER TO postgres;

--
-- Name: points_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.points_batches_id_seq OWNED BY public.points_batches.id;


--
-- Name: points_conversion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.points_conversion (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    points_converted integer NOT NULL,
    cash_amount numeric(10,2) NOT NULL,
    conversion_type character varying NOT NULL,
    status character varying NOT NULL,
    requested_at timestamp with time zone DEFAULT now(),
    approved_by bigint,
    approved_at timestamp with time zone
);


ALTER TABLE public.points_conversion OWNER TO postgres;

--
-- Name: points_conversion_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.points_conversion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.points_conversion_id_seq OWNER TO postgres;

--
-- Name: points_conversion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.points_conversion_id_seq OWNED BY public.points_conversion.id;


--
-- Name: points_ledger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.points_ledger (
    id bigint NOT NULL,
    source_wallet_id bigint,
    target_wallet_id bigint,
    points integer NOT NULL,
    transaction_type character varying NOT NULL,
    reference_type character varying,
    reference_id bigint,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.points_ledger OWNER TO postgres;

--
-- Name: points_ledger_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.points_ledger_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.points_ledger_id_seq OWNER TO postgres;

--
-- Name: points_ledger_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.points_ledger_id_seq OWNED BY public.points_ledger.id;


--
-- Name: points_policy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.points_policy (
    id bigint NOT NULL,
    recognition_type character varying NOT NULL,
    event_key character varying,
    points integer NOT NULL,
    monthly_limit integer,
    cooldown_days integer,
    conversion_rate numeric(10,2),
    conversion_reward_type character varying,
    is_active boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    cooldown_hours integer,
    consecutive_limit integer
);


ALTER TABLE public.points_policy OWNER TO postgres;

--
-- Name: points_policy_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.points_policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.points_policy_id_seq OWNER TO postgres;

--
-- Name: points_policy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.points_policy_id_seq OWNED BY public.points_policy.id;


--
-- Name: recognition_feed; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recognition_feed (
    id bigint NOT NULL,
    actor_id bigint NOT NULL,
    receiver_id bigint,
    source_type character varying NOT NULL,
    source_id bigint NOT NULL,
    message text,
    created_at timestamp with time zone DEFAULT now(),
    actor_label character varying(120)
);


ALTER TABLE public.recognition_feed OWNER TO postgres;

--
-- Name: recognition_feed_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recognition_feed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recognition_feed_id_seq OWNER TO postgres;

--
-- Name: recognition_feed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recognition_feed_id_seq OWNED BY public.recognition_feed.id;


--
-- Name: redemptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.redemptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    reward_id bigint NOT NULL,
    points_used integer NOT NULL,
    status character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.redemptions OWNER TO postgres;

--
-- Name: redemptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.redemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.redemptions_id_seq OWNER TO postgres;

--
-- Name: redemptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.redemptions_id_seq OWNED BY public.redemptions.id;


--
-- Name: rewards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rewards (
    id bigint NOT NULL,
    name character varying NOT NULL,
    reward_type character varying NOT NULL,
    points_required integer NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    stock integer,
    stock_quantity integer,
    image_url character varying,
    cooldown_hours integer,
    consecutive_limit integer
);


ALTER TABLE public.rewards OWNER TO postgres;

--
-- Name: rewards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rewards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rewards_id_seq OWNER TO postgres;

--
-- Name: rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rewards_id_seq OWNED BY public.rewards.id;


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_config (
    key character varying NOT NULL,
    value text NOT NULL,
    description text,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_config OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    password character varying NOT NULL,
    role character varying NOT NULL,
    department_id bigint,
    manager_id bigint,
    date_of_joining date,
    birth_date date,
    created_at timestamp with time zone DEFAULT now(),
    email_notifications_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: wallet_funding; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallet_funding (
    id bigint NOT NULL,
    manager_wallet_id bigint NOT NULL,
    funded_by bigint NOT NULL,
    points integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.wallet_funding OWNER TO postgres;

--
-- Name: wallet_funding_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wallet_funding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallet_funding_id_seq OWNER TO postgres;

--
-- Name: wallet_funding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wallet_funding_id_seq OWNED BY public.wallet_funding.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    wallet_type character varying NOT NULL,
    balance integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.wallets OWNER TO postgres;

--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallets_id_seq OWNER TO postgres;

--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: award_approvals id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.award_approvals ALTER COLUMN id SET DEFAULT nextval('public.award_approvals_id_seq'::regclass);


--
-- Name: award_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.award_types ALTER COLUMN id SET DEFAULT nextval('public.award_types_id_seq'::regclass);


--
-- Name: awards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.awards ALTER COLUMN id SET DEFAULT nextval('public.awards_id_seq'::regclass);


--
-- Name: badges id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badges ALTER COLUMN id SET DEFAULT nextval('public.badges_id_seq'::regclass);


--
-- Name: celebrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.celebrations ALTER COLUMN id SET DEFAULT nextval('public.celebrations_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: ecards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecards ALTER COLUMN id SET DEFAULT nextval('public.ecards_id_seq'::regclass);


--
-- Name: email_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_logs ALTER COLUMN id SET DEFAULT nextval('public.email_logs_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: points_batches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_batches ALTER COLUMN id SET DEFAULT nextval('public.points_batches_id_seq'::regclass);


--
-- Name: points_conversion id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_conversion ALTER COLUMN id SET DEFAULT nextval('public.points_conversion_id_seq'::regclass);


--
-- Name: points_ledger id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_ledger ALTER COLUMN id SET DEFAULT nextval('public.points_ledger_id_seq'::regclass);


--
-- Name: points_policy id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_policy ALTER COLUMN id SET DEFAULT nextval('public.points_policy_id_seq'::regclass);


--
-- Name: recognition_feed id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recognition_feed ALTER COLUMN id SET DEFAULT nextval('public.recognition_feed_id_seq'::regclass);


--
-- Name: redemptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions ALTER COLUMN id SET DEFAULT nextval('public.redemptions_id_seq'::regclass);


--
-- Name: rewards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards ALTER COLUMN id SET DEFAULT nextval('public.rewards_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wallet_funding id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_funding ALTER COLUMN id SET DEFAULT nextval('public.wallet_funding_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
r20260402_01
\.


--
-- Data for Name: award_approvals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.award_approvals (id, award_id, approver_id, approval_level, status, comments, created_at) FROM stdin;
11	24	4	MANAGER	APPROVED	Auto-approved by MANAGER nominator	2026-02-19 15:06:34.401435+05:30
12	24	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-02-19 15:07:39.827776+05:30
13	24	1	HR	APPROVED	Approved by HR	2026-02-19 15:08:54.712538+05:30
14	25	6	MANAGER	APPROVED	Approved by MANAGER	2026-02-19 15:24:35.8611+05:30
15	25	1	HR	APPROVED	Approved by HR	2026-02-19 15:26:12.982025+05:30
16	27	4	MANAGER	APPROVED	Auto-approved by MANAGER nominator	2026-02-23 11:46:21.405964+05:30
17	27	1	HR	APPROVED	Approved by HR	2026-02-23 12:08:03.597524+05:30
18	28	5	MANAGER	APPROVED	Approved by MANAGER	2026-02-23 16:12:31.628432+05:30
19	28	1	HR	REJECTED	Rejected by HR	2026-02-23 16:13:58.125348+05:30
20	29	5	MANAGER	APPROVED	Approved by MANAGER	2026-02-23 16:18:00.387009+05:30
21	29	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-02-23 16:18:29.784214+05:30
22	29	1	HR	APPROVED	Approved by HR	2026-02-23 16:19:23.359076+05:30
23	30	7	MANAGER	APPROVED	Auto-approved by MANAGER nominator	2026-02-24 11:23:20.640897+05:30
24	31	7	MANAGER	APPROVED	Approved by MANAGER	2026-02-25 11:31:45.070401+05:30
25	32	4	MANAGER	APPROVED	Auto-approved by MANAGER nominator	2026-02-25 14:44:53.784661+05:30
26	31	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-02-25 14:46:35.143815+05:30
27	32	2	DEPT_HEAD	REJECTED	Rejected by DEPT_HEAD	2026-02-25 14:47:49.127279+05:30
28	33	4	MANAGER	APPROVED	deserves it	2026-02-25 15:05:09.725777+05:30
29	33	2	DEPT_HEAD	REJECTED	i dont think an award is needed for that u can give an ecard instead	2026-02-25 15:08:24.813168+05:30
30	31	1	HR	APPROVED	well deserved	2026-02-25 15:13:23.139362+05:30
31	34	4	MANAGER	APPROVED	Approved by MANAGER	2026-02-26 14:39:14.582917+05:30
32	34	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-02-26 14:40:13.369398+05:30
33	34	1	HR	APPROVED	Approved by HR	2026-02-26 14:43:38.817637+05:30
34	35	4	MANAGER	APPROVED	well deserved	2026-03-04 15:18:15.020465+05:30
35	35	2	DEPT_HEAD	APPROVED	great work keep it up	2026-03-04 15:27:45.575773+05:30
36	35	1	HR	APPROVED	great work keep it up 	2026-03-04 15:29:02.78995+05:30
37	36	4	MANAGER	APPROVED	Approved	2026-03-04 16:22:02.824581+05:30
38	36	2	DEPT_HEAD	APPROVED	well deserved	2026-03-05 10:50:14.097594+05:30
39	36	1	HR	APPROVED	great work	2026-03-05 10:51:04.333488+05:30
40	37	4	MANAGER	APPROVED	Auto-approved by MANAGER nominator	2026-03-10 09:41:01.854932+05:30
41	37	1	HR	APPROVED	Approved by HR	2026-03-10 09:41:25.522103+05:30
42	38	4	MANAGER	APPROVED	Approved by MANAGER	2026-03-10 14:04:15.69331+05:30
43	38	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-03-10 14:08:34.241966+05:30
44	38	1	HR	APPROVED	Approved by HR	2026-03-10 14:11:03.70338+05:30
45	39	6	MANAGER	APPROVED	Approved by MANAGER	2026-03-11 12:36:43.029142+05:30
46	39	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-03-11 12:37:03.996504+05:30
47	40	4	MANAGER	APPROVED	Approved by MANAGER	2026-03-11 12:49:33.735385+05:30
48	40	2	DEPT_HEAD	APPROVED	Approved by DEPT_HEAD	2026-03-11 12:50:20.861731+05:30
49	40	1	HR	APPROVED	Approved by HR	2026-03-11 14:19:50.687262+05:30
50	39	1	HR	REJECTED	Rejected	2026-03-11 14:20:56.806646+05:30
51	42	6	MANAGER	APPROVED	deserved	2026-03-26 17:01:35.508008+05:30
52	43	1	DEPT_HEAD	APPROVED	Auto-approved by HR nominator	2026-04-01 15:39:13.377044+05:30
53	43	1	HR	APPROVED	Auto-approved by HR nominator	2026-04-01 15:39:13.377044+05:30
\.


--
-- Data for Name: award_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.award_types (id, award_key, name, description, points, frequency, eligibility_rule, is_active, created_at, approval_workflow) FROM stdin;
13	STAR_PERFORMER	Star Performer	Awarded to the employee who consistently exceeds expectations and delivers outstanding results.	500	MONTHLY	MANAGER_ONLY	t	2026-02-19 14:51:54.519172+05:30	MANAGER,DEPT_HEAD,HR
14	BEST_TEAM_PLAYER	Best Team Player	Recognises an employee who exemplifies collaboration, support, and team spirit.	400	MONTHLY	MANAGER_ONLY	t	2026-02-19 14:51:54.519172+05:30	MANAGER,HR
15	CUSTOMER_CHAMPION	Customer Champion	Awarded to the employee who goes above and beyond to deliver exceptional customer experiences.	400	MONTHLY	MANAGER_ONLY	t	2026-02-19 14:51:54.519172+05:30	MANAGER,HR
16	INNOVATION_AWARD	Innovation Award	Recognises an employee who introduces a creative idea or solution that creates measurable impact.	1000	QUARTERLY	SENIOR_MGMT	t	2026-02-19 14:51:54.519172+05:30	MANAGER,DEPT_HEAD,HR
17	LEADERSHIP_EXCELLENCE	Leadership Excellence	Awarded to a manager or team lead who demonstrates exemplary leadership and people development.	1000	QUARTERLY	SENIOR_MGMT	t	2026-02-19 14:51:54.519172+05:30	DEPT_HEAD,HR
18	RISING_STAR	Rising Star	Recognises a new or junior employee who has shown exceptional growth and potential.	750	QUARTERLY	MANAGER_ONLY	t	2026-02-19 14:51:54.519172+05:30	MANAGER,HR
20	ABOVE_AND_BEYOND	Above and Beyond	Awarded when an employee voluntarily takes on extra responsibility or works outside their scope.	300	ADHOC	PEER	t	2026-02-19 14:51:54.519172+05:30	MANAGER,DEPT_HEAD,HR
19	SPOT_AWARD	Spot Award	An on-the-spot recognition for an employee who demonstrated exceptional effort in a specific situation.	200	ADHOC	MANAGER_ONLY	t	2026-02-19 14:51:54.519172+05:30	MANAGER
21	SPECIAL_ACHIEVEMENT	Special Achievement	For a one-time exceptional achievement such as successfully leading a critical project or milestone.	1500	ADHOC	SENIOR_MGMT	t	2026-02-19 14:51:54.519172+05:30	DEPT_HEAD,HR
22	GREAT	great		400		Managers, Dept Heads & HR (manager-only)	f	2026-03-03 14:54:14.557329+05:30	MANAGER,DEPT_HEAD,HR
\.


--
-- Data for Name: awards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.awards (id, nominee_id, nominator_id, award_type_id, status, points_awarded, created_at, citation, next_required_level, persona_type, persona_label) FROM stdin;
24	9	4	13	APPROVED	500	2026-02-19 15:06:34.401435+05:30	highly appreciate the effort	\N	\N	\N
25	21	9	20	APPROVED	300	2026-02-19 15:18:38.629079+05:30	good	\N	\N	\N
27	9	4	18	APPROVED	750	2026-02-23 11:46:21.405964+05:30	really good performance in the recent project	\N	\N	\N
28	13	21	20	REJECTED	300	2026-02-23 16:11:39.839879+05:30	helped me a lot with the project	\N	\N	\N
29	13	21	20	APPROVED	300	2026-02-23 16:17:30.858805+05:30	helped me a lot	\N	\N	\N
30	24	7	19	APPROVED	200	2026-02-24 11:23:20.640897+05:30	well deserved	\N	\N	\N
32	9	4	13	REJECTED	500	2026-02-25 14:44:53.784661+05:30	the best during our recent project	\N	\N	\N
33	8	9	20	REJECTED	300	2026-02-25 15:04:31.264926+05:30	helped me a lot with the presentation	\N	\N	\N
31	25	9	20	APPROVED	300	2026-02-25 11:30:46.699415+05:30	good	\N	\N	\N
34	9	11	20	APPROVED	300	2026-02-26 14:37:16.319958+05:30	thank u for the help	\N	\N	\N
35	9	12	20	APPROVED	300	2026-03-04 15:02:56.293882+05:30	amazing	\N	\N	\N
36	8	9	20	APPROVED	300	2026-03-04 16:16:48.079916+05:30	testing	\N	\N	\N
37	11	4	14	APPROVED	400	2026-03-10 09:41:01.854932+05:30	continue the good work	\N	\N	\N
38	11	9	20	APPROVED	300	2026-03-10 14:03:16.429168+05:30	thank you	\N	\N	\N
40	9	19	20	APPROVED	300	2026-03-11 12:48:31.588633+05:30	thanks	\N	\N	\N
39	18	9	20	REJECTED	300	2026-03-11 12:34:39.835291+05:30	t	\N	\N	\N
41	1719	1718	20	PENDING	300	2026-03-17 13:09:11.765294+05:30	Testing User Service nomination	\N	\N	\N
42	19	9	20	PENDING	300	2026-03-26 16:58:49.196347+05:30	very good	\N	\N	\N
43	1718	1	17	APPROVED	1000	2026-04-01 15:39:13.377044+05:30	test	\N	\N	\N
44	1713	1718	20	PENDING	300	2026-04-10 16:47:13.737179+05:30	testing styria	\N	MYSELF	Nominate as Myself
\.


--
-- Data for Name: badges; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.badges (id, name, description, icon_url, is_active, created_at, points) FROM stdin;
2	Out of Box Thinker !!!	For creative problem-solving and innovative thinking	https://github.githubassets.com/images/icons/emoji/unicode/1f4a1.png	t	2026-02-19 14:14:08.775089+05:30	75
4	Great Team Player !!!	For outstanding collaboration and team spirit	https://github.githubassets.com/images/icons/emoji/unicode/1f465.png	t	2026-02-19 14:14:08.775089+05:30	60
5	Invaluable Help !!!	For going out of their way to help a colleague	https://github.githubassets.com/images/icons/emoji/unicode/1f64c.png	t	2026-02-19 14:14:08.775089+05:30	50
6	Agility Champion !!!	For adapting quickly and keeping pace in a fast environment	https://github.githubassets.com/images/icons/emoji/unicode/26a1.png	t	2026-02-19 14:14:08.775089+05:30	70
7	Trust Builder !!!	For being someone the team can always rely on	https://github.githubassets.com/images/icons/emoji/unicode/1f6e1.png	t	2026-02-19 14:14:08.775089+05:30	65
8	Partnership Pioneer !!!	For building exceptional relationships with stakeholders	https://github.githubassets.com/images/icons/emoji/unicode/1f91d.png	t	2026-02-19 14:14:08.775089+05:30	80
9	Customer Hero !!!	For delivering outstanding customer or client experience	https://github.githubassets.com/images/icons/emoji/unicode/1f3c6.png	t	2026-02-19 14:14:08.775089+05:30	50
10	Star of Innovation !!!	For pioneering a new idea, tool or process	https://github.githubassets.com/images/icons/emoji/unicode/1f680.png	t	2026-02-19 14:14:08.775089+05:30	50
12	Thank You		\N	f	2026-03-03 17:00:01.230654+05:30	120
1	You Rock !!!	For someone who consistently goes above and beyond	https://github.githubassets.com/images/icons/emoji/unicode/2b50.png	t	2026-02-19 14:14:08.775089+05:30	50
11	Heartfelt Apology !!	For taking accountability and making things right gracefully	https://github.githubassets.com/images/icons/emoji/unicode/1f64f.png	t	2026-02-19 14:14:08.775089+05:30	50
3	Bright Spark !!!	For bringing energy, enthusiasm and fresh ideas to the team	https://github.githubassets.com/images/icons/emoji/unicode/2728.png	t	2026-02-19 14:14:08.775089+05:30	50
\.


--
-- Data for Name: celebrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.celebrations (id, user_id, celebration_type, year, points_awarded, created_at) FROM stdin;
3	5	BIRTHDAY	2026	500	2026-02-27 11:38:03.358864+05:30
4	2	MARRIAGE	2026	1000	2026-03-30 10:53:18.54496+05:30
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (id, name) FROM stdin;
2	Marketing
51	NXT
1	General
\.


--
-- Data for Name: ecards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ecards (id, sender_id, badge_id, points_awarded, message, created_at, receiver_id, persona_type, persona_label) FROM stdin;
42	4	2	75	\N	2026-02-19 14:26:15.141499+05:30	8	PERSONAL	\N
43	9	3	50	\N	2026-02-20 12:41:38.334445+05:30	11	PERSONAL	\N
44	13	5	50	thank u for the help	2026-02-23 16:25:30.929966+05:30	8	PERSONAL	\N
45	4	4	60	\N	2026-02-24 11:41:11.898709+05:30	11	PERSONAL	\N
46	4	2	75	\N	2026-02-24 14:21:18.607125+05:30	9	PERSONAL	\N
47	9	3	50	thank you for your hardwork	2026-02-24 14:37:14.836695+05:30	5	PERSONAL	\N
48	11	10	50	thanks for the idea \n	2026-02-26 12:24:29.341483+05:30	26	PERSONAL	\N
49	11	10	50	thank u for the idea 	2026-02-26 12:26:33.334418+05:30	26	PERSONAL	\N
50	11	5	50	thanks for the help	2026-02-26 12:27:30.719829+05:30	27	PERSONAL	\N
51	20	7	65	it was really valuable 	2026-02-26 12:28:36.607384+05:30	23	PERSONAL	\N
52	11	4	60	thanks	2026-02-26 14:34:12.175701+05:30	20	PERSONAL	\N
53	19	6	70	than for completeing the work so fast 	2026-03-03 10:57:01.468904+05:30	9	PERSONAL	\N
54	19	4	60	thanks for being a good partner 	2026-03-03 10:57:20.48452+05:30	9	PERSONAL	\N
55	19	10	50	what an idea \n	2026-03-03 10:57:33.871164+05:30	9	PERSONAL	\N
56	19	2	75	thank u for the idea 	2026-03-03 10:59:08.537584+05:30	9	PERSONAL	\N
57	20	1	50	thanks for the energy u pass on keep on producing more energy 	2026-03-03 11:19:04.920921+05:30	9	PERSONAL	\N
58	10	4	60	\N	2026-03-03 11:25:10.477694+05:30	9	PERSONAL	\N
59	10	6	70	\N	2026-03-03 11:25:18.020768+05:30	9	PERSONAL	\N
60	10	10	50	\N	2026-03-03 11:25:24.169885+05:30	9	PERSONAL	\N
61	10	1	50	\N	2026-03-03 11:25:30.840007+05:30	9	PERSONAL	\N
62	9	4	60	thank you	2026-03-03 13:08:01.173351+05:30	16	PERSONAL	\N
63	9	6	70	u are the best 	2026-03-03 15:57:25.095678+05:30	22	PERSONAL	\N
64	9	2	75	\N	2026-03-03 16:49:14.808458+05:30	6	PERSONAL	\N
65	9	6	70	thanks for completeing the work so fast 	2026-03-04 14:19:48.627249+05:30	8	PERSONAL	\N
66	9	10	50	thanks for the fantastic idea 	2026-03-04 14:20:21.614945+05:30	10	PERSONAL	\N
67	9	9	50	\N	2026-03-04 14:39:18.50103+05:30	22	PERSONAL	\N
68	9	4	60	thanks	2026-03-04 14:44:35.335165+05:30	25	PERSONAL	\N
69	9	5	50	\N	2026-03-04 16:07:51.076678+05:30	19	PERSONAL	\N
70	9	9	50	well done	2026-03-09 11:11:50.566436+05:30	11	PERSONAL	\N
71	9	3	50	what a great idea 	2026-03-09 22:05:39.215448+05:30	11	PERSONAL	\N
72	9	5	50	thank you	2026-03-10 14:01:13.637063+05:30	11	PERSONAL	\N
73	11	9	50	\N	2026-03-11 12:02:31.473804+05:30	4	PERSONAL	\N
74	12	11	50	\N	2026-03-11 12:09:35.435022+05:30	9	PERSONAL	\N
75	10	8	80	\N	2026-03-11 12:11:43.118858+05:30	24	PERSONAL	\N
76	9	2	75	\N	2026-03-11 13:01:16.728211+05:30	6	PERSONAL	\N
77	9	5	50	\N	2026-03-11 13:01:24.900914+05:30	5	PERSONAL	\N
78	9	4	60	\N	2026-03-11 13:01:32.754083+05:30	21	PERSONAL	\N
79	9	5	50	\N	2026-03-11 13:01:41.389131+05:30	27	PERSONAL	\N
82	1718	1	50	Great work on the project!	2026-03-17 11:46:31.813485+05:30	1719	PERSONAL	\N
83	1718	1	50	Great work on the project!	2026-03-17 11:47:12.908799+05:30	1719	PERSONAL	\N
84	1718	1	50	End-to-end test after FK removal!	2026-03-17 12:23:49.39836+05:30	1719	PERSONAL	\N
85	1718	1	50	Systematic endpoint test!	2026-03-17 12:26:35.624003+05:30	1719	PERSONAL	\N
86	9	3	50	good	2026-03-25 16:44:14.687995+05:30	1718	PERSONAL	\N
87	9	5	50	goood	2026-03-25 16:45:03.316411+05:30	15	PERSONAL	\N
88	1718	4	60	thank you	2026-03-27 12:12:46.674604+05:30	1698	PERSONAL	\N
89	1718	11	50	thanks 	2026-03-27 12:29:17.865181+05:30	1674	PERSONAL	\N
90	1718	4	60	test	2026-03-27 12:31:16.120055+05:30	1719	PERSONAL	\N
91	1718	10	50	test	2026-03-27 17:25:42.872086+05:30	11	PERSONAL	\N
92	1718	3	50	\N	2026-03-30 14:30:21.289971+05:30	1719	PERSONAL	\N
93	1718	6	70	\N	2026-03-30 15:33:43.213754+05:30	1719	PERSONAL	\N
94	1718	6	70	\N	2026-03-30 15:35:46.936193+05:30	1719	PERSONAL	\N
95	1718	10	50		2026-03-31 14:21:45.566066+05:30	1719	PERSONAL	\N
96	1718	6	70		2026-03-31 14:31:04.785424+05:30	1719	PERSONAL	\N
97	1718	3	50		2026-04-01 10:58:04.09861+05:30	1651	PERSONAL	\N
98	2	3	50	test	2026-04-01 17:23:46.75526+05:30	9	DEPARTMENT	General
99	9	9	50		2026-04-01 17:25:01.031045+05:30	1718	PERSONAL	\N
\.


--
-- Data for Name: email_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_logs (id, recipient_email, user_id, template_key, subject, body_html, status, error_message, created_at, sent_at) FROM stdin;
1	jennifer.scott@company.com	\N	recognition_received	Alice Smith recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi ,</p>\n  <p><strong>Alice Smith</strong> recognised you with the <strong>Star Performer</strong> badge.</p>\n  \n  <blockquote style="border-left:4px solid #4f46e5;padding-left:12px;color:#555;margin:16px 0">You did an amazing job on the Q4 report!</blockquote>\n  \n  \n  <p>You received <strong>100 points</strong> for this recognition.</p>\n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@example.com">noreply@example.com</a></p>\n</body>\n</html>	FAILED	[Errno 111] Connection refused	2026-03-04 12:52:24.008642+05:30	\N
2	jennifer.scott@company.com	\N	recognition_received	Alice Smith recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi ,</p>\n  <p><strong>Alice Smith</strong> recognised you with the <strong>Star Performer</strong> badge.</p>\n  \n  <blockquote style="border-left:4px solid #4f46e5;padding-left:12px;color:#555;margin:16px 0">Great job!</blockquote>\n  \n  \n  <p>You received <strong>100 points</strong> for this recognition.</p>\n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@example.com">noreply@example.com</a></p>\n</body>\n</html>	FAILED	[Errno 111] Connection refused	2026-03-04 12:52:39.265139+05:30	\N
3	jennifer.scott@company.com	\N	recognition_received	Alice Smith recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi ,</p>\n  <p><strong>Alice Smith</strong> recognised you with the <strong>Star Performer</strong> badge.</p>\n  \n  <blockquote style="border-left:4px solid #4f46e5;padding-left:12px;color:#555;margin:16px 0">Great job on Q4!</blockquote>\n  \n  \n  <p>You received <strong>100 points</strong> for this recognition.</p>\n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	SENT	\N	2026-03-04 13:38:09.900993+05:30	2026-03-04 13:38:09.916525+05:30
4	jennifer.scott@company.com	\N	recognition_received	Alice Smith recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi ,</p>\n  <p><strong>Alice Smith</strong> recognised you with the <strong>Star Performer</strong> badge.</p>\n  \n  <blockquote style="border-left:4px solid #4f46e5;padding-left:12px;color:#555;margin:16px 0">Great job!</blockquote>\n  \n  \n  <p>You received <strong>100 points</strong> for this recognition.</p>\n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	SENT	\N	2026-03-04 13:38:32.129693+05:30	2026-03-04 13:38:32.135788+05:30
5	jennifer.scott@company.com	\N	recognition_received	Alice Smith recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi Jennifer Scott,</p>\n  <p><strong>Alice Smith</strong> recognised you with the <strong>Star Performer</strong> badge.</p>\n  \n  <blockquote style="border-left:4px solid #4f46e5;padding-left:12px;color:#555;margin:16px 0">Great job on the Q4 report!</blockquote>\n  \n  \n  <p>You received <strong>100 points</strong> for this recognition.</p>\n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	SENT	\N	2026-03-04 13:39:46.826869+05:30	2026-03-04 13:39:46.834272+05:30
6	jennifer.scott@company.com	\N	recognition_received	Alice Chen recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi ,</p>\n  <p><strong>Alice Chen</strong> recognised you with the <strong>Star Performer</strong> badge.</p>\n  \n  <blockquote style="border-left:4px solid #4f46e5;padding-left:12px;color:#555;margin:16px 0">Outstanding work on the Q4 report! Your attention to detail made a huge difference.</blockquote>\n  \n  \n  <p>You received <strong>150 points</strong> for this recognition.</p>\n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	SENT	\N	2026-03-04 13:56:25.484785+05:30	2026-03-04 13:56:25.490836+05:30
7	sophie.williams@company.com	8	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi Sophie Williams,</p>\n  <p><strong>Noah Adams</strong> recognised you with the <strong>Agility Champion !!!</strong> badge.</p>\n  \n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	FAILED	[Errno 111] Connection refused	2026-03-04 14:19:48.675978+05:30	\N
8	isabella.brown@company.com	10	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi Isabella Brown,</p>\n  <p><strong>Noah Adams</strong> recognised you with the <strong>Star of Innovation !!!</strong> badge.</p>\n  \n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	FAILED	[Errno 111] Connection refused	2026-03-04 14:20:21.669739+05:30	\N
9	sophia.bennett@company.com	22	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi Sophia Bennett,</p>\n  <p><strong>Noah Adams</strong> recognised you with the <strong>Customer Hero !!!</strong> badge.</p>\n  \n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	FAILED	[Errno 111] Connection refused	2026-03-04 14:39:18.608874+05:30	\N
10	mason.taylor@company.com	25	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>You've been recognised! 🎉</h2>\n  <p>Hi Mason Taylor,</p>\n  <p><strong>Noah Adams</strong> recognised you with the <strong>Great Team Player !!!</strong> badge.</p>\n  \n  \n  <p><a href="http://localhost:8080/feed" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">View Recognition Feed</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	SENT	\N	2026-03-04 14:44:35.386053+05:30	2026-03-04 14:44:40.304076+05:30
11	michael.thompson@company.com	12	redemption_receipt	Redemption confirmed – Desk Plant	<!DOCTYPE html>\n<html>\n<body style="font-family:sans-serif;color:#333;max-width:600px;margin:auto">\n  <h2>Redemption Confirmed</h2>\n  <p>Hi Michael Thompson,</p>\n  <p>Your redemption of <strong>Desk Plant</strong> has been confirmed.</p>\n  <table style="border-collapse:collapse;width:100%">\n    <tr><td style="padding:8px;border:1px solid #ddd"><strong>Points Used</strong></td><td style="padding:8px;border:1px solid #ddd"></td></tr>\n    <tr><td style="padding:8px;border:1px solid #ddd"><strong>Remaining Balance</strong></td><td style="padding:8px;border:1px solid #ddd"></td></tr>\n  </table>\n  <p><a href="http://localhost:8080/store" style="background:#4f46e5;color:#fff;padding:10px 20px;border-radius:4px;text-decoration:none">Visit Store</a></p>\n  <hr>\n  <p style="font-size:12px;color:#888">Rewards &amp; Recognition System · <a href="mailto:noreply@rnr.local">noreply@rnr.local</a></p>\n</body>\n</html>	SENT	\N	2026-03-04 14:47:48.056876+05:30	2026-03-04 14:47:52.527909+05:30
12	noah.adams@company.com	9	approval_decision	Award decision: 	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award decision – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#fee2e2;color:#7f1d1d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Not Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Award Decision: </h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your nomination for <strong></strong> was not approved this time.</p><p style="margin:22px 0 0"><a href="http://localhost:8080/awards" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">View Awards</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080/settings/notifications" style="color:#6366f1;text-decoration:none">Notification settings</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-04 15:02:56.331305+05:30	2026-03-04 15:03:01.157212+05:30
13	mia.lewis@company.com	19	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Mia Lewis</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Invaluable Help !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-04 16:07:51.137278+05:30	2026-03-04 16:07:56.944787+05:30
14	sophie.williams@company.com	8	nomination_submitted	Award Nomination Submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Sophie Williams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Above and Beyond Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Noah Adams</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-04 16:16:48.103638+05:30	2026-03-04 16:16:52.90646+05:30
15	sophie.williams@company.com	8	award_decision	Above and Beyond Award – Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Above and Beyond Award – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Above and Beyond Award: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Sophie Williams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Great news &#8212; your <strong>Above and Beyond Award</strong> has been <strong style="color:#166534">approved</strong>!</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;text-align:center;margin:16px 0"><p style="margin:0 0 2px;font-size:30px;font-weight:700;color:#166534">+300</p><p style="margin:0;font-size:12px;color:#15803d;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Awarded</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Jennifer Scott</div></div></div><div style="background:#f8f9fa;border-left:4px solid #4f46e5;padding:12px 16px;border-radius:0 6px 6px 0;margin:14px 0"><p style="margin:0;font-size:14px;color:#374151"><strong>Reviewer note:</strong> great work</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-05 10:51:04.385876+05:30	2026-03-05 10:51:09.521033+05:30
16	liam.johnson@company.com	11	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Customer Hero !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;well done&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-09 11:11:50.614741+05:30	2026-03-09 11:11:55.095488+05:30
17	liam.johnson@company.com	11	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Bright Spark !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;what a great idea &#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-09 22:05:39.281862+05:30	2026-03-09 22:05:44.21755+05:30
18	liam.johnson@company.com	11	nomination_submitted	Award Nomination Submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Best Team Player Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Best Team Player Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">David Chen</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-10 09:41:01.890602+05:30	2026-03-10 09:41:07.34573+05:30
19	liam.johnson@company.com	11	award_decision	Best Team Player Award – Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Best Team Player Award – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Best Team Player Award: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Great news &#8212; your <strong>Best Team Player Award</strong> has been <strong style="color:#166534">approved</strong>!</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;text-align:center;margin:16px 0"><p style="margin:0 0 2px;font-size:30px;font-weight:700;color:#166534">+400</p><p style="margin:0;font-size:12px;color:#15803d;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Awarded</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Best Team Player Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Jennifer Scott</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-10 09:41:25.572015+05:30	2026-03-10 09:41:31.093513+05:30
20	liam.johnson@company.com	11	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Invaluable Help !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;thank you&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-10 14:01:13.675718+05:30	2026-03-10 14:01:17.611221+05:30
28	ryan.patel@company.com	6	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Ryan Patel</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Out of Box Thinker !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+75</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 13:01:16.770455+05:30	2026-03-11 13:01:21.648745+05:30
30	charlotte.hall@company.com	21	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Charlotte Hall</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Great Team Player !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+60</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 13:01:32.786093+05:30	2026-03-11 13:01:37.921289+05:30
21	liam.johnson@company.com	11	nomination_submitted	Award Nomination Submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Above and Beyond Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Noah Adams</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-10 14:03:16.452027+05:30	2026-03-10 14:03:20.221786+05:30
22	liam.johnson@company.com	11	award_decision	Above and Beyond Award – Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Above and Beyond Award – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Above and Beyond Award: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Great news &#8212; your <strong>Above and Beyond Award</strong> has been <strong style="color:#166534">approved</strong>!</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;text-align:center;margin:16px 0"><p style="margin:0 0 2px;font-size:30px;font-weight:700;color:#166534">+300</p><p style="margin:0;font-size:12px;color:#15803d;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Awarded</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Jennifer Scott</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-10 14:11:03.747109+05:30	2026-03-10 14:11:07.431172+05:30
23	david.chen@company.com	4	recognition_received	Liam Johnson recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>David Chen</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Liam Johnson</strong> has recognised you with the <strong>Customer Hero !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 12:02:31.530871+05:30	2026-03-11 12:02:36.813541+05:30
24	noah.adams@company.com	9	recognition_received	Michael Thompson recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Michael Thompson</strong> has recognised you with the <strong>Heartfelt Apology !!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 12:09:35.540836+05:30	2026-03-11 12:09:40.356301+05:30
25	chloe.anderson@company.com	24	recognition_received	Isabella Brown recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Chloe Anderson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Isabella Brown</strong> has recognised you with the <strong>Partnership Pioneer !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+80</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 12:11:43.168651+05:30	2026-03-11 12:11:47.743306+05:30
26	ethan.clark@company.com	18	nomination_submitted	Award Nomination Submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Ethan Clark</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Above and Beyond Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Noah Adams</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 12:34:39.862856+05:30	2026-03-11 12:34:44.80787+05:30
27	noah.adams@company.com	9	nomination_submitted	Award Nomination Submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Above and Beyond Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Mia Lewis</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 12:48:31.621454+05:30	2026-03-11 12:48:36.30922+05:30
29	emily.turner@company.com	5	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Emily Turner</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Invaluable Help !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	(550, b'5.7.0 Too many emails per second. Please upgrade your plan https://mailtrap.io/billing/plans/testing')	2026-03-11 13:01:24.932417+05:30	\N
31	henry.jackson@company.com	27	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Henry Jackson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Invaluable Help !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	(550, b'5.7.0 Too many emails per second. Please upgrade your plan https://mailtrap.io/billing/plans/testing')	2026-03-11 13:01:41.422879+05:30	\N
34	noah.adams@company.com	9	award_decision	Above and Beyond Award – Not Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Above and Beyond Award – Not Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#fee2e2;color:#7f1d1d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Not Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Above and Beyond Award: Not Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your <strong>Above and Beyond Award</strong> was not approved this time.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Not Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Jennifer Scott</div></div></div><div style="background:#f8f9fa;border-left:4px solid #4f46e5;padding:12px 16px;border-radius:0 6px 6px 0;margin:14px 0"><p style="margin:0;font-size:14px;color:#374151"><strong>Reviewer note:</strong> Rejected</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	(550, b'5.7.0 Too many emails per second. Please upgrade your plan https://mailtrap.io/billing/plans/testing')	2026-03-11 14:20:56.829884+05:30	\N
32	noah.adams@company.com	9	award_decision	Above and Beyond Award – Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Above and Beyond Award – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Above and Beyond Award: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Great news &#8212; your <strong>Above and Beyond Award</strong> has been <strong style="color:#166534">approved</strong>!</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;text-align:center;margin:16px 0"><p style="margin:0 0 2px;font-size:30px;font-weight:700;color:#166534">+300</p><p style="margin:0;font-size:12px;color:#15803d;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Awarded</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Jennifer Scott</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 14:19:50.723247+05:30	2026-03-11 14:19:56.064267+05:30
33	ethan.clark@company.com	18	award_decision	Above and Beyond Award – Not Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Above and Beyond Award – Not Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#fee2e2;color:#7f1d1d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Not Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Above and Beyond Award: Not Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Ethan Clark</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your <strong>Above and Beyond Award</strong> was not approved this time.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Not Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">HR</div></div></div><div style="background:#f8f9fa;border-left:4px solid #4f46e5;padding:12px 16px;border-radius:0 6px 6px 0;margin:14px 0"><p style="margin:0;font-size:14px;color:#374151"><strong>Reviewer note:</strong> Rejected</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-11 14:20:56.819965+05:30	2026-03-11 14:21:02.215004+05:30
35	noah.adams@company.com	9	conversion_submitted	Points conversion submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points conversion submitted – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Under Review</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion Submitted</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>900</strong> points (&#8776; &#8377;180.0) has been submitted and is pending HR approval.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points to Convert</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>900</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Cash Value</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>&#8377;180.0</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Approval</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">Typical processing time is 1&#8211;3 business days. You&#39;ll receive an email once a decision is made.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-12 14:39:00.562339+05:30	2026-03-12 14:39:06.155507+05:30
36	noah.adams@company.com	9	conversion_decision	Points Conversion – Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points Conversion – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>900 points</strong> has been <strong style="color:#166534">approved</strong>.</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#166534;line-height:1.5">The converted amount will be processed according to your organisation&#39;s policy. You will be notified once the payout is complete.</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Request Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Points Conversion</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>900</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">HR</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-12 15:15:00.904511+05:30	2026-03-12 15:15:07.087775+05:30
37	noah.adams@company.com	9	conversion_submitted	Points conversion submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points conversion submitted – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Under Review</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion Submitted</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>500</strong> points (&#8776; &#8377;100.0) has been submitted and is pending HR approval.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points to Convert</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>500</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Cash Value</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>&#8377;100.0</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Approval</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">Typical processing time is 1&#8211;3 business days. You&#39;ll receive an email once a decision is made.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-25 11:11:38.850722+05:30	2026-03-25 11:11:43.68407+05:30
38	fidaan.hussain@tarento.com	1718	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Bright Spark !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;good&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-25 16:44:14.741066+05:30	2026-03-25 16:44:20.323069+05:30
39	emma.davis@company.com	15	recognition_received	Noah Adams recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Emma Davis</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Noah Adams</strong> has recognised you with the <strong>Invaluable Help !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;goood&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-25 16:45:03.358101+05:30	2026-03-25 16:45:09.488704+05:30
42	rabeeh.cheriya@tarento.com	1698	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Rabeeh c v</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Great Team Player !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;thank you&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+60</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-27 12:12:46.961704+05:30	2026-03-27 12:12:51.596795+05:30
43	abhilash.manikoth@tarento.com	1674	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Abhilash Manikoth</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Heartfelt Apology !!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;thanks &#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-27 12:29:18.144647+05:30	2026-03-27 12:29:22.946801+05:30
40	noah.adams@company.com	9	conversion_submitted	Points conversion submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points conversion submitted – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Under Review</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion Submitted</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>500</strong> points (&#8776; &#8377;100.0) has been submitted and is pending HR approval.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points to Convert</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>500</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Cash Value</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>&#8377;100.0</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Approval</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">Typical processing time is 1&#8211;3 business days. You&#39;ll receive an email once a decision is made.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-25 16:45:53.470067+05:30	2026-03-25 16:45:59.341358+05:30
41	mia.lewis@company.com	19	nomination_submitted	Award Nomination Submitted – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Mia Lewis</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Above and Beyond Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Noah Adams</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-26 16:58:49.224127+05:30	2026-03-26 16:58:54.744095+05:30
44	athira.ambali@tarento.com	1719	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Athira A K</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Great Team Player !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;test&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+60</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-27 12:31:16.362862+05:30	2026-03-27 12:31:20.621614+05:30
45	liam.johnson@company.com	11	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Liam Johnson</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Star of Innovation !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;test&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-27 17:25:42.92327+05:30	2026-03-27 17:25:47.442811+05:30
46	sarah.mitchell@company.com	2	celebration_reminder	Marriage: Sarah Mitchell – Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Marriage – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#f3e8ff;color:#581c87;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Celebration</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Marriage: Sarah Mitchell &#127882;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Sarah Mitchell</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">A celebration is happening! <strong>Sarah Mitchell</strong> is celebrating a <strong>Marriage</strong> on <strong>2026-03-30</strong>.</p><div style="background:#faf5ff;border:1px solid #e9d5ff;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#581c87;line-height:1.5">Take a moment to send a recognition or a kind message to your colleague!</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-30 10:53:18.586797+05:30	2026-03-30 10:53:23.467936+05:30
57	athira.ambali@tarento.com	1719	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Athira A K</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Agility Champion !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+70</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-31 14:31:04.834498+05:30	2026-03-31 14:31:06.969882+05:30
47	noah.adams@company.com	9	conversion_decision	Points Conversion – Rejected	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points Conversion – Rejected</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#fee2e2;color:#7f1d1d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Not Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion: Rejected</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>500 points</strong> was not approved.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Request Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Points Conversion</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>500</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Rejected</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">HR</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-30 11:47:50.66941+05:30	2026-03-30 11:47:55.362944+05:30
48	noah.adams@company.com	9	conversion_decision	Points Conversion – Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points Conversion – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>500 points</strong> has been <strong style="color:#166534">approved</strong>.</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#166534;line-height:1.5">The converted amount will be processed according to your organisation&#39;s policy. You will be notified once the payout is complete.</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Request Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Points Conversion</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>500</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">HR</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	(550, b'5.7.0 Too many emails per second. Please upgrade your plan https://mailtrap.io/billing/plans/testing')	2026-03-30 11:47:52.866396+05:30	\N
49	athira.ambali@tarento.com	1719	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Athira A K</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Bright Spark !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-03-30 14:30:21.346922+05:30	\N
50	athira.ambali@tarento.com	1719	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Athira A K</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Agility Champion !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+70</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	'Settings' object has no attribute 'NOTIFICATION_SERVICE_BASE_URL'	2026-03-30 15:33:43.266319+05:30	\N
51	athira.ambali@tarento.com	1719	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Athira A K</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Agility Champion !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+70</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-30 15:35:47.249894+05:30	2026-03-30 15:35:52.875106+05:30
52	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed – Premium Coffee Gift Set	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Premium Coffee Gift Set</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Premium Coffee Gift Set</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>1500</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>0 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-03-31 10:56:49.826336+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-03-31 10:56:49.848235+05:30	\N
53	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed – Fitness Tracker	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Fitness Tracker</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Fitness Tracker</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>9000</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>41000 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-03-31 11:05:57.336003+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-31 11:05:57.355665+05:30	2026-03-31 11:06:04.477256+05:30
54	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed - Company Hoodie	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Company Hoodie</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Company Hoodie</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>2000</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>39000 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-03-31 11:12:21.694202+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-31 11:12:21.718944+05:30	2026-03-31 11:12:24.082765+05:30
63	noah.adams@company.com	9	recognition_received	General recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Noah Adams</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>General</strong> has recognised you with the <strong>Bright Spark !!!</strong> badge.</p><div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:14px 18px;border-radius:0 8px 8px 0;margin:14px 0"><p style="margin:0;font-size:15px;color:#166534;font-style:italic;line-height:1.6">&#8220;test&#8221;</p></div><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-04-01 17:23:46.792849+05:30	\N
55	fidaan.hussain@tarento.com	1718	conversion_submitted	Points conversion submitted - Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points conversion submitted – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Under Review</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion Submitted</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>1000</strong> points (&#8776; &#8377;200.0) has been submitted and is pending HR approval.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points to Convert</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>1000</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Cash Value</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>&#8377;200.0</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Approval</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">Typical processing time is 1&#8211;3 business days. You&#39;ll receive an email once a decision is made.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-31 11:12:54.014063+05:30	2026-03-31 11:12:56.235432+05:30
56	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed - Desk Plant	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Desk Plant</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Desk Plant</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>800</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>11100 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-03-31 14:30:38.010104+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-31 14:30:38.036347+05:30	2026-03-31 14:30:40.65211+05:30
58	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed - Desk Plant	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Desk Plant</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Desk Plant</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>800</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>10300 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-03-31 17:49:19.698445+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-03-31 17:49:19.718427+05:30	\N
59	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed - Noise-Cancelling Headphones	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Noise-Cancelling Headphones</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Noise-Cancelling Headphones</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>5000</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>5300 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-03-31 17:50:53.560913+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-03-31 17:50:53.576659+05:30	2026-03-31 17:50:55.598897+05:30
60	oiuytrewdfc	1651	recognition_received	Fidaan Hussain P recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>ccddf</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Fidaan Hussain P</strong> has recognised you with the <strong>Bright Spark !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-04-01 10:58:04.385567+05:30	\N
61	fidaan.hussain@tarento.com	1718	conversion_decision	Points Conversion - Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points Conversion – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>1000 points</strong> has been <strong style="color:#166534">approved</strong>.</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#166534;line-height:1.5">The converted amount will be processed according to your organisation&#39;s policy. You will be notified once the payout is complete.</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Request Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Points Conversion</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>1000</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">HR</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-04-01 12:40:19.42661+05:30	\N
62	fidaan.hussain@tarento.com	1718	award_decision	Leadership Excellence Award - Approved	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Leadership Excellence Award – Approved</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Approved</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Leadership Excellence Award: Approved</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Great news &#8212; your <strong>Leadership Excellence Award</strong> has been <strong style="color:#166534">approved</strong>!</p><div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:16px;text-align:center;margin:16px 0"><p style="margin:0 0 2px;font-size:30px;font-weight:700;color:#166534">+1000</p><p style="margin:0;font-size:12px;color:#15803d;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Awarded</p></div><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Type</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Leadership Excellence Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Decision</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Approved</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reviewed By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">HR</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-04-01 15:39:13.604251+05:30	\N
64	fidaan.hussain@tarento.com	1718	recognition_received	Sermandurai Subbiah recognised you!	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>You&#39;ve been recognised – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">You&#39;ve Been Recognised</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve been recognised! &#127942;</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65"><strong>Sermandurai Subbiah</strong> has recognised you with the <strong>Customer Hero !!!</strong> badge.</p><div style="background:#f8faff;border:1px solid #c7d2fe;border-radius:8px;padding:14px 18px;margin:14px 0;text-align:center"><p style="margin:0 0 2px;font-size:28px;font-weight:700;color:#4338ca">+50</p><p style="margin:0;font-size:12px;color:#4f46e5;font-weight:600;text-transform:uppercase;letter-spacing:0.5px">Points Earned</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	FAILED	Notification service returned a failure response	2026-04-01 17:25:01.05659+05:30	\N
65	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed - Desk Plant	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Desk Plant</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Desk Plant</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>800</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>4550 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-04-09 11:40:52.172709+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-04-09 11:40:52.202713+05:30	2026-04-09 11:40:57.912974+05:30
66	fidaan.hussain@tarento.com	1718	conversion_submitted	Points conversion submitted - Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Points conversion submitted – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Under Review</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Points Conversion Submitted</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your request to convert <strong>500</strong> points (&#8776; &#8377;50.0) has been submitted and is pending HR approval.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points to Convert</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>500</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Cash Value</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>&#8377;50.0</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Approval</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">Typical processing time is 1&#8211;3 business days. You&#39;ll receive an email once a decision is made.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@rnr.local" style="color:#6366f1;text-decoration:none">noreply@rnr.local</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-04-09 12:02:19.446118+05:30	2026-04-09 12:02:21.672208+05:30
67	hrishikesh.krishnan@tarento.com	1713	nomination_submitted	Award Nomination Submitted - Rewards &amp; Recognition System	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Award Nomination – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dbeafe;color:#1e3a8a;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Nomination Received</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">You&#39;ve Been Nominated!</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Hrishikesh Krishnan</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">You have been nominated for a <strong>Above and Beyond Award</strong>. Your nomination is now being reviewed by the approvers.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Nomination</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Above and Beyond Award</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Status</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Pending Review</div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Submitted By</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">Nominate as Myself</div></div></div><div style="background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:14px 18px;margin:14px 0"><p style="margin:0;font-size:14px;color:#1e3a8a;line-height:1.5">You will receive another email once a decision has been made. No action is needed from you at this time.</p></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@example.com" style="color:#6366f1;text-decoration:none">noreply@example.com</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-04-10 16:47:14.043121+05:30	2026-04-10 16:47:16.364243+05:30
68	fidaan.hussain@tarento.com	1718	redemption_receipt	Redemption confirmed - Desk Plant	<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width,initial-scale=1.0">\n  <title>Redemption confirmed – Rewards &amp; Recognition System</title>\n</head>\n<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">\n  <div style="background:#f0f2f5;padding:40px 20px">\n    <div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08)">\n\n      <div style="background:linear-gradient(135deg,#4338ca 0%,#6d28d9 100%);padding:26px 40px">\n        <p style="margin:0;color:#ffffff;font-size:21px;font-weight:700;letter-spacing:-0.3px">Rewards &amp; Recognition System</p>\n      </div>\n\n      <div style="padding:0 40px"><span style="display:inline-block;background:#dcfce7;color:#14532d;font-size:11px;font-weight:700;padding:4px 12px;border-radius:0 0 8px 8px;letter-spacing:0.6px;text-transform:uppercase">Redemption Confirmed</span></div>\n\n      <div style="padding:34px 40px 30px">\n        <h2 style="margin:0 0 10px;font-size:20px;font-weight:700;color:#111827">Redemption Confirmed</h2><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Hi <strong>Fidaan Hussain P</strong>,</p><p style="margin:0 0 14px;font-size:15px;color:#374151;line-height:1.65">Your redemption of <strong>Desk Plant</strong> is confirmed and being processed.</p><div style="border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;margin:18px 0"><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Reward</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>Desk Plant</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Points Used</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>800</strong></div></div><div style="display:flex;background:#f8f9fa;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Remaining Balance</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827"><strong>3750 pts</strong></div></div><div style="display:flex;background:#ffffff;border-bottom:1px solid #e5e7eb"><div style="flex:0 0 45%;padding:9px 14px;font-size:13px;font-weight:600;color:#374151;border-right:1px solid #e5e7eb">Date</div><div style="flex:1;padding:9px 14px;font-size:13px;color:#111827">2026-04-10 16:49:24.874162+05:30</div></div></div><p style="margin:22px 0 0"><a href="http://localhost:8080" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:13px 26px;border-radius:6px;text-decoration:none;font-weight:600;font-size:15px;letter-spacing:0.2px">Open Dashboard</a></p>\n      </div>\n\n      <div style="background:#f8f9fa;padding:16px 40px;border-top:1px solid #e9ecef">\n        <p style="margin:0;font-size:12px;color:#9ca3af;text-align:center;line-height:1.6">\n          &copy; Rewards &amp; Recognition System &nbsp;&middot;&nbsp;\n          <a href="mailto:noreply@example.com" style="color:#6366f1;text-decoration:none">noreply@example.com</a>\n          &nbsp;&middot;&nbsp;\n          <a href="http://localhost:8080" style="color:#6366f1;text-decoration:none">Open Dashboard</a>\n        </p>\n      </div>\n\n    </div>\n  </div>\n</body>\n</html>	SENT	\N	2026-04-10 16:49:24.898177+05:30	2026-04-10 16:49:27.125456+05:30
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, message, source_type, source_id, is_read, created_at) FROM stdin;
139	8	David Chen appreciated you with a 'Out of Box Thinker !!!' badge! 75 points earned.	ECARD	42	f	2026-02-19 14:26:15.183854+05:30
143	21	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	25	f	2026-02-19 15:18:38.646486+05:30
144	6	New Award Nomination: Charlotte Hall has been nominated for Above and Beyond.	AWARD	25	f	2026-02-19 15:18:38.657206+05:30
145	21	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	25	f	2026-02-19 15:26:13.021389+05:30
142	9	Congratulations! Your Star Performer award has been fully approved. 500 points awarded!	AWARD	24	t	2026-02-19 15:08:54.741755+05:30
140	9	You have been nominated for a Star Performer award by David Chen!	AWARD	24	t	2026-02-19 15:06:34.423019+05:30
149	1	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	26	t	2026-02-20 16:38:28.655868+05:30
138	9	David Chen appreciated you with a 'Out of Box Thinker !!!' badge! 50 points earned.	ECARD	41	t	2026-02-19 14:17:33.747552+05:30
156	6	You have been allocated 3000 points in your manager budget.	BUDGET	43	f	2026-02-23 12:09:02.762947+05:30
157	7	You have been allocated 3000 points in your manager budget.	BUDGET	44	f	2026-02-23 12:09:02.785022+05:30
150	9	You have been nominated for a Rising Star award by David Chen!	AWARD	27	t	2026-02-23 11:46:21.424095+05:30
152	9	Congratulations! Your Rising Star award has been fully approved. 750 points awarded!	AWARD	27	t	2026-02-23 12:08:03.624748+05:30
158	9	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	5	t	2026-02-23 13:34:12.111048+05:30
159	9	Your request to convert 500 points to cash (250.0) has been submitted and is pending approval.	CONVERSION	23	t	2026-02-23 13:36:28.356717+05:30
160	9	Your points conversion request for 500 points has been approved.	CONVERSION	23	t	2026-02-23 14:24:18.339206+05:30
162	13	You have been nominated for a Above and Beyond award by Charlotte Hall!	AWARD	28	t	2026-02-23 16:11:39.857519+05:30
164	13	You have been nominated for a Above and Beyond award by Charlotte Hall!	AWARD	29	t	2026-02-23 16:17:30.869661+05:30
166	13	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	29	t	2026-02-23 16:19:23.378924+05:30
167	8	Olivia Harris appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	44	f	2026-02-23 16:25:30.958888+05:30
168	24	Congratulations! Your Spot Award award has been fully approved. 200 points awarded!	AWARD	30	f	2026-02-24 11:23:20.698572+05:30
153	4	You have been allocated 1000 points in your manager budget.	BUDGET	40	t	2026-02-23 12:08:23.464846+05:30
141	4	New Award Nomination: Noah Adams has been nominated for Star Performer.	AWARD	24	t	2026-02-19 15:06:34.434272+05:30
147	4	You have been allocated 500 points in your manager budget.	BUDGET	38	t	2026-02-20 15:16:59.769739+05:30
151	4	New Award Nomination: Noah Adams has been nominated for Rising Star.	AWARD	27	t	2026-02-23 11:46:21.43367+05:30
154	4	You have been allocated 3000 points in your manager budget.	BUDGET	41	t	2026-02-23 12:09:02.722297+05:30
170	9	You have received 3000 points from your manager. Reason: 	MANAGER_REWARD	62	t	2026-02-24 14:09:21.043674+05:30
171	9	Redemption successful! You redeemed 'Premium Coffee Gift Set' for 1500 points.	REDEMPTION	6	t	2026-02-24 14:09:55.97661+05:30
172	9	Redemption successful! You redeemed 'Premium Coffee Gift Set' for 1500 points.	REDEMPTION	7	t	2026-02-24 14:10:23.063028+05:30
173	9	David Chen appreciated you with a 'Out of Box Thinker !!!' badge! 75 points earned.	ECARD	46	t	2026-02-24 14:21:18.641536+05:30
175	10	You have received 100 points from your manager. Reason: 	MANAGER_REWARD	65	f	2026-02-24 17:28:12.762968+05:30
176	25	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	31	f	2026-02-25 11:30:46.714962+05:30
177	7	New Award Nomination: Mason Taylor has been nominated for Above and Beyond.	AWARD	31	f	2026-02-25 11:30:46.724435+05:30
178	9	You have been nominated for a Star Performer award by David Chen!	AWARD	32	t	2026-02-25 14:44:53.805071+05:30
180	9	Update on your nomination: The Star Performer award nomination has not been approved at this time.	AWARD	32	t	2026-02-25 14:47:49.127279+05:30
182	8	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	33	f	2026-02-25 15:04:31.279594+05:30
181	4	Your nomination for Noah Adams (Star Performer) was rejected by Sarah Mitchell at the DEPT_HEAD level. Reason: not deserved need more work	AWARD	32	t	2026-02-25 14:47:49.144604+05:30
179	4	New Award Nomination: Noah Adams has been nominated for Star Performer.	AWARD	32	t	2026-02-25 14:44:53.814817+05:30
184	8	Update on your nomination: The Above and Beyond award nomination has not been approved at this time.	AWARD	33	f	2026-02-25 15:08:24.813168+05:30
185	9	Your nomination for Sophie Williams (Above and Beyond) was rejected by Sarah Mitchell at the DEPT_HEAD level. Reason: i dont think an award is needed for that u can give an ecard instead	AWARD	33	t	2026-02-25 15:08:24.827832+05:30
186	25	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	31	f	2026-02-25 15:13:23.238793+05:30
183	4	New Award Nomination: Sophie Williams has been nominated for Above and Beyond.	AWARD	33	t	2026-02-25 15:04:31.288763+05:30
188	2	You have been allocated 2000 points in your manager budget.	BUDGET	45	f	2026-02-26 10:20:32.20987+05:30
161	20	You have received 300 points from your manager. Reason: fantastic work on backend	MANAGER_REWARD	57	t	2026-02-23 14:52:20.588066+05:30
148	5	You have been allocated 1000 points in your manager budget.	BUDGET	39	t	2026-02-20 15:21:17.056311+05:30
155	5	You have been allocated 3000 points in your manager budget.	BUDGET	42	t	2026-02-23 12:09:02.740247+05:30
163	5	New Award Nomination: Olivia Harris has been nominated for Above and Beyond.	AWARD	28	t	2026-02-23 16:11:39.866116+05:30
191	6	You have been allocated 3000 points in your manager budget.	BUDGET	48	f	2026-02-26 10:23:01.453025+05:30
192	3	You have been allocated 3000 points in your manager budget.	BUDGET	49	f	2026-02-26 10:30:54.555365+05:30
193	2	You have been allocated 1200000 points in your manager budget.	BUDGET	50	f	2026-02-26 10:47:04.343862+05:30
194	2	You have been allocated 110000 points in your manager budget.	BUDGET	51	f	2026-02-26 10:53:19.531191+05:30
195	3	You have been allocated 1000001 points in your manager budget.	BUDGET	52	f	2026-02-26 10:55:29.924579+05:30
146	11	Noah Adams appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	43	t	2026-02-20 12:41:38.374488+05:30
169	11	David Chen appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	45	t	2026-02-24 11:41:11.921138+05:30
187	11	You have received 1400 points from your manager. Reason: good work 	MANAGER_REWARD	67	t	2026-02-26 10:11:38.259866+05:30
198	27	Liam Johnson appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	50	f	2026-02-26 12:27:30.812817+05:30
199	23	Benjamin Walker appreciated you with a 'Trust Builder !!!' badge! 65 points earned.	ECARD	51	f	2026-02-26 12:28:36.634016+05:30
197	4	You have been allocated 10000000 points in your manager budget.	BUDGET	54	t	2026-02-26 10:59:46.075037+05:30
196	4	You have been allocated 100001 points in your manager budget.	BUDGET	53	t	2026-02-26 10:59:33.012639+05:30
189	4	You have been allocated 2000 points in your manager budget.	BUDGET	46	t	2026-02-26 10:20:47.036883+05:30
190	4	You have been allocated 2000 points in your manager budget.	BUDGET	47	t	2026-02-26 10:21:06.580003+05:30
200	11	You have received 2000 points from your manager. Reason: keep up the hardwork	MANAGER_REWARD	70	f	2026-02-26 13:05:49.017503+05:30
201	11	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	8	f	2026-02-26 13:08:58.948123+05:30
202	20	Liam Johnson appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	52	f	2026-02-26 14:34:12.207049+05:30
203	11	Redemption successful! You redeemed 'Amazon $25 Gift Card' for 2500 points.	REDEMPTION	9	f	2026-02-26 14:35:50.78688+05:30
205	4	New Award Nomination: Noah Adams has been nominated for Above and Beyond.	AWARD	34	f	2026-02-26 14:37:16.356187+05:30
206	12	You have received 400 points from your manager. Reason: keep up the good work	MANAGER_REWARD	72	f	2026-02-26 14:38:45.946635+05:30
165	5	New Award Nomination: Olivia Harris has been nominated for Above and Beyond.	AWARD	29	t	2026-02-23 16:17:30.875645+05:30
174	5	Noah Adams appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	47	t	2026-02-24 14:37:14.863893+05:30
208	5	🎉 Happy Birthday! You've been awarded 500 reward points. Have a great day!	CELEBRATION	3	t	2026-02-27 11:38:03.403644+05:30
209	5	Your request to convert 550 points to cash (110.0) has been submitted and is pending approval.	CONVERSION	24	t	2026-02-27 16:15:50.071747+05:30
210	5	Your request to convert 550 points to cash (110.0) has been submitted and is pending approval.	CONVERSION	25	t	2026-02-27 16:16:04.344983+05:30
211	5	Your points conversion request for 550 points has been approved.	CONVERSION	25	t	2026-02-27 16:16:55.821569+05:30
212	5	Your points conversion request for 550 points has been rejected.	CONVERSION	24	t	2026-02-27 16:17:04.504491+05:30
213	9	Mia Lewis appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	53	t	2026-03-03 10:57:01.508136+05:30
222	16	Noah Adams appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	62	f	2026-03-03 13:08:01.222746+05:30
224	12	You have received 600 points from your manager. Reason: 	MANAGER_REWARD	85	f	2026-03-03 13:10:14.79624+05:30
226	2	You have been allocated 1000 points in your manager budget.	BUDGET	55	f	2026-03-03 13:13:09.84139+05:30
227	22	Noah Adams appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	63	f	2026-03-03 15:57:25.134882+05:30
229	8	Noah Adams appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	65	f	2026-03-04 14:19:48.663166+05:30
230	10	Noah Adams appreciated you with a 'Star of Innovation !!!' badge! 50 points earned.	ECARD	66	f	2026-03-04 14:20:21.655741+05:30
231	22	Noah Adams appreciated you with a 'Customer Hero !!!' badge! 50 points earned.	ECARD	67	f	2026-03-04 14:39:18.584577+05:30
232	25	Noah Adams appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	68	f	2026-03-04 14:44:35.372089+05:30
233	12	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	10	f	2026-03-04 14:47:48.048369+05:30
235	4	New Award Nomination: Noah Adams has been nominated for Above and Beyond.	AWARD	35	f	2026-03-04 15:02:56.32658+05:30
204	9	You have been nominated for a Above and Beyond award by Liam Johnson!	AWARD	34	t	2026-02-26 14:37:16.342054+05:30
228	6	Noah Adams appreciated you with a 'Out of Box Thinker !!!' badge! 75 points earned.	ECARD	64	t	2026-03-03 16:49:14.843371+05:30
237	19	Noah Adams appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	69	f	2026-03-04 16:07:51.124363+05:30
238	8	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	36	f	2026-03-04 16:16:48.094023+05:30
240	8	You have received 20 points from your manager. Reason: Great work	MANAGER_REWARD	94	f	2026-03-04 16:20:52.376522+05:30
241	12	You have received 100 points from your manager. Reason: keep up the hardwork	MANAGER_REWARD	95	f	2026-03-05 09:53:29.195902+05:30
242	10	You have received 100 points from your manager. Reason: keep it up	MANAGER_REWARD	96	f	2026-03-05 10:40:13.579634+05:30
243	11	You have received 50 points from your manager. Reason: keep up	MANAGER_REWARD	97	f	2026-03-05 10:43:14.326871+05:30
244	8	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	36	f	2026-03-05 10:51:04.373723+05:30
239	4	New Award Nomination: Sophie Williams has been nominated for Above and Beyond.	AWARD	36	t	2026-03-04 16:16:48.100552+05:30
246	4	You have been allocated 3000 points in your manager budget.	BUDGET	56	f	2026-03-05 14:38:31.44498+05:30
247	4	You have received 2000 points from your manager. Reason: keep up the good work	MANAGER_REWARD	100	f	2026-03-05 14:39:34.095805+05:30
245	9	You have received 500 points from your manager. Reason: 	MANAGER_REWARD	99	t	2026-03-05 14:37:40.62892+05:30
236	9	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	35	t	2026-03-04 15:29:02.827502+05:30
234	9	You have been nominated for a Above and Beyond award by Michael Thompson!	AWARD	35	t	2026-03-04 15:02:56.313643+05:30
248	11	Noah Adams appreciated you with a 'Customer Hero !!!' badge! 50 points earned.	ECARD	70	f	2026-03-09 11:11:50.603878+05:30
249	11	Noah Adams appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	71	f	2026-03-09 22:05:39.269254+05:30
250	11	You have been nominated for a Best Team Player award by David Chen!	AWARD	37	f	2026-03-10 09:41:01.877219+05:30
251	4	New Award Nomination: Liam Johnson has been nominated for Best Team Player.	AWARD	37	f	2026-03-10 09:41:01.887897+05:30
252	11	Congratulations! Your Best Team Player award has been fully approved. 400 points awarded!	AWARD	37	f	2026-03-10 09:41:25.561872+05:30
253	11	Noah Adams appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	72	f	2026-03-10 14:01:13.662233+05:30
254	11	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	38	f	2026-03-10 14:03:16.442897+05:30
255	4	New Award Nomination: Liam Johnson has been nominated for Above and Beyond.	AWARD	38	f	2026-03-10 14:03:16.449359+05:30
256	11	You have received 300 points from your manager. Reason: 	MANAGER_REWARD	105	f	2026-03-10 14:03:58.076175+05:30
257	11	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	38	f	2026-03-10 14:11:03.73031+05:30
258	4	Liam Johnson appreciated you with a 'Customer Hero !!!' badge! 50 points earned.	ECARD	73	f	2026-03-11 12:02:31.518642+05:30
260	24	Isabella Brown appreciated you with a 'Partnership Pioneer !!!' badge! 80 points earned.	ECARD	75	f	2026-03-11 12:11:43.157515+05:30
261	18	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	39	f	2026-03-11 12:34:39.850482+05:30
264	4	New Award Nomination: Noah Adams has been nominated for Above and Beyond and requires your approval.	AWARD	40	f	2026-03-11 12:48:31.61837+05:30
265	2	New Award Nomination: Noah Adams has been nominated for Above and Beyond and requires your approval.	AWARD	40	f	2026-03-11 12:49:33.735385+05:30
268	5	Noah Adams appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	77	f	2026-03-11 13:01:24.922892+05:30
269	21	Noah Adams appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	78	f	2026-03-11 13:01:32.776547+05:30
270	27	Noah Adams appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	79	f	2026-03-11 13:01:41.413626+05:30
272	18	Update on your nomination: The Above and Beyond award nomination has not been approved at this time.	AWARD	39	f	2026-03-11 14:20:56.806646+05:30
266	1	New Award Nomination: Noah Adams has been nominated for Above and Beyond and requires your approval.	AWARD	40	t	2026-03-11 12:50:20.861731+05:30
276	1719	Fidaan Hussain P appreciated you with a 'You Rock !!!' badge! 50 points earned.	ECARD	82	f	2026-03-17 11:46:31.87009+05:30
277	1719	Fidaan Hussain P appreciated you with a 'You Rock !!!' badge! 50 points earned.	ECARD	83	f	2026-03-17 11:47:12.933505+05:30
278	1719	Fidaan Hussain P appreciated you with a 'You Rock !!!' badge! 50 points earned.	ECARD	84	f	2026-03-17 12:23:49.434903+05:30
279	1719	Fidaan Hussain P appreciated you with a 'You Rock !!!' badge! 50 points earned.	ECARD	85	f	2026-03-17 12:26:35.644167+05:30
280	1719	You have been nominated for a Above and Beyond award by Fidaan Hussain P!	AWARD	41	f	2026-03-17 13:09:11.779596+05:30
283	15	Noah Adams appreciated you with a 'Invaluable Help !!!' badge! 50 points earned.	ECARD	87	f	2026-03-25 16:45:03.348628+05:30
207	9	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	34	t	2026-02-26 14:43:38.849407+05:30
262	6	New Award Nomination: Ethan Clark has been nominated for Above and Beyond.	AWARD	39	t	2026-03-11 12:34:39.859293+05:30
267	6	Noah Adams appreciated you with a 'Out of Box Thinker !!!' badge! 75 points earned.	ECARD	76	t	2026-03-11 13:01:16.76053+05:30
282	1718	Noah Adams appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	86	t	2026-03-25 16:44:14.727453+05:30
214	9	Mia Lewis appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	54	t	2026-03-03 10:57:20.504894+05:30
215	9	Mia Lewis appreciated you with a 'Star of Innovation !!!' badge! 50 points earned.	ECARD	55	t	2026-03-03 10:57:33.890337+05:30
216	9	Mia Lewis appreciated you with a 'Out of Box Thinker !!!' badge! 75 points earned.	ECARD	56	t	2026-03-03 10:59:08.559859+05:30
217	9	Benjamin Walker appreciated you with a 'You Rock !!!' badge! 50 points earned.	ECARD	57	t	2026-03-03 11:19:04.964118+05:30
218	9	Isabella Brown appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	58	t	2026-03-03 11:25:10.497065+05:30
219	9	Isabella Brown appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	59	t	2026-03-03 11:25:18.043763+05:30
220	9	Isabella Brown appreciated you with a 'Star of Innovation !!!' badge! 50 points earned.	ECARD	60	t	2026-03-03 11:25:24.191622+05:30
221	9	Isabella Brown appreciated you with a 'You Rock !!!' badge! 50 points earned.	ECARD	61	t	2026-03-03 11:25:30.857185+05:30
223	9	Your request to convert 500 points to cash (100.0) has been submitted and is pending approval.	CONVERSION	26	t	2026-03-03 13:09:03.995054+05:30
225	9	Your points conversion request for 500 points has been approved.	CONVERSION	26	t	2026-03-03 13:12:57.295066+05:30
259	9	Michael Thompson appreciated you with a 'Heartfelt Apology !!' badge! 50 points earned.	ECARD	74	t	2026-03-11 12:09:35.502024+05:30
263	9	You have been nominated for a Above and Beyond award by Mia Lewis!	AWARD	40	t	2026-03-11 12:48:31.60785+05:30
271	9	Congratulations! Your Above and Beyond award has been fully approved. 300 points awarded!	AWARD	40	t	2026-03-11 14:19:50.713181+05:30
273	9	Your nomination for Ethan Clark (Above and Beyond) was rejected by your HR Jennifer Scott. Reason: Rejected	AWARD	39	t	2026-03-11 14:20:56.817241+05:30
274	9	Your request to convert 900 points to cash (180.0) has been submitted and is pending approval.	CONVERSION	27	t	2026-03-12 14:39:00.551342+05:30
275	9	Your points conversion request for 900 points has been approved.	CONVERSION	27	t	2026-03-12 15:15:00.895683+05:30
281	9	Your request to convert 500 points to cash (100.0) has been submitted and is pending approval.	CONVERSION	28	t	2026-03-25 11:11:38.839342+05:30
284	9	Your request to convert 500 points to cash (100.0) has been submitted and is pending approval.	CONVERSION	29	t	2026-03-25 16:45:53.461213+05:30
285	19	You have been nominated for a Above and Beyond award by Noah Adams!	AWARD	42	f	2026-03-26 16:58:49.21141+05:30
287	3	New Award Nomination: Mia Lewis has been nominated for Above and Beyond and requires your approval.	AWARD	42	f	2026-03-26 17:01:35.508008+05:30
286	6	New Award Nomination: Mia Lewis has been nominated for Above and Beyond and requires your approval.	AWARD	42	t	2026-03-26 16:58:49.221252+05:30
288	1698	Fidaan Hussain P appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	88	f	2026-03-27 12:12:46.952438+05:30
289	1674	Fidaan Hussain P appreciated you with a 'Heartfelt Apology !!' badge! 50 points earned.	ECARD	89	f	2026-03-27 12:29:18.136363+05:30
290	1719	Fidaan Hussain P appreciated you with a 'Great Team Player !!!' badge! 60 points earned.	ECARD	90	f	2026-03-27 12:31:16.35645+05:30
291	11	Fidaan Hussain P appreciated you with a 'Star of Innovation !!!' badge! 50 points earned.	ECARD	91	f	2026-03-27 17:25:42.909449+05:30
292	2	💍 Congratulations on your marriage! You've been awarded 1000 reward points to celebrate this wonderful occasion.	CELEBRATION	4	f	2026-03-30 10:53:18.578321+05:30
295	1719	Fidaan Hussain P appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	92	f	2026-03-30 14:30:21.335324+05:30
296	1719	Fidaan Hussain P appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	93	f	2026-03-30 15:33:43.255674+05:30
297	1719	Fidaan Hussain P appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	94	f	2026-03-30 15:35:46.974037+05:30
298	1718	Redemption successful! You redeemed 'Premium Coffee Gift Set' for 1500 points.	REDEMPTION	11	t	2026-03-31 10:56:49.835077+05:30
299	1718	Redemption successful! You redeemed 'Fitness Tracker' for 9000 points.	REDEMPTION	12	t	2026-03-31 11:05:57.343873+05:30
300	1718	Redemption successful! You redeemed 'Company Hoodie' for 2000 points.	REDEMPTION	13	t	2026-03-31 11:12:21.704192+05:30
301	1718	Your request to convert 1000 points to cash (200.0) has been submitted and is pending approval.	CONVERSION	30	t	2026-03-31 11:12:54.000255+05:30
303	1719	Fidaan Hussain P appreciated you with a 'Agility Champion !!!' badge! 70 points earned.	ECARD	96	f	2026-03-31 14:31:04.824668+05:30
302	1718	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	14	t	2026-03-31 14:30:38.020424+05:30
304	1718	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	15	t	2026-03-31 17:49:19.706412+05:30
305	1718	Redemption successful! You redeemed 'Noise-Cancelling Headphones' for 5000 points.	REDEMPTION	16	t	2026-03-31 17:50:53.566605+05:30
306	1651	Fidaan Hussain P appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	97	f	2026-04-01 10:58:04.376948+05:30
293	9	Your points conversion request for 500 points has been rejected.	CONVERSION	28	t	2026-03-30 11:47:50.659446+05:30
294	9	Your points conversion request for 500 points has been approved.	CONVERSION	29	t	2026-03-30 11:47:52.85992+05:30
309	9	General appreciated you with a 'Bright Spark !!!' badge! 50 points earned.	ECARD	98	t	2026-04-01 17:23:46.784143+05:30
310	1718	Sermandurai Subbiah appreciated you with a 'Customer Hero !!!' badge! 50 points earned.	ECARD	99	t	2026-04-01 17:25:01.049034+05:30
308	1718	Congratulations! Your Leadership Excellence award has been fully approved by HR. 1000 points awarded!	AWARD	43	t	2026-04-01 15:39:13.592117+05:30
307	1718	Your points conversion request for 1000 points has been approved.	CONVERSION	30	t	2026-04-01 12:40:19.418215+05:30
311	1718	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	17	f	2026-04-09 11:40:52.185786+05:30
312	1718	Your request to convert 500 points to cash (50.0) has been submitted and is pending approval.	CONVERSION	31	f	2026-04-09 12:02:19.43552+05:30
313	1713	You have been nominated for a Above and Beyond award by Nominate as Myself!	AWARD	44	f	2026-04-10 16:47:14.027803+05:30
314	1718	Redemption successful! You redeemed 'Desk Plant' for 800 points.	REDEMPTION	18	f	2026-04-10 16:49:24.884982+05:30
\.


--
-- Data for Name: points_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.points_batches (id, user_id, points, remaining_points, source_type, source_id, expiry_date, created_at) FROM stdin;
52	8	75	75	ECARD	42	2027-02-19	2026-02-19 14:26:15.150581+05:30
54	21	300	300	AWARD	25	2027-02-19	2026-02-19 15:26:12.982025+05:30
102	11	50	50	ECARD	71	2027-03-09	2026-03-09 22:05:39.242451+05:30
103	11	400	400	AWARD	37	2027-03-10	2026-03-10 09:41:25.543274+05:30
104	11	50	50	ECARD	72	2027-03-10	2026-03-10 14:01:13.646167+05:30
105	11	300	300	MANAGER_REWARD	4	2027-03-10	2026-03-10 14:03:58.051225+05:30
106	11	300	300	AWARD	38	2027-03-10	2026-03-10 14:11:03.717594+05:30
51	9	50	0	ECARD	41	2027-02-19	2026-02-19 14:17:33.71618+05:30
53	9	500	0	AWARD	24	2026-06-20	2026-02-19 15:08:54.712538+05:30
107	4	50	50	ECARD	73	2027-03-11	2026-03-11 12:02:31.487323+05:30
56	9	750	0	AWARD	27	2027-02-23	2026-02-23 12:08:03.597524+05:30
57	20	300	300	MANAGER_REWARD	6	2027-02-23	2026-02-23 14:52:20.546344+05:30
58	13	300	300	AWARD	29	2027-02-23	2026-02-23 16:19:23.359076+05:30
59	8	50	50	ECARD	44	2027-02-23	2026-02-23 16:25:30.93715+05:30
60	24	200	200	AWARD	30	2027-02-24	2026-02-24 11:23:20.672055+05:30
109	24	80	80	ECARD	75	2027-03-11	2026-03-11 12:11:43.133601+05:30
65	10	100	100	MANAGER_REWARD	4	2027-02-24	2026-02-24 17:28:12.727294+05:30
66	25	300	300	AWARD	31	2027-02-25	2026-02-25 15:13:23.212856+05:30
110	6	75	75	ECARD	76	2027-03-11	2026-03-11 13:01:16.739191+05:30
111	5	50	50	ECARD	77	2027-03-11	2026-03-11 13:01:24.909762+05:30
112	21	60	60	ECARD	78	2027-03-11	2026-03-11 13:01:32.763055+05:30
113	27	50	50	ECARD	79	2027-03-11	2026-03-11 13:01:41.401126+05:30
68	27	50	50	ECARD	50	2027-02-26	2026-02-26 12:27:30.727959+05:30
69	23	65	65	ECARD	51	2027-02-26	2026-02-26 12:28:36.613922+05:30
76	9	60	0	ECARD	54	2027-03-03	2026-03-03 10:57:20.489593+05:30
77	9	50	0	ECARD	55	2027-03-03	2026-03-03 10:57:33.876685+05:30
78	9	75	0	ECARD	56	2027-03-03	2026-03-03 10:59:08.543033+05:30
79	9	50	0	ECARD	57	2027-03-03	2026-03-03 11:19:04.930715+05:30
62	9	3000	0	MANAGER_REWARD	4	2027-02-24	2026-01-24 14:09:21.011818+05:30
80	9	60	0	ECARD	58	2027-03-03	2026-03-03 11:25:10.4825+05:30
71	20	60	60	ECARD	52	2027-02-26	2026-02-26 14:34:12.186331+05:30
55	11	50	0	ECARD	43	2027-02-20	2026-02-20 12:41:38.343631+05:30
61	11	60	0	ECARD	45	2027-02-24	2026-02-24 11:41:11.906199+05:30
67	11	1400	0	MANAGER_REWARD	4	2026-02-26	2026-02-26 10:11:38.227868+05:30
70	11	2000	210	MANAGER_REWARD	4	2027-02-26	2026-02-26 13:05:48.986376+05:30
64	5	50	0	ECARD	47	2027-02-24	2026-02-24 14:37:14.842059+05:30
74	5	500	0	CELEBRATION	3	2027-02-27	2026-02-27 11:38:03.358864+05:30
84	16	60	60	ECARD	62	2027-03-03	2026-03-03 13:08:01.188181+05:30
63	9	75	0	ECARD	46	2027-02-24	2026-02-24 14:21:18.616934+05:30
73	9	300	0	AWARD	34	2027-02-26	2026-02-26 14:43:38.834329+05:30
75	9	70	0	ECARD	53	2027-03-03	2026-03-03 10:57:01.477963+05:30
108	9	50	0	ECARD	74	2027-03-11	2026-03-11 12:09:35.463281+05:30
86	22	70	70	ECARD	63	2027-03-03	2026-03-03 15:57:25.102835+05:30
87	6	75	75	ECARD	64	2027-03-03	2026-03-03 16:49:14.818682+05:30
88	8	70	70	ECARD	65	2027-03-04	2026-03-04 14:19:48.636343+05:30
89	10	50	50	ECARD	66	2027-03-04	2026-03-04 14:20:21.627752+05:30
90	22	50	50	ECARD	67	2027-03-04	2026-03-04 14:39:18.557604+05:30
91	25	60	60	ECARD	68	2027-03-04	2026-03-04 14:44:35.345321+05:30
72	12	400	0	MANAGER_REWARD	4	2027-02-26	2026-02-26 14:38:45.911393+05:30
85	12	600	200	MANAGER_REWARD	4	2027-03-03	2026-03-03 13:10:14.775533+05:30
93	19	50	50	ECARD	69	2027-03-04	2026-03-04 16:07:51.087757+05:30
94	8	20	20	MANAGER_REWARD	4	2027-03-04	2026-03-04 16:20:52.351442+05:30
95	12	100	100	MANAGER_REWARD	4	2027-03-05	2026-03-05 09:53:29.165214+05:30
96	10	100	100	MANAGER_REWARD	4	2027-03-05	2026-03-05 10:40:13.545478+05:30
97	11	50	50	MANAGER_REWARD	4	2027-03-05	2026-03-05 10:43:14.308866+05:30
98	8	300	300	AWARD	36	2027-03-05	2026-03-05 10:51:04.353642+05:30
100	4	2000	2000	MANAGER_REWARD	2	2027-03-05	2026-03-05 14:39:34.07526+05:30
101	11	50	50	ECARD	70	2027-03-09	2026-03-09 11:11:50.576895+05:30
81	9	70	0	ECARD	59	2027-03-03	2026-03-03 11:25:18.026589+05:30
82	9	50	0	ECARD	60	2027-03-03	2026-03-03 11:25:24.175468+05:30
83	9	50	0	ECARD	61	2027-03-03	2026-03-03 11:25:30.844377+05:30
92	9	300	0	AWARD	35	2027-03-04	2026-03-04 15:29:02.80755+05:30
132	1718	1000	1000	AWARD	43	2027-04-01	2026-04-01 15:39:13.576427+05:30
115	1719	50	50	ECARD	82	2027-03-17	2026-03-17 11:46:31.834882+05:30
116	1719	50	50	ECARD	83	2027-03-17	2026-03-17 11:47:12.917995+05:30
117	1719	50	50	ECARD	84	2027-03-17	2026-03-17 12:23:49.416133+05:30
118	1719	50	50	ECARD	85	2027-03-17	2026-03-17 12:26:35.632132+05:30
120	15	50	50	ECARD	87	2027-03-25	2026-03-25 16:45:03.325929+05:30
121	1698	60	60	ECARD	88	2027-03-27	2026-03-27 12:12:46.92937+05:30
122	1674	50	50	ECARD	89	2027-03-27	2026-03-27 12:29:18.115207+05:30
123	1719	60	60	ECARD	90	2027-03-27	2026-03-27 12:31:16.346025+05:30
124	11	50	50	ECARD	91	2027-03-27	2026-03-27 17:25:42.884621+05:30
125	2	1000	1000	CELEBRATION	4	2027-03-30	2026-03-30 10:53:18.54496+05:30
99	9	500	0	MANAGER_REWARD	4	2027-03-05	2026-03-05 14:37:40.604789+05:30
114	9	300	160	AWARD	40	2027-03-11	2026-03-11 14:19:50.701218+05:30
126	1719	50	50	ECARD	92	2027-03-30	2026-03-30 14:30:21.31038+05:30
127	1719	70	70	ECARD	93	2027-03-30	2026-03-30 15:33:43.231469+05:30
128	1719	70	70	ECARD	94	2027-03-30	2026-03-30 15:35:46.953908+05:30
130	1719	70	70	ECARD	96	2027-03-31	2026-03-31 14:31:04.798172+05:30
133	9	50	50	ECARD	98	2027-04-01	2026-04-01 17:23:46.764892+05:30
134	1718	50	50	ECARD	99	2027-04-01	2026-04-01 17:25:01.038425+05:30
131	1651	50	50	ECARD	97	2027-04-01	2026-04-01 10:58:04.354875+05:30
129	1719	50	50	ECARD	95	2027-03-31	2026-03-31 14:21:45.577968+05:30
119	1718	50	2700	ECARD	86	2027-03-25	2026-03-25 16:44:14.702652+05:30
\.


--
-- Data for Name: points_conversion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.points_conversion (id, user_id, points_converted, cash_amount, conversion_type, status, requested_at, approved_by, approved_at) FROM stdin;
23	9	500	250.00	CSR	APPROVED	2026-02-23 13:36:28.347751+05:30	1	2026-02-23 14:24:18.333522+05:30
25	5	550	110.00	PAYROLL	APPROVED	2026-02-27 16:16:04.337974+05:30	1	2026-02-27 16:16:55.812288+05:30
24	5	550	110.00	PAYROLL	REJECTED	2026-02-27 16:15:50.060936+05:30	1	2026-02-27 16:17:04.499637+05:30
26	9	500	100.00	PAYROLL	APPROVED	2026-03-03 13:09:03.979475+05:30	1	2026-03-03 13:12:57.285703+05:30
27	9	900	180.00	PAYROLL	APPROVED	2026-03-12 14:39:00.535744+05:30	1	2026-03-12 15:15:00.887885+05:30
28	9	500	100.00	PAYROLL	REJECTED	2026-03-25 11:11:38.82787+05:30	1	2026-03-30 11:47:50.652931+05:30
29	9	500	100.00	PAYROLL	APPROVED	2026-03-25 16:45:53.452006+05:30	1	2026-03-30 11:47:52.854885+05:30
30	1718	1000	200.00	PAYROLL	APPROVED	2026-03-31 11:12:53.982284+05:30	1	2026-04-01 12:40:19.411244+05:30
31	1718	500	50.00	payroll	PENDING	2026-04-09 12:02:19.41062+05:30	\N	\N
\.


--
-- Data for Name: points_ledger; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.points_ledger (id, source_wallet_id, target_wallet_id, points, transaction_type, reference_type, reference_id, created_at) FROM stdin;
114	\N	18	50	CREDIT	ECARD	41	2026-02-19 14:17:33.727389+05:30
115	\N	19	75	CREDIT	ECARD	42	2026-02-19 14:26:15.163999+05:30
116	\N	18	500	CREDIT	AWARD	24	2026-02-19 15:08:54.712538+05:30
117	\N	20	300	CREDIT	AWARD	25	2026-02-19 15:26:13.011183+05:30
118	\N	22	50	CREDIT	ECARD	43	2026-02-20 12:41:38.357236+05:30
119	\N	17	500	CREDIT	BUDGET_ALLOCATION	38	2026-02-20 15:16:59.732289+05:30
120	\N	23	1000	CREDIT	BUDGET_ALLOCATION	39	2026-02-20 15:21:17.034862+05:30
121	\N	18	750	CREDIT	AWARD	27	2026-02-23 12:08:03.597524+05:30
122	\N	17	1000	CREDIT	BUDGET_ALLOCATION	40	2026-02-23 12:08:23.442865+05:30
123	\N	17	3000	CREDIT	BUDGET_ALLOCATION	41	2026-02-23 12:09:02.705812+05:30
124	\N	23	3000	CREDIT	BUDGET_ALLOCATION	42	2026-02-23 12:09:02.726473+05:30
125	\N	25	3000	CREDIT	BUDGET_ALLOCATION	43	2026-02-23 12:09:02.752487+05:30
126	\N	26	3000	CREDIT	BUDGET_ALLOCATION	44	2026-02-23 12:09:02.773935+05:30
127	18	\N	800	DEBIT	REDEMPTION	0	2026-02-23 13:34:12.085283+05:30
128	18	\N	500	DEBIT	CONVERSION	23	2026-02-23 14:24:18.320511+05:30
129	25	\N	300	DEBIT	MANAGER_REWARD	20	2026-02-23 14:52:20.546344+05:30
130	\N	27	300	CREDIT	MANAGER_REWARD	6	2026-02-23 14:52:20.571511+05:30
131	\N	28	300	CREDIT	AWARD	29	2026-02-23 16:19:23.373409+05:30
132	\N	19	50	CREDIT	ECARD	44	2026-02-23 16:25:30.93715+05:30
133	\N	30	200	CREDIT	AWARD	30	2026-02-24 11:23:20.686988+05:30
134	\N	22	60	CREDIT	ECARD	45	2026-02-24 11:41:11.906199+05:30
135	17	\N	3000	DEBIT	MANAGER_REWARD	9	2026-02-24 14:09:21.011818+05:30
137	18	\N	1500	DEBIT	REDEMPTION	0	2026-02-24 14:09:55.94791+05:30
138	18	\N	1500	DEBIT	REDEMPTION	0	2026-02-24 14:10:23.045443+05:30
139	\N	18	75	CREDIT	ECARD	46	2026-02-24 14:21:18.616934+05:30
140	\N	31	50	CREDIT	ECARD	47	2026-02-24 14:37:14.851869+05:30
141	17	\N	100	DEBIT	MANAGER_REWARD	10	2026-02-24 17:28:12.727294+05:30
142	\N	24	100	CREDIT	MANAGER_REWARD	4	2026-02-24 17:28:12.727294+05:30
143	\N	34	300	CREDIT	AWARD	31	2026-02-25 15:13:23.230272+05:30
144	17	\N	1400	DEBIT	MANAGER_REWARD	11	2026-02-26 10:11:38.227868+05:30
145	\N	22	1400	CREDIT	MANAGER_REWARD	4	2026-02-26 10:11:38.227868+05:30
146	\N	35	2000	CREDIT	BUDGET_ALLOCATION	45	2026-02-26 10:20:32.191108+05:30
147	\N	17	2000	CREDIT	BUDGET_ALLOCATION	46	2026-02-26 10:20:47.015266+05:30
148	\N	17	2000	CREDIT	BUDGET_ALLOCATION	47	2026-02-26 10:21:06.557395+05:30
149	\N	25	3000	CREDIT	BUDGET_ALLOCATION	48	2026-02-26 10:23:01.437805+05:30
150	\N	36	3000	CREDIT	BUDGET_ALLOCATION	49	2026-02-26 10:30:54.489134+05:30
151	\N	35	1200000	CREDIT	BUDGET_ALLOCATION	50	2026-02-26 10:47:04.315579+05:30
152	\N	35	110000	CREDIT	BUDGET_ALLOCATION	51	2026-02-26 10:53:19.509199+05:30
153	\N	36	1000001	CREDIT	BUDGET_ALLOCATION	52	2026-02-26 10:55:29.896671+05:30
154	\N	17	100001	CREDIT	BUDGET_ALLOCATION	53	2026-02-26 10:59:32.984906+05:30
155	\N	17	10000000	CREDIT	BUDGET_ALLOCATION	54	2026-02-26 10:59:46.059043+05:30
156	\N	37	50	CREDIT	ECARD	50	2026-02-26 12:27:30.793516+05:30
157	\N	38	65	CREDIT	ECARD	51	2026-02-26 12:28:36.623127+05:30
136	\N	18	3000	CREDIT	MANAGER_REWARD	4	2026-01-24 14:09:21.011818+05:30
158	17	\N	2000	DEBIT	MANAGER_REWARD	11	2026-02-26 13:05:48.986376+05:30
159	\N	22	2000	CREDIT	MANAGER_REWARD	4	2026-02-26 13:05:48.986376+05:30
160	22	\N	800	DEBIT	REDEMPTION	0	2026-02-26 13:08:58.926764+05:30
161	\N	27	60	CREDIT	ECARD	52	2026-02-26 14:34:12.186331+05:30
162	22	\N	2500	DEBIT	REDEMPTION	0	2026-02-26 14:35:50.762376+05:30
163	17	\N	400	DEBIT	MANAGER_REWARD	12	2026-02-26 14:38:45.911393+05:30
164	\N	39	400	CREDIT	MANAGER_REWARD	4	2026-02-26 14:38:45.934724+05:30
165	\N	18	300	CREDIT	AWARD	34	2026-02-26 14:43:38.834329+05:30
166	\N	31	500	CREDIT	CELEBRATION	3	2026-02-27 11:38:03.358864+05:30
167	31	\N	550	DEBIT	CONVERSION	25	2026-02-27 16:16:55.789276+05:30
168	\N	18	70	CREDIT	ECARD	53	2026-03-03 10:57:01.477963+05:30
169	\N	18	60	CREDIT	ECARD	54	2026-03-03 10:57:20.489593+05:30
170	\N	18	50	CREDIT	ECARD	55	2026-03-03 10:57:33.876685+05:30
171	\N	18	75	CREDIT	ECARD	56	2026-03-03 10:59:08.543033+05:30
172	\N	18	50	CREDIT	ECARD	57	2026-03-03 11:19:04.930715+05:30
173	\N	18	60	CREDIT	ECARD	58	2026-03-03 11:25:10.4825+05:30
174	\N	18	70	CREDIT	ECARD	59	2026-03-03 11:25:18.026589+05:30
175	\N	18	50	CREDIT	ECARD	60	2026-03-03 11:25:24.175468+05:30
176	\N	18	50	CREDIT	ECARD	61	2026-03-03 11:25:30.844377+05:30
177	\N	40	60	CREDIT	ECARD	62	2026-03-03 13:08:01.204873+05:30
178	17	\N	600	DEBIT	MANAGER_REWARD	12	2026-03-03 13:10:14.775533+05:30
179	\N	39	600	CREDIT	MANAGER_REWARD	4	2026-03-03 13:10:14.775533+05:30
180	18	\N	500	DEBIT	CONVERSION	26	2026-03-03 13:12:57.26515+05:30
181	\N	35	1000	CREDIT	BUDGET_ALLOCATION	55	2026-03-03 13:13:09.818091+05:30
182	\N	41	70	CREDIT	ECARD	63	2026-03-03 15:57:25.116346+05:30
183	\N	21	75	CREDIT	ECARD	64	2026-03-03 16:49:14.818682+05:30
184	\N	19	70	CREDIT	ECARD	65	2026-03-04 14:19:48.636343+05:30
185	\N	24	50	CREDIT	ECARD	66	2026-03-04 14:20:21.627752+05:30
186	\N	41	50	CREDIT	ECARD	67	2026-03-04 14:39:18.557604+05:30
187	\N	34	60	CREDIT	ECARD	68	2026-03-04 14:44:35.345321+05:30
188	39	\N	800	DEBIT	REDEMPTION	0	2026-03-04 14:47:48.027692+05:30
189	\N	18	300	CREDIT	AWARD	35	2026-03-04 15:29:02.80755+05:30
190	\N	42	50	CREDIT	ECARD	69	2026-03-04 16:07:51.104947+05:30
191	17	\N	20	DEBIT	MANAGER_REWARD	8	2026-03-04 16:20:52.351442+05:30
192	\N	19	20	CREDIT	MANAGER_REWARD	4	2026-03-04 16:20:52.351442+05:30
193	17	\N	100	DEBIT	MANAGER_REWARD	12	2026-03-05 09:53:29.165214+05:30
194	\N	39	100	CREDIT	MANAGER_REWARD	4	2026-03-05 09:53:29.165214+05:30
195	17	\N	100	DEBIT	MANAGER_REWARD	10	2026-03-05 10:40:13.545478+05:30
196	\N	24	100	CREDIT	MANAGER_REWARD	4	2026-03-05 10:40:13.545478+05:30
197	17	\N	50	DEBIT	MANAGER_REWARD	11	2026-03-05 10:43:14.308866+05:30
198	\N	22	50	CREDIT	MANAGER_REWARD	4	2026-03-05 10:43:14.308866+05:30
199	\N	19	300	CREDIT	AWARD	36	2026-03-05 10:51:04.353642+05:30
200	17	\N	500	DEBIT	MANAGER_REWARD	9	2026-03-05 14:37:40.604789+05:30
201	\N	18	500	CREDIT	MANAGER_REWARD	4	2026-03-05 14:37:40.604789+05:30
202	\N	17	3000	CREDIT	BUDGET_ALLOCATION	56	2026-03-05 14:38:31.42059+05:30
203	35	\N	2000	DEBIT	MANAGER_REWARD	4	2026-03-05 14:39:34.07526+05:30
204	\N	16	2000	CREDIT	MANAGER_REWARD	2	2026-03-05 14:39:34.07526+05:30
205	\N	22	50	CREDIT	ECARD	70	2026-03-09 11:11:50.576895+05:30
206	\N	22	50	CREDIT	ECARD	71	2026-03-09 22:05:39.242451+05:30
207	\N	22	400	CREDIT	AWARD	37	2026-03-10 09:41:25.543274+05:30
208	\N	22	50	CREDIT	ECARD	72	2026-03-10 14:01:13.646167+05:30
209	17	\N	300	DEBIT	MANAGER_REWARD	11	2026-03-10 14:03:58.051225+05:30
210	\N	22	300	CREDIT	MANAGER_REWARD	4	2026-03-10 14:03:58.051225+05:30
211	\N	22	300	CREDIT	AWARD	38	2026-03-10 14:11:03.717594+05:30
212	\N	16	50	CREDIT	ECARD	73	2026-03-11 12:02:31.487323+05:30
213	\N	18	50	CREDIT	ECARD	74	2026-03-11 12:09:35.463281+05:30
214	\N	30	80	CREDIT	ECARD	75	2026-03-11 12:11:43.133601+05:30
215	\N	21	75	CREDIT	ECARD	76	2026-03-11 13:01:16.739191+05:30
216	\N	31	50	CREDIT	ECARD	77	2026-03-11 13:01:24.909762+05:30
217	\N	20	60	CREDIT	ECARD	78	2026-03-11 13:01:32.763055+05:30
218	\N	37	50	CREDIT	ECARD	79	2026-03-11 13:01:41.401126+05:30
219	\N	18	300	CREDIT	AWARD	40	2026-03-11 14:19:50.701218+05:30
220	18	\N	900	DEBIT	CONVERSION	27	2026-03-12 15:15:00.864026+05:30
221	\N	44	50	CREDIT	ECARD	82	2026-03-17 11:46:31.84943+05:30
222	\N	44	50	CREDIT	ECARD	83	2026-03-17 11:47:12.917995+05:30
223	\N	44	50	CREDIT	ECARD	84	2026-03-17 12:23:49.416133+05:30
224	\N	44	50	CREDIT	ECARD	85	2026-03-17 12:26:35.632132+05:30
225	\N	43	50	CREDIT	ECARD	86	2026-03-25 16:44:14.702652+05:30
226	\N	45	50	CREDIT	ECARD	87	2026-03-25 16:45:03.335226+05:30
227	\N	46	60	CREDIT	ECARD	88	2026-03-27 12:12:46.937965+05:30
228	\N	47	50	CREDIT	ECARD	89	2026-03-27 12:29:18.12452+05:30
229	\N	44	60	CREDIT	ECARD	90	2026-03-27 12:31:16.346025+05:30
230	\N	22	50	CREDIT	ECARD	91	2026-03-27 17:25:42.884621+05:30
231	\N	29	1000	CREDIT	CELEBRATION	4	2026-03-30 10:53:18.54496+05:30
232	18	\N	500	DEBIT	CONVERSION	29	2026-03-30 11:47:52.835521+05:30
233	\N	44	50	CREDIT	ECARD	92	2026-03-30 14:30:21.31038+05:30
234	\N	44	70	CREDIT	ECARD	93	2026-03-30 15:33:43.231469+05:30
235	\N	44	70	CREDIT	ECARD	94	2026-03-30 15:35:46.953908+05:30
236	43	\N	1500	DEBIT	REDEMPTION	0	2026-03-31 10:56:49.801628+05:30
237	43	\N	9000	DEBIT	REDEMPTION	0	2026-03-31 11:05:57.309275+05:30
238	43	\N	2000	DEBIT	REDEMPTION	0	2026-03-31 11:12:21.671664+05:30
239	43	\N	12000	DEBIT	REDEMPTION	0	2026-03-31 14:06:18.617794+05:30
240	43	\N	12000	DEBIT	REDEMPTION	0	2026-03-31 14:08:00.21782+05:30
241	43	\N	1500	DEBIT	REDEMPTION	0	2026-03-31 14:20:32.24478+05:30
242	\N	44	50	CREDIT	ECARD	95	2026-03-31 14:21:45.577968+05:30
243	43	\N	800	DEBIT	REDEMPTION	0	2026-03-31 14:22:45.269516+05:30
244	43	\N	800	DEBIT	REDEMPTION	0	2026-03-31 14:28:24.206509+05:30
245	43	\N	800	DEBIT	REDEMPTION	0	2026-03-31 14:30:37.982528+05:30
246	\N	44	70	CREDIT	ECARD	96	2026-03-31 14:31:04.798172+05:30
247	43	\N	800	DEBIT	REDEMPTION	0	2026-03-31 17:49:19.678399+05:30
248	43	\N	5000	DEBIT	REDEMPTION	0	2026-03-31 17:50:53.547737+05:30
249	\N	49	50	CREDIT	ECARD	97	2026-04-01 10:58:04.363705+05:30
250	43	\N	1000	DEBIT	CONVERSION	30	2026-04-01 12:40:19.378248+05:30
251	\N	43	1000	CREDIT	AWARD	43	2026-04-01 15:39:13.576427+05:30
252	\N	18	50	CREDIT	ECARD	98	2026-04-01 17:23:46.764892+05:30
253	\N	43	50	CREDIT	ECARD	99	2026-04-01 17:25:01.038425+05:30
254	43	\N	800	DEBIT	REDEMPTION	0	2026-04-09 11:40:52.138465+05:30
255	43	\N	800	DEBIT	REDEMPTION	0	2026-04-10 16:49:24.842788+05:30
\.


--
-- Data for Name: points_policy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.points_policy (id, recognition_type, event_key, points, monthly_limit, cooldown_days, conversion_rate, conversion_reward_type, is_active, created_at, cooldown_hours, consecutive_limit) FROM stdin;
43	CELEBRATION	BIRTHDAY	500	\N	\N	\N	\N	t	2026-02-19 14:46:07.533342+05:30	\N	\N
44	CELEBRATION	ANNIVERSARY	1000	\N	\N	\N	\N	t	2026-02-19 14:46:07.533342+05:30	\N	\N
46	CONVERSION	\N	0	\N	\N	0.50	CSR	t	2026-02-19 14:46:07.533342+05:30	\N	\N
47	CONVERSION	\N	0	\N	\N	0.20	PAYROLL	t	2026-02-23 10:48:26.484584+05:30	\N	\N
48	ECARD	\N	60	50	1	\N	\N	t	2026-03-05 15:25:17.580856+05:30	2	5
49	CELEBRATION	BIRTH	750	\N	\N	\N	\N	t	2026-03-30 11:28:42.572024+05:30	\N	\N
50	CELEBRATION	MARRIAGE	1000	\N	\N	\N	\N	t	2026-03-30 11:28:42.572024+05:30	\N	\N
\.


--
-- Data for Name: recognition_feed; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recognition_feed (id, actor_id, receiver_id, source_type, source_id, message, created_at, actor_label) FROM stdin;
38	4	9	ECARD	41	thank u	2026-02-19 14:17:33.737744+05:30	\N
39	4	8	ECARD	42	Recognized with Out of Box Thinker !!!	2026-02-19 14:26:15.172896+05:30	\N
40	9	11	ECARD	43	Recognized with Bright Spark !!!	2026-02-20 12:41:38.365127+05:30	\N
41	6	20	MANAGER_REWARD	6	fantastic work on backend	2026-02-23 14:52:20.579209+05:30	\N
42	13	8	ECARD	44	thank u for the help	2026-02-23 16:25:30.951487+05:30	\N
43	7	24	AWARD	30	Honored with the Spot Award Award! 🎉	2026-02-24 11:23:20.640897+05:30	\N
44	4	11	ECARD	45	Recognized with Great Team Player !!!	2026-02-24 11:41:11.914495+05:30	\N
45	4	9	MANAGER_REWARD	4		2026-02-24 14:09:21.037378+05:30	\N
46	4	9	ECARD	46	Recognized with Out of Box Thinker !!!	2026-02-24 14:21:18.631402+05:30	\N
47	9	5	ECARD	47	thank you for your hardwork	2026-02-24 14:37:14.857228+05:30	\N
48	4	10	MANAGER_REWARD	4		2026-02-24 17:28:12.755286+05:30	\N
49	9	25	AWARD	31	Honored with the Above and Beyond Award! 🎉	2026-02-25 15:13:23.139362+05:30	\N
50	4	11	MANAGER_REWARD	4	good work 	2026-02-26 10:11:38.252502+05:30	\N
51	11	27	ECARD	50	thanks for the help	2026-02-26 12:27:30.80446+05:30	\N
52	20	23	ECARD	51	it was really valuable 	2026-02-26 12:28:36.628629+05:30	\N
53	4	11	MANAGER_REWARD	4	keep up the hardwork	2026-02-26 13:05:49.010256+05:30	\N
54	11	20	ECARD	52	thanks	2026-02-26 14:34:12.198835+05:30	\N
55	4	12	MANAGER_REWARD	4	keep up the good work	2026-02-26 14:38:45.941148+05:30	\N
56	11	9	AWARD	34	Honored with the Above and Beyond Award! 🎉	2026-02-26 14:43:38.817637+05:30	\N
57	1	5	CELEBRATION	3	Happy Birthday, Emily Turner! Enjoy your birthday reward points! 🎂	2026-02-27 11:38:03.39242+05:30	\N
58	19	9	ECARD	53	than for completeing the work so fast 	2026-03-03 10:57:01.498377+05:30	\N
59	19	9	ECARD	54	thanks for being a good partner 	2026-03-03 10:57:20.49919+05:30	\N
60	19	9	ECARD	55	what an idea \n	2026-03-03 10:57:33.8852+05:30	\N
61	19	9	ECARD	56	thank u for the idea 	2026-03-03 10:59:08.55383+05:30	\N
62	20	9	ECARD	57	thanks for the energy u pass on keep on producing more energy 	2026-03-03 11:19:04.951873+05:30	\N
63	10	9	ECARD	58	Recognized with Great Team Player !!!	2026-03-03 11:25:10.491278+05:30	\N
64	10	9	ECARD	59	Recognized with Agility Champion !!!	2026-03-03 11:25:18.036943+05:30	\N
65	10	9	ECARD	60	Recognized with Star of Innovation !!!	2026-03-03 11:25:24.18515+05:30	\N
66	10	9	ECARD	61	Recognized with You Rock !!!	2026-03-03 11:25:30.851605+05:30	\N
67	9	16	ECARD	62	thank you	2026-03-03 13:08:01.215823+05:30	\N
68	4	12	MANAGER_REWARD	4		2026-03-03 13:10:14.792521+05:30	\N
69	9	22	ECARD	63	u are the best 	2026-03-03 15:57:25.125976+05:30	\N
70	9	6	ECARD	64	Recognized with Out of Box Thinker !!!	2026-03-03 16:49:14.834801+05:30	\N
71	9	8	ECARD	65	thanks for completeing the work so fast 	2026-03-04 14:19:48.654118+05:30	\N
72	9	10	ECARD	66	thanks for the fantastic idea 	2026-03-04 14:20:21.645569+05:30	\N
73	9	22	ECARD	67	Recognized with Customer Hero !!!	2026-03-04 14:39:18.574913+05:30	\N
74	9	25	ECARD	68	thanks	2026-03-04 14:44:35.363661+05:30	\N
75	12	9	AWARD	35	Honored with the Above and Beyond Award! 🎉	2026-03-04 15:29:02.78995+05:30	\N
76	9	19	ECARD	69	Recognized with Invaluable Help !!!	2026-03-04 16:07:51.114533+05:30	\N
77	4	8	MANAGER_REWARD	4	Great work	2026-03-04 16:20:52.368033+05:30	\N
78	4	12	MANAGER_REWARD	4	keep up the hardwork	2026-03-05 09:53:29.189143+05:30	\N
79	4	10	MANAGER_REWARD	4	keep it up	2026-03-05 10:40:13.572514+05:30	\N
80	4	11	MANAGER_REWARD	4	keep up	2026-03-05 10:43:14.322347+05:30	\N
81	9	8	AWARD	36	Honored with the Above and Beyond Award! 🎉	2026-03-05 10:51:04.333488+05:30	\N
82	4	9	MANAGER_REWARD	4		2026-03-05 14:37:40.625292+05:30	\N
83	2	4	MANAGER_REWARD	2	keep up the good work	2026-03-05 14:39:34.091121+05:30	\N
84	9	11	ECARD	70	well done	2026-03-09 11:11:50.596973+05:30	\N
85	9	11	ECARD	71	what a great idea 	2026-03-09 22:05:39.261954+05:30	\N
86	4	11	AWARD	37	Honored with the Best Team Player Award! 🎉	2026-03-10 09:41:25.522103+05:30	\N
87	9	11	ECARD	72	thank you	2026-03-10 14:01:13.65445+05:30	\N
88	4	11	MANAGER_REWARD	4		2026-03-10 14:03:58.071783+05:30	\N
89	9	11	AWARD	38	Honored with the Above and Beyond Award! 🎉	2026-03-10 14:11:03.70338+05:30	\N
90	11	4	ECARD	73	Recognized with Customer Hero !!!	2026-03-11 12:02:31.509074+05:30	\N
91	12	9	ECARD	74	Recognized with Heartfelt Apology !!	2026-03-11 12:09:35.487805+05:30	\N
92	10	24	ECARD	75	Recognized with Partnership Pioneer !!!	2026-03-11 12:11:43.148691+05:30	\N
93	9	6	ECARD	76	Recognized with Out of Box Thinker !!!	2026-03-11 13:01:16.751476+05:30	\N
94	9	5	ECARD	77	Recognized with Invaluable Help !!!	2026-03-11 13:01:24.917399+05:30	\N
95	9	21	ECARD	78	Recognized with Great Team Player !!!	2026-03-11 13:01:32.770361+05:30	\N
96	9	27	ECARD	79	Recognized with Invaluable Help !!!	2026-03-11 13:01:41.408355+05:30	\N
97	19	9	AWARD	40	Honored with the Above and Beyond Award! 🎉	2026-03-11 14:19:50.687262+05:30	\N
98	1718	1719	ECARD	82	Great work on the project!	2026-03-17 11:46:31.861251+05:30	\N
99	1718	1719	ECARD	83	Great work on the project!	2026-03-17 11:47:12.929665+05:30	\N
100	1718	1719	ECARD	84	End-to-end test after FK removal!	2026-03-17 12:23:49.428232+05:30	\N
101	1718	1719	ECARD	85	Systematic endpoint test!	2026-03-17 12:26:35.639284+05:30	\N
102	9	1718	ECARD	86	good	2026-03-25 16:44:14.718464+05:30	\N
103	9	15	ECARD	87	goood	2026-03-25 16:45:03.342359+05:30	\N
104	1718	1698	ECARD	88	thank you	2026-03-27 12:12:46.94646+05:30	\N
105	1718	1674	ECARD	89	thanks 	2026-03-27 12:29:18.130916+05:30	\N
106	1718	1719	ECARD	90	test	2026-03-27 12:31:16.352501+05:30	\N
107	1718	11	ECARD	91	test	2026-03-27 17:25:42.900038+05:30	\N
108	1	2	CELEBRATION	4	Congratulations to Sarah Mitchell on their marriage! Wishing you a lifetime of happiness together! 💍	2026-03-30 10:53:18.570012+05:30	\N
109	1718	1719	ECARD	92	Recognized with Bright Spark !!!	2026-03-30 14:30:21.325789+05:30	\N
110	1718	1719	ECARD	93	Recognized with Agility Champion !!!	2026-03-30 15:33:43.245925+05:30	\N
111	1718	1719	ECARD	94	Recognized with Agility Champion !!!	2026-03-30 15:35:46.966721+05:30	\N
112	1718	1719	ECARD	96	Recognized with Agility Champion !!!	2026-03-31 14:31:04.809425+05:30	\N
113	1718	1651	ECARD	97	Recognized with Bright Spark !!!	2026-04-01 10:58:04.370329+05:30	\N
114	1	1718	AWARD	43	Honored with the Leadership Excellence Award! 🎉	2026-04-01 15:39:13.377044+05:30	\N
115	2	9	ECARD	98	test	2026-04-01 17:23:46.777471+05:30	General
116	9	1718	ECARD	99	Recognized with Customer Hero !!!	2026-04-01 17:25:01.044301+05:30	\N
\.


--
-- Data for Name: redemptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.redemptions (id, user_id, reward_id, points_used, status, created_at) FROM stdin;
5	9	16	800	FULFILLED	2026-02-23 13:34:12.102793+05:30
6	9	12	1500	FULFILLED	2026-02-24 14:09:55.965109+05:30
7	9	12	1500	FULFILLED	2026-02-24 14:10:23.05683+05:30
8	11	16	800	FULFILLED	2026-02-26 13:08:58.940905+05:30
9	11	14	2500	FULFILLED	2026-02-26 14:35:50.779097+05:30
10	12	16	800	FULFILLED	2026-03-04 14:47:48.040433+05:30
11	1718	12	1500	FULFILLED	2026-03-31 10:56:49.826336+05:30
12	1718	19	9000	FULFILLED	2026-03-31 11:05:57.336003+05:30
13	1718	13	2000	FULFILLED	2026-03-31 11:12:21.694202+05:30
14	1718	16	800	FULFILLED	2026-03-31 14:30:38.010104+05:30
15	1718	16	800	FULFILLED	2026-03-31 17:49:19.698445+05:30
16	1718	10	5000	FULFILLED	2026-03-31 17:50:53.560913+05:30
17	1718	16	800	FULFILLED	2026-04-09 11:40:52.172709+05:30
18	1718	16	800	FULFILLED	2026-04-10 16:49:24.874162+05:30
\.


--
-- Data for Name: rewards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rewards (id, name, reward_type, points_required, is_active, created_at, updated_at, stock, stock_quantity, image_url, cooldown_hours, consecutive_limit) FROM stdin;
16	Desk Plant	MERCH	800	t	2026-02-23 11:38:37.947259+05:30	2026-04-10 16:49:24.874162+05:30	\N	23	https://hips.hearstapps.com/hmg-prod/images/screen-shot-2023-07-06-at-2-04-54-pm-64a7024cb5493.png?crop=0.8432732316227461xw:1xh;center,top&resize=1200:*	\N	\N
15	Uber Eats $15 Voucher	GIFT_CARD	1500	t	2026-02-23 11:38:37.947259+05:30	2026-02-24 14:27:32.674571+05:30	\N	100	https://c.dlnws.com/image/upload/f_auto,t_maximum,q_auto/content/gs4alj7hvvd3lqkw7ls2.png	\N	\N
11	Ergonomic Office Chair	MERCH	12000	t	2026-02-23 11:38:37.947259+05:30	2026-02-25 16:47:54.068768+05:30	\N	2	https://m.media-amazon.com/images/I/71aGX3PevYL._AC_UF894,1000_QL80_.jpg	\N	\N
14	Amazon $25 Gift Card	GIFT_CARD	2500	t	2026-02-23 11:38:37.947259+05:30	2026-02-26 14:35:50.779097+05:30	\N	99	https://m.media-amazon.com/images/I/51iMYoUUN5L.jpg	\N	\N
17	Experience Day (Spa/Workshop)	MERCH	8000	t	2026-02-23 11:38:37.947259+05:30	2026-03-04 10:52:38.635096+05:30	\N	0	\N	\N	\N
18	Bluetooth Speaker	MERCH	3500	t	2026-02-23 11:38:37.947259+05:30	2026-03-06 15:03:52.079303+05:30	\N	10	https://media.tatacroma.com/Croma%20Assets/Entertainment/Speakers%20and%20Media%20Players/Images/251614_0_ghxuff.png	\N	\N
12	Premium Coffee Gift Set	MERCH	1500	t	2026-02-23 11:38:37.947259+05:30	2026-03-31 10:56:49.826336+05:30	\N	17	https://giftcarnation.com/cdn/shop/products/Coffee-1.png?v=1690741376	\N	\N
19	Fitness Tracker	MERCH	9000	t	2026-02-23 11:38:37.947259+05:30	2026-03-31 11:05:57.336003+05:30	\N	3	https://m.media-amazon.com/images/I/61AeGQhwjxL.jpg	\N	\N
13	Company Hoodie	MERCH	2000	t	2026-02-23 11:38:37.947259+05:30	2026-03-31 11:12:21.694202+05:30	\N	49	https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTioom3BiZyQocQA5smzYbwWFXyfsQoaz_SBA&s	\N	\N
10	Noise-Cancelling Headphones	MERCH	5000	t	2026-02-23 11:38:37.947259+05:30	2026-03-31 17:50:53.560913+05:30	\N	4	https://cdn.thewirecutter.com/wp-content/media/2023/09/noise-cancelling-headphone-2048px-0876.jpg	\N	\N
\.


--
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_config (key, value, description, updated_at) FROM stdin;
feature.conversion_enabled	true	Enable / disable the Points-to-Cash (Payroll Encashment) conversion feature.	2026-03-04 16:29:48.393412+05:30
feature.email_notifications_enabled	true	Global toggle: send email notifications (true/false)	2026-03-05 15:43:04.710655+05:30
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password, role, department_id, manager_id, date_of_joining, birth_date, created_at, email_notifications_enabled) FROM stdin;
1	Jennifer Scott	jennifer.scott@company.com	$2b$12$s5t4Lg6STfZT/PoD/jt8t.ZqY1uWjzdFOaI1jPB4gxmelm3sQJHzK	HR	\N	\N	2019-03-01	1982-07-14	2026-02-19 14:02:07.009743+05:30	t
2	Sarah Mitchell	sarah.mitchell@company.com	$2b$12$hgi7ockfR0bO0icEwnL1YeXyfd6XDaNg.cMubHfGZPzcb5YHI8wvS	DEPT_HEAD	1	\N	2018-06-15	1980-04-22	2026-02-19 14:02:07.009743+05:30	t
3	James Carter	james.carter@company.com	$2b$12$MjXjH8m3omigGinVYK7fXupTYKIyLJmHtRxPMI0rbvzyGXJBkU3IO	DEPT_HEAD	2	\N	2018-09-01	1979-11-05	2026-02-19 14:02:07.009743+05:30	t
4	David Chen	david.chen@company.com	$2b$12$r2/svJrUnlK93nelQRPgt.B3tqhpaoM.HFuMaMQMWTaFSloAGm/92	MANAGER	1	2	2020-01-10	1985-08-30	2026-02-19 14:02:07.009743+05:30	t
6	Ryan Patel	ryan.patel@company.com	$2b$12$n.eHlN9wrfL91njABabRy.qVuIQupZWgcGoIgf/W2OL8V5oO7K5Qm	MANAGER	2	3	2020-05-11	1986-12-09	2026-02-19 14:02:07.009743+05:30	t
7	Alex Morgan	alex.morgan@company.com	$2b$12$atCeNE1M.2FsIh16n2vgtuc7i2I4t.F8RrGdxqa321CPY9aA06q3e	MANAGER	2	3	2020-07-19	1988-05-25	2026-02-19 14:02:07.009743+05:30	t
8	Sophie Williams	sophie.williams@company.com	$2b$12$CcZ8SwERmOoCZbWngLhhtO5XpntD60gQvBn55imPHfdOLyNkeMwSC	EMPLOYEE	1	4	2021-02-08	1995-03-14	2026-02-19 14:02:07.009743+05:30	t
10	Isabella Brown	isabella.brown@company.com	$2b$12$6WgKYx6IN/TnodeACj/38Oht0ZpK.Y8.vux8.fXsPyBAnF5yk.Xv6	EMPLOYEE	1	4	2021-06-14	1997-01-07	2026-02-19 14:02:07.009743+05:30	t
11	Liam Johnson	liam.johnson@company.com	$2b$12$zIBaOzG7kjycmIqBKBrAWO/ChhWHZGhUJyiNEhxFt0s2JoyEFIzjO	EMPLOYEE	1	4	2021-08-23	1994-06-30	2026-02-19 14:02:07.009743+05:30	t
12	Michael Thompson	michael.thompson@company.com	$2b$12$b05b59Q2Vqp42azqLXI2Sejg8Uahc9tWkE9YGHqPRuMIZnrIKoAK2	EMPLOYEE	1	4	2021-10-05	1993-11-17	2026-02-19 14:02:07.009743+05:30	t
13	Olivia Harris	olivia.harris@company.com	$2b$12$Qs0AWiHXuopP4owBv2du1O1PFMvYAl4dmOGbWnKmTbypbdOdYfLXq	EMPLOYEE	1	5	2022-01-17	1998-04-02	2026-02-19 14:02:07.009743+05:30	t
14	Daniel Wilson	daniel.wilson@company.com	$2b$12$2q.fJFY5wPZ7opNXwCFxEeLaOldZz5uhPSuLyEXZcEGiCGflTFSlW	EMPLOYEE	1	5	2022-03-29	1997-08-19	2026-02-19 14:02:07.009743+05:30	t
15	Emma Davis	emma.davis@company.com	$2b$12$VCILW6ktoAKH.qACA53PKOBVmwJu0YXp5Lv0K7xdDgRl2WcXSxD66	EMPLOYEE	1	5	2022-05-11	1999-02-25	2026-02-19 14:02:07.009743+05:30	t
16	Lucas Martinez	lucas.martinez@company.com	$2b$12$JW9P6A7EG2VzLgDrx/Acb.SSc4IRkf5w1ebu7mI8GixwU9J4TtdHC	EMPLOYEE	1	5	2022-07-04	1996-12-11	2026-02-19 14:02:07.009743+05:30	t
17	Ava Robinson	ava.robinson@company.com	$2b$12$PCj2x9sRJ/l1EqBuslZsK.AmE7/xGY1.JKP7xgM2mgWFkR0Pdkjfy	EMPLOYEE	1	5	2022-09-20	1995-07-08	2026-02-19 14:02:07.009743+05:30	t
18	Ethan Clark	ethan.clark@company.com	$2b$12$aBos9VYfp.v4A9HfJaiVauDxjHaZXKSbd.vPZebyhC29T1Djbl/vu	EMPLOYEE	2	6	2021-03-15	1994-05-22	2026-02-19 14:02:07.009743+05:30	t
19	Mia Lewis	mia.lewis@company.com	$2b$12$JbaaWlNKStMlvHDjRT8evOvXQB3xKPS6D8ngLj5NS3rRMw/8NyqMq	EMPLOYEE	2	6	2021-05-27	1997-10-14	2026-02-19 14:02:07.009743+05:30	t
20	Benjamin Walker	benjamin.walker@company.com	$2b$12$0j0k3y5p9/wu3pg2S6uQ6uOpEaNzUhLqu0CyPunrIngtk5OLWKTnK	EMPLOYEE	2	6	2021-08-09	1995-01-31	2026-02-19 14:02:07.009743+05:30	t
21	Charlotte Hall	charlotte.hall@company.com	$2b$12$h4O4XUJ9NCpR2GVOIsOv1uUY/9yVBIyqmhqJvyCStU3HANe5uayZW	EMPLOYEE	2	6	2021-11-03	1998-06-17	2026-02-19 14:02:07.009743+05:30	t
22	Sophia Bennett	sophia.bennett@company.com	$2b$12$hgi7ockfR0bO0icEwnL1YeXyfd6XDaNg.cMubHfGZPzcb5YHI8wvS	EMPLOYEE	2	6	2022-01-25	1996-03-08	2026-02-19 14:02:07.009743+05:30	t
23	Jack Wilson	jack.wilson@company.com	$2b$12$MjXjH8m3omigGinVYK7fXupTYKIyLJmHtRxPMI0rbvzyGXJBkU3IO	EMPLOYEE	2	7	2022-02-14	1993-09-25	2026-02-19 14:02:07.009743+05:30	t
24	Chloe Anderson	chloe.anderson@company.com	$2b$12$r2/svJrUnlK93nelQRPgt.B3tqhpaoM.HFuMaMQMWTaFSloAGm/92	EMPLOYEE	2	7	2022-04-19	1997-04-12	2026-02-19 14:02:07.009743+05:30	t
25	Mason Taylor	mason.taylor@company.com	$2b$12$cN2CXRzxFfQAO7/y.NbsbucYRlyWUp2CF3.L9GowgCMMeHy2dulGC	EMPLOYEE	2	7	2022-06-30	1995-08-04	2026-02-19 14:02:07.009743+05:30	t
26	Grace Thomas	grace.thomas@company.com	$2b$12$n.eHlN9wrfL91njABabRy.qVuIQupZWgcGoIgf/W2OL8V5oO7K5Qm	EMPLOYEE	2	7	2022-09-07	1998-11-29	2026-02-19 14:02:07.009743+05:30	t
27	Henry Jackson	henry.jackson@company.com	$2b$12$atCeNE1M.2FsIh16n2vgtuc7i2I4t.F8RrGdxqa321CPY9aA06q3e	EMPLOYEE	2	7	2022-11-22	1994-02-23	2026-02-19 14:02:07.009743+05:30	t
5	Emily Turner	emily.turner@company.com	$2b$12$cN2CXRzxFfQAO7/y.NbsbucYRlyWUp2CF3.L9GowgCMMeHy2dulGC	MANAGER	1	2	2020-03-22	1987-02-27	2026-02-19 14:02:07.009743+05:30	t
9	Noah Adams	noah.adams@company.com	$2b$12$68L6jfFTQ.Tk9tJdt.gv3ewfYCN4TZR29IGcH0XOMVywodhFP5NF6	EMPLOYEE	1	4	2021-03-05	1996-09-21	2026-02-19 14:02:07.009743+05:30	t
1718	Fidaan Hussain P	fidaan.hussain@tarento.com	$2b$12$4fndZA7IMmHWgh43JWfxLOMYQx4oJSieOSaiBPskqXDN6IMp555.2	EMPLOYEE	51	\N	\N	2002-08-13	2026-03-16 15:14:37.467015+05:30	t
1698	Rabeeh c v	rabeeh.cheriya@tarento.com	$2b$12$e7Qcst6F5oHOxmlpdSU3ROAsXCNHCzsOK0LpiQlDW5srT1cTHCxWS	UNKNOWN	51	\N	\N	2001-02-28	2026-03-27 12:12:46.674604+05:30	t
1674	Abhilash Manikoth	abhilash.manikoth@tarento.com	$2b$12$BEa9DtJRI.B3R7EeSY5oDu9vt./2sGqDN/RnfQAZ9a8vhvuko7ME2	EMPLOYEE	51	\N	\N	2024-07-26	2026-03-27 12:29:17.865181+05:30	t
1719	Athira A K	athira.ambali@tarento.com	$2b$12$FrY4.KyNak4UXUD1BCe5NO0bno.UKpayp28lLujEEiJeJxXZ9Muqm	EMPLOYEE	51	\N	\N	2001-03-23	2026-03-27 12:31:16.120055+05:30	t
1651	ccddf	oiuytrewdfc	$2b$12$8Ud9n7UoQpMDJ/Brm0WQOeupUIMwgi91gqgJDYs/X.fDel9YyvIFu	EMPLOYEE	1	\N	\N	\N	2026-04-01 10:58:04.09861+05:30	t
\.


--
-- Data for Name: wallet_funding; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallet_funding (id, manager_wallet_id, funded_by, points, created_at) FROM stdin;
38	17	1	500	2026-02-20 15:16:59.732289+05:30
39	23	1	1000	2026-02-20 15:21:17.034862+05:30
40	17	1	1000	2026-02-23 12:08:23.442865+05:30
41	17	1	3000	2026-02-23 12:09:02.705812+05:30
42	23	1	3000	2026-02-23 12:09:02.726473+05:30
43	25	1	3000	2026-02-23 12:09:02.752487+05:30
44	26	1	3000	2026-02-23 12:09:02.773935+05:30
45	35	1	2000	2026-02-26 10:20:32.191108+05:30
46	17	1	2000	2026-02-26 10:20:47.015266+05:30
47	17	1	2000	2026-02-26 10:21:06.557395+05:30
48	25	1	3000	2026-02-26 10:23:01.437805+05:30
49	36	1	3000	2026-02-26 10:30:54.489134+05:30
55	35	1	1000	2026-03-03 13:13:09.818091+05:30
56	17	1	3000	2026-03-05 14:38:31.42059+05:30
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallets (id, user_id, wallet_type, balance, created_at) FROM stdin;
45	15	EMPLOYEE	50	2026-03-25 16:45:03.325929+05:30
23	5	MANAGER	4000	2026-02-20 15:21:17.02196+05:30
46	1698	EMPLOYEE	60	2026-03-27 12:12:46.92937+05:30
26	7	MANAGER	3000	2026-02-23 12:09:02.767651+05:30
47	1674	EMPLOYEE	50	2026-03-27 12:29:18.115207+05:30
40	16	EMPLOYEE	60	2026-03-03 13:08:01.188181+05:30
28	13	EMPLOYEE	300	2026-02-23 16:19:23.359076+05:30
48	1	EMPLOYEE	0	2026-03-27 16:36:27.72495+05:30
22	11	EMPLOYEE	1460	2026-02-20 12:41:38.343631+05:30
29	2	EMPLOYEE	1000	2026-02-23 17:04:05.974046+05:30
32	7	EMPLOYEE	0	2026-02-25 11:32:34.472617+05:30
33	7	EMPLOYEE	0	2026-02-25 11:32:34.47453+05:30
41	22	EMPLOYEE	120	2026-03-03 15:57:25.102835+05:30
34	25	EMPLOYEE	360	2026-02-25 15:13:23.212856+05:30
25	6	MANAGER	5700	2026-02-23 12:09:02.744354+05:30
42	19	EMPLOYEE	50	2026-03-04 16:07:51.087757+05:30
39	12	EMPLOYEE	300	2026-02-26 14:38:45.911393+05:30
36	3	MANAGER	4000	2026-02-26 10:30:54.477654+05:30
44	1719	EMPLOYEE	570	2026-03-17 11:46:31.834882+05:30
38	23	EMPLOYEE	65	2026-02-26 12:28:36.613922+05:30
24	10	EMPLOYEE	250	2026-02-23 11:07:33.955233+05:30
27	20	EMPLOYEE	360	2026-02-23 14:52:20.546344+05:30
49	1651	EMPLOYEE	50	2026-04-01 10:58:04.354875+05:30
19	8	EMPLOYEE	515	2026-02-19 14:26:15.150581+05:30
18	9	EMPLOYEE	210	2026-02-19 14:17:33.71618+05:30
43	1718	EMPLOYEE	3750	2026-03-17 10:56:56.572293+05:30
35	2	MANAGER	2000	2026-02-26 10:20:32.181468+05:30
17	4	MANAGER	2930	2026-02-19 14:09:09.994609+05:30
16	4	EMPLOYEE	2050	2026-02-19 14:08:50.230848+05:30
30	24	EMPLOYEE	280	2026-02-24 11:23:20.672055+05:30
21	6	EMPLOYEE	150	2026-02-19 15:52:58.542099+05:30
31	5	EMPLOYEE	50	2026-02-24 14:37:14.842059+05:30
20	21	EMPLOYEE	360	2026-02-19 15:26:12.982025+05:30
37	27	EMPLOYEE	100	2026-02-26 12:27:30.727959+05:30
\.


--
-- Name: award_approvals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.award_approvals_id_seq', 53, true);


--
-- Name: award_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.award_types_id_seq', 22, true);


--
-- Name: awards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.awards_id_seq', 44, true);


--
-- Name: badges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.badges_id_seq', 12, true);


--
-- Name: celebrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.celebrations_id_seq', 4, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departments_id_seq', 4, true);


--
-- Name: ecards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ecards_id_seq', 99, true);


--
-- Name: email_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_logs_id_seq', 68, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 314, true);


--
-- Name: points_batches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.points_batches_id_seq', 134, true);


--
-- Name: points_conversion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.points_conversion_id_seq', 31, true);


--
-- Name: points_ledger_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.points_ledger_id_seq', 255, true);


--
-- Name: points_policy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.points_policy_id_seq', 50, true);


--
-- Name: recognition_feed_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recognition_feed_id_seq', 116, true);


--
-- Name: redemptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.redemptions_id_seq', 18, true);


--
-- Name: rewards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rewards_id_seq', 19, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 27, true);


--
-- Name: wallet_funding_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wallet_funding_id_seq', 56, true);


--
-- Name: wallets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wallets_id_seq', 49, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: award_approvals award_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.award_approvals
    ADD CONSTRAINT award_approvals_pkey PRIMARY KEY (id);


--
-- Name: award_types award_types_award_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.award_types
    ADD CONSTRAINT award_types_award_key_key UNIQUE (award_key);


--
-- Name: award_types award_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.award_types
    ADD CONSTRAINT award_types_pkey PRIMARY KEY (id);


--
-- Name: awards awards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.awards
    ADD CONSTRAINT awards_pkey PRIMARY KEY (id);


--
-- Name: badges badges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (id);


--
-- Name: celebrations celebrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.celebrations
    ADD CONSTRAINT celebrations_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: ecards ecards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecards
    ADD CONSTRAINT ecards_pkey PRIMARY KEY (id);


--
-- Name: email_logs email_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_logs
    ADD CONSTRAINT email_logs_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: points_batches points_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_batches
    ADD CONSTRAINT points_batches_pkey PRIMARY KEY (id);


--
-- Name: points_conversion points_conversion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_conversion
    ADD CONSTRAINT points_conversion_pkey PRIMARY KEY (id);


--
-- Name: points_ledger points_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_ledger
    ADD CONSTRAINT points_ledger_pkey PRIMARY KEY (id);


--
-- Name: points_policy points_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_policy
    ADD CONSTRAINT points_policy_pkey PRIMARY KEY (id);


--
-- Name: recognition_feed recognition_feed_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recognition_feed
    ADD CONSTRAINT recognition_feed_pkey PRIMARY KEY (id);


--
-- Name: redemptions redemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_pkey PRIMARY KEY (id);


--
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (id);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (key);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wallet_funding wallet_funding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_funding
    ADD CONSTRAINT wallet_funding_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: ix_award_approvals_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_award_approvals_id ON public.award_approvals USING btree (id);


--
-- Name: ix_award_types_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_award_types_id ON public.award_types USING btree (id);


--
-- Name: ix_awards_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_awards_id ON public.awards USING btree (id);


--
-- Name: ix_badges_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_badges_id ON public.badges USING btree (id);


--
-- Name: ix_celebrations_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_celebrations_id ON public.celebrations USING btree (id);


--
-- Name: ix_departments_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_departments_id ON public.departments USING btree (id);


--
-- Name: ix_ecards_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ecards_id ON public.ecards USING btree (id);


--
-- Name: ix_email_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_email_logs_id ON public.email_logs USING btree (id);


--
-- Name: ix_email_logs_recipient_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_email_logs_recipient_email ON public.email_logs USING btree (recipient_email);


--
-- Name: ix_email_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_email_logs_user_id ON public.email_logs USING btree (user_id);


--
-- Name: ix_notifications_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_notifications_id ON public.notifications USING btree (id);


--
-- Name: ix_points_batches_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_points_batches_id ON public.points_batches USING btree (id);


--
-- Name: ix_points_conversion_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_points_conversion_id ON public.points_conversion USING btree (id);


--
-- Name: ix_points_ledger_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_points_ledger_id ON public.points_ledger USING btree (id);


--
-- Name: ix_points_policy_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_points_policy_id ON public.points_policy USING btree (id);


--
-- Name: ix_recognition_feed_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_recognition_feed_id ON public.recognition_feed USING btree (id);


--
-- Name: ix_redemptions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_redemptions_id ON public.redemptions USING btree (id);


--
-- Name: ix_rewards_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_rewards_id ON public.rewards USING btree (id);


--
-- Name: ix_system_config_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_system_config_key ON public.system_config USING btree (key);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_wallet_funding_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_wallet_funding_id ON public.wallet_funding USING btree (id);


--
-- Name: ix_wallets_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_wallets_id ON public.wallets USING btree (id);


--
-- Name: award_approvals award_approvals_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.award_approvals
    ADD CONSTRAINT award_approvals_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.awards(id);


--
-- Name: awards awards_award_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.awards
    ADD CONSTRAINT awards_award_type_id_fkey FOREIGN KEY (award_type_id) REFERENCES public.award_types(id);


--
-- Name: ecards ecards_badge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ecards
    ADD CONSTRAINT ecards_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(id);


--
-- Name: points_ledger points_ledger_source_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_ledger
    ADD CONSTRAINT points_ledger_source_wallet_id_fkey FOREIGN KEY (source_wallet_id) REFERENCES public.wallets(id);


--
-- Name: points_ledger points_ledger_target_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_ledger
    ADD CONSTRAINT points_ledger_target_wallet_id_fkey FOREIGN KEY (target_wallet_id) REFERENCES public.wallets(id);


--
-- Name: redemptions redemptions_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(id);


--
-- Name: users users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: users users_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.users(id);


--
-- Name: wallet_funding wallet_funding_manager_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_funding
    ADD CONSTRAINT wallet_funding_manager_wallet_id_fkey FOREIGN KEY (manager_wallet_id) REFERENCES public.wallets(id);


--
-- PostgreSQL database dump complete
--

\unrestrict mw8uZbTtQaL5yzY5Yk2bsSPny4WRtLmh3PNbccpRkVsib2fQQpM0CjEQg640SKE

