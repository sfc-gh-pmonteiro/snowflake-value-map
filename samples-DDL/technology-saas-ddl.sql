-- ============================================================================
-- TECHNOLOGY / SaaS VERTICAL - Sample DDL
-- Source Systems: Segment (product events), Stripe (billing/subscriptions),
--                 Salesforce (CRM/pipeline), PagerDuty (incidents),
--                 Snowflake Information Schema (infra usage)
-- Entity: Nexus Platform Inc (B2B SaaS, developer tools)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS NEXUS_SAAS;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS NEXUS_SAAS.SILVER;

-- Source: Segment (Product Analytics)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.SEGMENT_PRODUCT_EVENT (
    EVENT_ID            VARCHAR(50) NOT NULL,
    USER_ID             VARCHAR(30),
    TENANT_ID           VARCHAR(30),
    EVENT_NAME          VARCHAR(100),      -- page_viewed, feature_used, api_call, build_triggered, deploy_completed
    EVENT_TIMESTAMP     TIMESTAMP_NTZ NOT NULL,
    PROPERTIES          VARIANT,           -- JSON: {feature, duration_ms, status, error_code, ...}
    SESSION_ID          VARCHAR(50),
    DEVICE_TYPE         VARCHAR(20),       -- DESKTOP, MOBILE, API, CLI, SDK
    SDK_VERSION         VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Segment product events. Clickstream and API usage. Source: Segment tracking API.';

-- Source: Stripe (Subscriptions)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.STRIPE_SUBSCRIPTION (
    SUBSCRIPTION_ID     VARCHAR(30) NOT NULL,
    TENANT_ID           VARCHAR(30),
    PLAN_ID             VARCHAR(30),
    STATUS              VARCHAR(20),       -- ACTIVE, TRIALING, PAST_DUE, CANCELED, UNPAID
    START_DATE          DATE,
    CANCEL_DATE         DATE,
    TRIAL_END           DATE,
    MRR_CENTS           NUMBER(12),
    BILLING_INTERVAL    VARCHAR(10),       -- MONTHLY, ANNUAL
    PAYMENT_METHOD      VARCHAR(20),       -- CARD, ACH, WIRE, INVOICE
    CANCEL_REASON       VARCHAR(50),       -- TOO_EXPENSIVE, MISSING_FEATURES, COMPETITOR, NOT_USING
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Stripe subscriptions. MRR tracking and churn reasons. Source: Stripe API.';

-- Source: Stripe (Invoices)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.STRIPE_INVOICE (
    INVOICE_ID          VARCHAR(30) NOT NULL,
    SUBSCRIPTION_ID     VARCHAR(30),
    TENANT_ID           VARCHAR(30),
    INVOICE_DATE        DATE,
    AMOUNT_DUE          NUMBER(12,2),
    AMOUNT_PAID         NUMBER(12,2),
    STATUS              VARCHAR(20),       -- PAID, OPEN, VOID, UNCOLLECTIBLE
    LINE_ITEMS          VARIANT,           -- JSON array: [{description, amount, quantity, ...}]
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Stripe invoices with line-item detail. Source: Stripe Invoices API.';

-- Source: Salesforce CRM (Accounts)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.SFDC_ACCOUNT (
    ACCOUNT_ID          VARCHAR(30) NOT NULL,
    TENANT_ID           VARCHAR(30),
    COMPANY_NAME        VARCHAR(200),
    INDUSTRY            VARCHAR(50),
    EMPLOYEE_COUNT      NUMBER(10),
    ARR                 NUMBER(15,2),
    PLAN_TIER           VARCHAR(20),       -- FREE, STARTER, PROFESSIONAL, ENTERPRISE, CUSTOM
    CSM_ID              VARCHAR(30),
    REGION              VARCHAR(30),       -- NA, EMEA, APAC, LATAM
    SIGNUP_DATE         DATE,
    HEALTH_SCORE        NUMBER(5,2),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce CRM accounts - SCD2. Health score from CS platform. Source: sf_account.';

-- Source: Salesforce CRM (Opportunities)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.SFDC_OPPORTUNITY (
    OPP_ID              VARCHAR(30) NOT NULL,
    ACCOUNT_ID          VARCHAR(30),
    STAGE               VARCHAR(30),       -- PROSPECTING, DEMO, EVALUATION, NEGOTIATION, CLOSED_WON, CLOSED_LOST
    AMOUNT              NUMBER(15,2),
    CLOSE_DATE          DATE,
    PRODUCT             VARCHAR(50),
    OPP_TYPE            VARCHAR(20),       -- NEW_BUSINESS, EXPANSION, RENEWAL
    SOURCE              VARCHAR(30),       -- INBOUND, OUTBOUND, PARTNER, PLG, REFERRAL
    OWNER_ID            VARCHAR(30),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce CRM opportunities/pipeline. Source: sf_opportunity.';

-- Source: PagerDuty (Incident Management)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.PAGERDUTY_INCIDENT (
    INCIDENT_ID         VARCHAR(30) NOT NULL,
    TENANT_ID           VARCHAR(30),
    SEVERITY            VARCHAR(10),       -- P1, P2, P3, P4
    TITLE               VARCHAR(500),
    CREATED_AT          TIMESTAMP_NTZ,
    RESOLVED_AT         TIMESTAMP_NTZ,
    SERVICE_NAME        VARCHAR(100),
    ESCALATION_COUNT    NUMBER(3),
    ACKNOWLEDGED_BY     VARCHAR(100),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'PagerDuty incidents affecting tenants. Reliability and SLA tracking.';

-- Source: Segment (User Identity)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.SEGMENT_IDENTIFY (
    USER_ID             VARCHAR(30) NOT NULL,
    TENANT_ID           VARCHAR(30),
    EMAIL               VARCHAR(200),
    ROLE                VARCHAR(30),       -- ADMIN, DEVELOPER, VIEWER, BILLING
    CREATED_AT          TIMESTAMP_NTZ,
    LAST_SEEN           TIMESTAMP_NTZ,
    NAME                VARCHAR(200),
    PROPERTIES          VARIANT,           -- JSON: {team, department, invite_source, ...}
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Segment identify calls. User profile data. Source: Segment Identify API.';

-- Source: Stripe (Usage Records)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.STRIPE_USAGE_RECORD (
    RECORD_ID           VARCHAR(50) NOT NULL,
    SUBSCRIPTION_ID     VARCHAR(30),
    TENANT_ID           VARCHAR(30),
    USAGE_TIMESTAMP     TIMESTAMP_NTZ,
    METRIC_NAME         VARCHAR(50),       -- API_CALLS, BUILDS, COMPUTE_MINUTES, STORAGE_GB, SEATS
    QUANTITY            NUMBER(15,4),
    UNIT                VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Stripe metered usage records. Usage-based billing input. Source: Stripe Usage API.';

-- Source: Salesforce CRM (Support Cases)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.SFDC_SUPPORT_CASE (
    CASE_ID             VARCHAR(30) NOT NULL,
    TENANT_ID           VARCHAR(30),
    SUBJECT             VARCHAR(500),
    PRIORITY            VARCHAR(10),       -- P1, P2, P3, P4
    STATUS              VARCHAR(20),       -- NEW, IN_PROGRESS, WAITING, RESOLVED, CLOSED
    CREATED_DATE        DATE,
    CLOSED_DATE         DATE,
    CATEGORY            VARCHAR(30),       -- BUG, FEATURE_REQUEST, HOW_TO, INTEGRATION, BILLING
    CSAT_SCORE          NUMBER(2),         -- 1-5
    ESCALATED_FLAG      BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce support cases. CSAT and escalation tracking. Source: sf_case.';

-- Source: Snowflake Information Schema (Infrastructure)
CREATE OR REPLACE TABLE NEXUS_SAAS.SILVER.INFRA_COMPUTE_USAGE (
    TENANT_ID           VARCHAR(30) NOT NULL,
    USAGE_DATE          DATE NOT NULL,
    WAREHOUSE_NAME      VARCHAR(100),
    CREDITS_USED        NUMBER(12,4),
    QUERIES_RUN         NUMBER(10),
    BYTES_SCANNED       NUMBER(15),
    AVG_QUEUE_TIME_MS   NUMBER(10,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Per-tenant infrastructure usage from Snowflake metadata. Multi-tenant cost attribution.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS NEXUS_SAAS.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.DIM_TENANT (
    TENANT_KEY          NUMBER AUTOINCREMENT,
    TENANT_ID           VARCHAR(30) NOT NULL,
    COMPANY_NAME        VARCHAR(200),
    INDUSTRY            VARCHAR(50),
    PLAN_TIER           VARCHAR(20),
    ARR                 NUMBER(15,2),
    EMPLOYEE_COUNT      NUMBER(10),
    REGION              VARCHAR(30),
    COHORT_MONTH        DATE,
    CSM_ID              VARCHAR(30),
    SIGNUP_DATE         DATE,
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Tenant (customer) dimension - SCD2. Unified from SFDC + Stripe.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.DIM_USER (
    USER_KEY            NUMBER AUTOINCREMENT,
    USER_ID             VARCHAR(30) NOT NULL,
    TENANT_KEY          NUMBER,
    ROLE                VARCHAR(30),
    SIGNUP_DATE         DATE,
    NAME                VARCHAR(200),
    EMAIL_DOMAIN        VARCHAR(100)
) COMMENT = 'User dimension. Individual product users within tenants.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.DIM_FEATURE (
    FEATURE_KEY         NUMBER AUTOINCREMENT,
    FEATURE_NAME        VARCHAR(100) NOT NULL,
    MODULE              VARCHAR(50),
    RELEASE_DATE        DATE,
    CATEGORY            VARCHAR(30)        -- CORE, ADVANCED, BETA, INTEGRATION, ADMIN
) COMMENT = 'Feature/capability dimension. Maps events to product features.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_BUSINESS_DAY     BOOLEAN,
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2)
) COMMENT = 'Standard date dimension.';

-- Facts
CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.FACT_PRODUCT_USAGE (
    DATE_KEY            NUMBER,
    TENANT_KEY          NUMBER,
    USER_KEY            NUMBER,
    FEATURE_KEY         NUMBER,
    EVENTS              NUMBER(10),
    SESSIONS            NUMBER(10),
    ACTIVE_MINUTES      NUMBER(10,2)
) COMMENT = 'Daily product usage fact. User-feature grain. Core engagement metric.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.FACT_SUBSCRIPTION (
    DATE_KEY            NUMBER,
    TENANT_KEY          NUMBER,
    MRR                 NUMBER(12,2),
    ARR                 NUMBER(15,2),
    PLAN_KEY            NUMBER,
    STATUS              VARCHAR(20),
    EXPANSION_FLAG      BOOLEAN,
    CONTRACTION_FLAG    BOOLEAN,
    SEATS               NUMBER(10)
) COMMENT = 'Subscription fact. Monthly MRR/ARR snapshots with movement flags.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.FACT_BILLING (
    DATE_KEY            NUMBER,
    TENANT_KEY          NUMBER,
    INVOICED_AMOUNT     NUMBER(12,2),
    COLLECTED_AMOUNT    NUMBER(12,2),
    USAGE_CHARGES       NUMBER(12,2),
    OVERAGE_AMOUNT      NUMBER(12,2),
    DISCOUNT_AMOUNT     NUMBER(12,2)
) COMMENT = 'Billing fact. Invoiced vs collected with usage breakdown.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.FACT_SUPPORT (
    DATE_KEY            NUMBER,
    TENANT_KEY          NUMBER,
    CASES_OPENED        NUMBER(10),
    CASES_CLOSED        NUMBER(10),
    AVG_RESOLUTION_HOURS NUMBER(10,2),
    CSAT_AVG            NUMBER(3,1),
    ESCALATIONS         NUMBER(5),
    P1_INCIDENTS        NUMBER(5)
) COMMENT = 'Support/incident fact. Monthly grain. Includes severity breakdown.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.FACT_INFRASTRUCTURE (
    DATE_KEY            NUMBER,
    TENANT_KEY          NUMBER,
    COMPUTE_CREDITS     NUMBER(12,4),
    STORAGE_TB          NUMBER(10,4),
    QUERIES             NUMBER(10),
    AVG_LATENCY_MS      NUMBER(10,2),
    ERROR_RATE_PCT      NUMBER(5,4)
) COMMENT = 'Infrastructure consumption fact. Multi-tenant cost attribution.';

-- Aggregates
CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.AGG_TENANT_HEALTH (
    MONTH_KEY           NUMBER,
    TENANT_KEY          NUMBER,
    PRODUCT_USAGE_SCORE NUMBER(5,2),
    SUPPORT_SCORE       NUMBER(5,2),
    PAYMENT_SCORE       NUMBER(5,2),
    EXPANSION_SIGNAL    NUMBER(5,4),
    CHURN_RISK_SCORE    NUMBER(5,4),
    HEALTH_TIER         VARCHAR(10),       -- GREEN, YELLOW, RED
    RECOMMENDED_ACTION  VARCHAR(50)
) COMMENT = 'Monthly tenant health composite. Multi-signal churn risk and expansion signals.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.AGG_COHORT_METRICS (
    COHORT_MONTH_KEY    NUMBER,
    MONTHS_SINCE_SIGNUP NUMBER(5),
    ACTIVE_TENANTS      NUMBER(10),
    CHURNED_TENANTS     NUMBER(10),
    NET_RETENTION_PCT   NUMBER(7,4),
    EXPANSION_PCT       NUMBER(7,4),
    GROSS_RETENTION_PCT NUMBER(7,4),
    AVG_ARR             NUMBER(15,2)
) COMMENT = 'Cohort retention analysis. Net and gross dollar retention by signup cohort.';

CREATE OR REPLACE TABLE NEXUS_SAAS.GOLD.AGG_FEATURE_ADOPTION (
    MONTH_KEY           NUMBER,
    FEATURE_KEY         NUMBER,
    TENANTS_USING       NUMBER(10),
    USERS_USING         NUMBER(10),
    ADOPTION_PCT        NUMBER(5,4),
    STICKINESS_PCT      NUMBER(5,4),       -- DAU/MAU ratio
    AVG_EVENTS_PER_USER NUMBER(10,2)
) COMMENT = 'Monthly feature adoption. Stickiness (DAU/MAU) and breadth of adoption.';
