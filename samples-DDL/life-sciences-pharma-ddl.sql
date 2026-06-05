-- ============================================================================
-- LIFE SCIENCES & PHARMA VERTICAL - Sample DDL
-- Source Systems: Veeva Vault (CTMS/eTMF), Oracle Argus (Safety/Pharmacovigilance),
--                 SAP S/4HANA (Manufacturing), IQVIA (Commercial Data),
--                 Salesforce (Commercial CRM)
-- Entity: Helix Pharmaceuticals
-- ============================================================================

CREATE DATABASE IF NOT EXISTS HELIX_PHARMA;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS HELIX_PHARMA.SILVER;

-- Source: Veeva Vault CTMS (Clinical Trial Management)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.VEEVA_TRIAL (
    TRIAL_ID            VARCHAR(20) NOT NULL,
    PROTOCOL_NUMBER     VARCHAR(30),
    TRIAL_PHASE         VARCHAR(10),           -- PHASE_1, PHASE_2, PHASE_2B, PHASE_3, PHASE_4
    THERAPEUTIC_AREA    VARCHAR(50),           -- ONCOLOGY, IMMUNOLOGY, CNS, CARDIOVASCULAR, RARE_DISEASE
    INDICATION          VARCHAR(100),
    COMPOUND_ID         VARCHAR(20),
    SPONSOR             VARCHAR(100),
    START_DATE          DATE,
    ESTIMATED_END_DATE  DATE,
    TARGET_ENROLLMENT   NUMBER(6),
    ACTUAL_ENROLLMENT   NUMBER(6),
    STATUS              VARCHAR(20),           -- PLANNING, RECRUITING, ACTIVE, CLOSED, TERMINATED
    REGULATORY_AUTHORITY VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Veeva Vault CTMS trial master. Protocol metadata and enrollment targets.';

-- Source: Veeva Vault CTMS (Trial Sites)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.VEEVA_SITE (
    SITE_ID             VARCHAR(20) NOT NULL,
    TRIAL_ID            VARCHAR(20),
    INVESTIGATOR_NAME   VARCHAR(200),
    INSTITUTION         VARCHAR(200),
    COUNTRY             VARCHAR(5),
    STATE               VARCHAR(5),
    ACTIVATION_DATE     DATE,
    STATUS              VARCHAR(20),           -- IDENTIFIED, SELECTED, ACTIVATED, ENROLLING, CLOSED
    TARGET_ENROLLMENT   NUMBER(5),
    ACTUAL_ENROLLMENT   NUMBER(5),
    SCREEN_FAILURE_COUNT NUMBER(5),
    QUERY_COUNT         NUMBER(5),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Veeva Vault CTMS site records. Investigator site performance tracking.';

-- Source: Veeva Vault CTMS (Trial Subjects)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.VEEVA_SUBJECT (
    SUBJECT_ID          VARCHAR(20) NOT NULL,
    TRIAL_ID            VARCHAR(20),
    SITE_ID             VARCHAR(20),
    RANDOMIZATION_DATE  DATE,
    ARM                 VARCHAR(30),           -- TREATMENT, PLACEBO, CONTROL, DOSE_1, DOSE_2
    SCREENING_DATE      DATE,
    CONSENT_DATE        DATE,
    STATUS              VARCHAR(20),           -- SCREENED, RANDOMIZED, ACTIVE, COMPLETED, WITHDRAWN
    WITHDRAWAL_REASON   VARCHAR(50),           -- ADVERSE_EVENT, LOST_TO_FOLLOWUP, CONSENT_WITHDRAWN, PROTOCOL_DEVIATION
    LAST_VISIT_DATE     DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Veeva Vault CTMS subject records. Enrollment funnel and disposition.';

-- Source: Oracle Argus (Safety/Pharmacovigilance)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.ARGUS_ADVERSE_EVENT (
    CASE_ID             VARCHAR(20) NOT NULL,
    SUBJECT_ID          VARCHAR(20),
    COMPOUND_ID         VARCHAR(20),
    EVENT_TERM          VARCHAR(200),          -- MedDRA preferred term
    SOC                 VARCHAR(100),          -- System Organ Class
    SERIOUSNESS         VARCHAR(20),           -- SERIOUS, NON_SERIOUS
    SEVERITY            VARCHAR(10),           -- MILD, MODERATE, SEVERE
    CAUSALITY           VARCHAR(20),           -- RELATED, POSSIBLY_RELATED, UNLIKELY, UNRELATED
    ONSET_DATE          DATE,
    REPORT_DATE         DATE,
    OUTCOME             VARCHAR(20),           -- RECOVERED, RECOVERING, NOT_RECOVERED, FATAL, UNKNOWN
    REPORTER_TYPE       VARCHAR(20),           -- INVESTIGATOR, SPONTANEOUS, LITERATURE, REGULATORY
    REGULATORY_AUTHORITY VARCHAR(20),
    EXPEDITED_FLAG      BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle Argus safety cases. Adverse event reporting and signal detection.';

-- Source: SAP S/4HANA (Batch Manufacturing)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.SAP_BATCH_RECORD (
    BATCH_ID            VARCHAR(20) NOT NULL,
    MATERIAL_NUMBER     VARCHAR(40),
    PRODUCT_NAME        VARCHAR(200),
    MANUFACTURING_SITE  VARCHAR(50),
    BATCH_START         TIMESTAMP_NTZ,
    BATCH_END           TIMESTAMP_NTZ,
    BATCH_SIZE          NUMBER(12,3),
    BATCH_SIZE_UOM      VARCHAR(10),
    YIELD_PCT           NUMBER(5,2),
    DISPOSITION         VARCHAR(20),           -- RELEASED, REJECTED, QUARANTINE, REWORK
    DEVIATION_COUNT     NUMBER(3),
    GMP_STATUS          VARCHAR(20),           -- COMPLIANT, NON_COMPLIANT, UNDER_REVIEW
    EXPIRY_DATE         DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP S/4HANA batch production records. GMP manufacturing and quality disposition.';

-- Source: SAP S/4HANA (Deviations/CAPA)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.SAP_DEVIATION (
    DEVIATION_ID        VARCHAR(20) NOT NULL,
    BATCH_ID            VARCHAR(20),
    DEVIATION_TYPE      VARCHAR(30),           -- PROCESS, EQUIPMENT, MATERIAL, DOCUMENTATION, ENVIRONMENTAL
    SEVERITY            VARCHAR(10),           -- CRITICAL, MAJOR, MINOR
    ROOT_CAUSE          VARCHAR(200),
    CAPA_ID             VARCHAR(20),
    OPEN_DATE           DATE,
    CLOSE_DATE          DATE,
    STATUS              VARCHAR(20),           -- OPEN, INVESTIGATING, CAPA_ASSIGNED, CLOSED, ESCALATED
    IMPACT_ASSESSMENT   VARCHAR(500),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP deviations and CAPA records. Manufacturing quality events and corrective actions.';

-- Source: IQVIA (Prescription/Commercial Data)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.IQVIA_PRESCRIPTION (
    RX_ID               VARCHAR(30) NOT NULL,
    NDC                 VARCHAR(15),
    PRODUCT_NAME        VARCHAR(200),
    PRESCRIBER_NPI      VARCHAR(15),
    PRESCRIBER_SPECIALTY VARCHAR(50),
    PHARMACY_ID         VARCHAR(20),
    DISPENSE_DATE       DATE,
    QUANTITY            NUMBER(10),
    DAYS_SUPPLY         NUMBER(3),
    NEW_RX_FLAG         BOOLEAN,
    REFILL_NUMBER       NUMBER(3),
    PAYER_TYPE          VARCHAR(20),           -- COMMERCIAL, MEDICARE, MEDICAID, CASH
    TERRITORY_ID        VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'IQVIA prescription-level data. De-identified Rx dispensing for commercial analytics.';

-- Source: Salesforce (HCP Interactions)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.SFDC_HCP_INTERACTION (
    INTERACTION_ID      VARCHAR(30) NOT NULL,
    HCP_ID              VARCHAR(20),
    REP_ID              VARCHAR(20),
    INTERACTION_TYPE    VARCHAR(20),           -- FACE_TO_FACE, VIRTUAL, PHONE, EMAIL, CONGRESS
    DATE                DATE,
    PRODUCT_DISCUSSED   VARCHAR(100),
    SAMPLES_LEFT        NUMBER(3),
    KEY_MESSAGE         VARCHAR(200),
    SENTIMENT           VARCHAR(20),           -- POSITIVE, NEUTRAL, NEGATIVE
    NEXT_STEPS          VARCHAR(500),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce HCP interaction records. Sales rep detailing and engagement tracking.';

-- Source: Veeva Vault (Clinical Endpoint Data)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.VEEVA_ENDPOINT_DATA (
    ENDPOINT_ID         VARCHAR(30) NOT NULL,
    TRIAL_ID            VARCHAR(20),
    SUBJECT_ID          VARCHAR(20),
    VISIT_NUMBER        NUMBER(3),
    ASSESSMENT_DATE     DATE,
    ENDPOINT_NAME       VARCHAR(100),          -- PRIMARY_EFFICACY, SECONDARY_EFFICACY, BIOMARKER, PRO
    ENDPOINT_VALUE      NUMBER(15,4),
    BASELINE_VALUE      NUMBER(15,4),
    CHANGE_FROM_BASELINE NUMBER(15,4),
    RESPONDER_FLAG      BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Veeva Vault clinical endpoint assessments. Efficacy measurements by visit.';

-- Source: SAP S/4HANA (Stability Testing)
CREATE OR REPLACE TABLE HELIX_PHARMA.SILVER.SAP_STABILITY_TEST (
    TEST_ID             VARCHAR(20) NOT NULL,
    BATCH_ID            VARCHAR(20),
    CONDITION           VARCHAR(30),           -- 25C_60RH, 30C_65RH, 40C_75RH (ICH conditions)
    TIMEPOINT_MONTHS    NUMBER(3),
    TEST_DATE           DATE,
    PARAMETER           VARCHAR(50),           -- ASSAY, DISSOLUTION, IMPURITY, MOISTURE, APPEARANCE
    RESULT              NUMBER(10,4),
    RESULT_UOM          VARCHAR(20),
    SPECIFICATION_MIN   NUMBER(10,4),
    SPECIFICATION_MAX   NUMBER(10,4),
    PASS_FLAG           BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP stability test results. ICH guideline compliance for shelf-life determination.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS HELIX_PHARMA.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.DIM_COMPOUND (
    COMPOUND_KEY        NUMBER AUTOINCREMENT,
    COMPOUND_ID         VARCHAR(20) NOT NULL,
    MOLECULE_NAME       VARCHAR(100),
    GENERIC_NAME        VARCHAR(100),
    THERAPEUTIC_AREA    VARCHAR(50),
    INDICATION          VARCHAR(100),
    MECHANISM_OF_ACTION VARCHAR(100),
    CURRENT_PHASE       VARCHAR(10),
    FIRST_IN_HUMAN_DATE DATE,
    ROUTE_OF_ADMIN      VARCHAR(20)
) COMMENT = 'Compound/molecule dimension. Pipeline assets and therapeutic classification.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.DIM_TRIAL (
    TRIAL_KEY           NUMBER AUTOINCREMENT,
    TRIAL_ID            VARCHAR(20) NOT NULL,
    PROTOCOL_NUMBER     VARCHAR(30),
    TRIAL_PHASE         VARCHAR(10),
    INDICATION          VARCHAR(100),
    STATUS              VARCHAR(20),
    TARGET_ENROLLMENT   NUMBER(6),
    ACTUAL_ENROLLMENT   NUMBER(6),
    START_DATE          DATE,
    SITE_COUNT          NUMBER(5)
) COMMENT = 'Trial dimension. Clinical study metadata and enrollment status.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.DIM_SITE (
    SITE_KEY            NUMBER AUTOINCREMENT,
    SITE_ID             VARCHAR(20) NOT NULL,
    INSTITUTION         VARCHAR(200),
    INVESTIGATOR_NAME   VARCHAR(200),
    COUNTRY             VARCHAR(5),
    STATE               VARCHAR(5),
    ACTIVATION_DATE     DATE,
    PERFORMANCE_TIER    VARCHAR(10)            -- HIGH, MEDIUM, LOW
) COMMENT = 'Investigator site dimension. Site capability and performance classification.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_WORKING_DAY      BOOLEAN
) COMMENT = 'Standard date dimension.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.DIM_PRODUCT (
    PRODUCT_KEY         NUMBER AUTOINCREMENT,
    PRODUCT_ID          VARCHAR(20) NOT NULL,
    PRODUCT_NAME        VARCHAR(200),
    NDC                 VARCHAR(15),
    THERAPEUTIC_AREA    VARCHAR(50),
    LAUNCH_DATE         DATE,
    DOSAGE_FORM         VARCHAR(30),
    STRENGTH            VARCHAR(20),
    MARKET_STATUS       VARCHAR(20)            -- PRE_LAUNCH, ACTIVE, MATURE, DECLINING
) COMMENT = 'Commercial product dimension. Marketed drug portfolio.';

-- Facts
CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.FACT_ENROLLMENT (
    DATE_KEY            NUMBER,
    TRIAL_KEY           NUMBER,
    SITE_KEY            NUMBER,
    SCREENED            NUMBER(5),
    RANDOMIZED          NUMBER(5),
    COMPLETED           NUMBER(5),
    WITHDRAWN           NUMBER(5),
    SCREEN_FAIL_COUNT   NUMBER(5),
    SCREEN_FAIL_RATE    NUMBER(5,4),
    ENROLLMENT_RATE     NUMBER(7,2)            -- Subjects per site per month
) COMMENT = 'Clinical enrollment fact. Recruitment funnel metrics by site.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.FACT_ADVERSE_EVENT (
    DATE_KEY            NUMBER,
    COMPOUND_KEY        NUMBER,
    TRIAL_KEY           NUMBER,
    SOC                 VARCHAR(100),
    TOTAL_EVENTS        NUMBER(5),
    SERIOUS_EVENTS      NUMBER(5),
    RELATED_EVENTS      NUMBER(5),
    FATAL_EVENTS        NUMBER(3),
    EXPEDITED_REPORTS   NUMBER(3),
    SUBJECTS_AFFECTED   NUMBER(5)
) COMMENT = 'Safety/adverse event fact. Aggregate AE counts for signal detection.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.FACT_COMMERCIAL_RX (
    DATE_KEY            NUMBER,
    PRODUCT_KEY         NUMBER,
    TERRITORY_ID        VARCHAR(20),
    TOTAL_RX            NUMBER(10),
    NEW_RX              NUMBER(10),
    REFILL_RX           NUMBER(10),
    TOTAL_UNITS         NUMBER(12),
    MARKET_SHARE_PCT    NUMBER(5,4),
    NBR_PRESCRIBERS     NUMBER(5),
    PAYER_MIX_COMMERCIAL_PCT NUMBER(5,4)
) COMMENT = 'Commercial prescription fact. Rx volume, share, and territory performance.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.FACT_MANUFACTURING (
    DATE_KEY            NUMBER,
    PRODUCT_KEY         NUMBER,
    MANUFACTURING_SITE  VARCHAR(50),
    BATCHES_PRODUCED    NUMBER(5),
    BATCHES_RELEASED    NUMBER(5),
    BATCHES_REJECTED    NUMBER(3),
    YIELD_AVG           NUMBER(5,2),
    DEVIATIONS          NUMBER(5),
    CRITICAL_DEVIATIONS NUMBER(3),
    RIGHT_FIRST_TIME_PCT NUMBER(5,4)
) COMMENT = 'Manufacturing quality fact. Batch disposition and yield performance.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.FACT_HCP_ENGAGEMENT (
    DATE_KEY            NUMBER,
    PRODUCT_KEY         NUMBER,
    REP_ID              VARCHAR(20),
    TERRITORY_ID        VARCHAR(20),
    CALLS               NUMBER(5),
    SAMPLES_DELIVERED   NUMBER(5),
    REACH_PCT           NUMBER(5,4),
    FREQUENCY           NUMBER(5,2),
    POSITIVE_SENTIMENT_PCT NUMBER(5,4),
    UNIQUE_HCPS_SEEN    NUMBER(5)
) COMMENT = 'HCP engagement fact. Sales force effectiveness and reach/frequency.';

-- Aggregates
CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.AGG_TRIAL_PERFORMANCE (
    TRIAL_KEY           NUMBER,
    SITE_KEY            NUMBER,
    MONTH_KEY           NUMBER,
    ENROLLMENT_RATE     NUMBER(7,2),
    SCREEN_FAIL_PCT     NUMBER(5,4),
    QUERY_RATE          NUMBER(7,2),           -- Queries per subject
    PROTOCOL_DEVIATION_RATE NUMBER(5,4),
    DATA_ENTRY_CYCLE_DAYS NUMBER(5,1),
    SITE_RANK           NUMBER(5)
) COMMENT = 'Monthly trial performance by site. Operational efficiency benchmarking.';

CREATE OR REPLACE TABLE HELIX_PHARMA.GOLD.AGG_SAFETY_SIGNAL (
    COMPOUND_KEY        NUMBER,
    MONTH_KEY           NUMBER,
    EVENT_TERM          VARCHAR(200),
    SOC                 VARCHAR(100),
    OBSERVED_COUNT      NUMBER(5),
    EXPECTED_COUNT      NUMBER(7,2),
    PRO_SCORE           NUMBER(7,4),           -- Proportional Reporting Ratio
    SIGNAL_FLAG         BOOLEAN,
    SERIOUSNESS_RATIO   NUMBER(5,4),
    CASE_TREND          VARCHAR(10)            -- INCREASING, STABLE, DECREASING
) COMMENT = 'Monthly safety signal detection. PRR-based disproportionality analysis.';

