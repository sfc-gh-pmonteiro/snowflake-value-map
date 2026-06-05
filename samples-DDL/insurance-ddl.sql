-- ============================================================================
-- INSURANCE VERTICAL - Sample DDL
-- Source Systems: Guidewire (PolicyCenter, ClaimCenter, BillingCenter),
--                 Duck Creek (Rating/Forms), Verisk (ISO/AAIS data),
--                 Salesforce Financial Services Cloud
-- Entity: Guardian Insurance Group
-- ============================================================================

CREATE DATABASE IF NOT EXISTS GUARDIAN_INS;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS GUARDIAN_INS.SILVER;

-- Source: Guidewire PolicyCenter
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.GUIDEWIRE_POLICY (
    POLICY_ID           VARCHAR(30) NOT NULL,
    POLICY_NUMBER       VARCHAR(20),
    PRODUCT_LINE        VARCHAR(30),           -- COMMERCIAL_PROPERTY, COMMERCIAL_AUTO, GL, WC, BOP, PERSONAL_AUTO, HOMEOWNERS
    EFFECTIVE_DATE      DATE,
    EXPIRATION_DATE     DATE,
    STATUS              VARCHAR(20),           -- ACTIVE, CANCELLED, EXPIRED, NON_RENEWED, IN_FORCE
    PREMIUM_WRITTEN     NUMBER(12,2),
    DEDUCTIBLE          NUMBER(10,2),
    LIMIT_AMOUNT        NUMBER(12,2),
    INSURED_ID          VARCHAR(30),
    AGENT_ID            VARCHAR(20),
    UNDERWRITER_ID      VARCHAR(30),
    RISK_SCORE          NUMBER(5,2),
    PROGRAM             VARCHAR(50),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Guidewire PolicyCenter policies - SCD2. Full policy lifecycle tracking. Source: GW PolicyCenter.';

-- Source: Guidewire ClaimCenter
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.GUIDEWIRE_CLAIM (
    CLAIM_ID            VARCHAR(30) NOT NULL,
    CLAIM_NUMBER        VARCHAR(20),
    POLICY_ID           VARCHAR(30),
    DATE_OF_LOSS        DATE,
    DATE_REPORTED       DATE,
    CLAIMANT_ID         VARCHAR(30),
    CLAIM_TYPE          VARCHAR(30),           -- BODILY_INJURY, PROPERTY_DAMAGE, LIABILITY, COLLISION, COMP, WC
    STATUS              VARCHAR(20),           -- OPEN, CLOSED, REOPENED, SUBROGATION
    RESERVE_AMOUNT      NUMBER(12,2),
    PAID_AMOUNT         NUMBER(12,2),
    ADJUSTER_ID         VARCHAR(30),
    CATASTROPHE_ID      VARCHAR(20),
    LITIGATION_FLAG     BOOLEAN,
    FAULT_PCT           NUMBER(5,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Guidewire ClaimCenter claims. Loss and payment tracking. Source: GW ClaimCenter.';

-- Source: Guidewire BillingCenter
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.GUIDEWIRE_BILLING (
    BILLING_ID          VARCHAR(30) NOT NULL,
    POLICY_ID           VARCHAR(30),
    INVOICE_DATE        DATE,
    DUE_DATE            DATE,
    AMOUNT_DUE          NUMBER(12,2),
    AMOUNT_PAID         NUMBER(12,2),
    PAYMENT_METHOD      VARCHAR(20),           -- ACH, CHECK, CREDIT_CARD, EFT, WIRE
    STATUS              VARCHAR(20),           -- BILLED, PAID, PAST_DUE, WRITTEN_OFF, CANCELLED
    BILLING_PLAN        VARCHAR(20),           -- ANNUAL, SEMI_ANNUAL, QUARTERLY, MONTHLY
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Guidewire BillingCenter premium billing. Payment collection lifecycle. Source: GW BillingCenter.';

-- Source: Duck Creek (Rating)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.DUCK_CREEK_RATING (
    RATING_ID           VARCHAR(30) NOT NULL,
    POLICY_ID           VARCHAR(30),
    PRODUCT_LINE        VARCHAR(30),
    TERRITORY           VARCHAR(10),
    CLASS_CODE          VARCHAR(20),
    RATE_FACTOR         NUMBER(8,5),
    BASE_RATE           NUMBER(10,4),
    FINAL_PREMIUM       NUMBER(12,2),
    EFFECTIVE_DATE      DATE,
    EXPERIENCE_MOD      NUMBER(6,4),
    SCHEDULE_MOD        NUMBER(6,4),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Duck Creek rating calculations. Actuarial factors and premium derivation. Source: Duck Creek Rating.';

-- Source: Verisk (Property Data)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.VERISK_PROPERTY (
    PROPERTY_ID         VARCHAR(30) NOT NULL,
    ADDRESS             VARCHAR(300),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    CONSTRUCTION_TYPE   VARCHAR(30),           -- FRAME, MASONRY, NON_COMBUSTIBLE, FIRE_RESISTIVE
    YEAR_BUILT          NUMBER(4),
    SQUARE_FOOTAGE      NUMBER(10),
    ROOF_TYPE           VARCHAR(30),
    PROTECTION_CLASS    NUMBER(2),             -- 1-10 (ISO PPC)
    FLOOD_ZONE          VARCHAR(10),
    WILDFIRE_RISK_SCORE NUMBER(5,2),
    EARTHQUAKE_ZONE     VARCHAR(10),
    REPLACEMENT_COST    NUMBER(12,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Verisk property risk data. Hazard scoring and replacement costs. Source: Verisk/ISO.';

-- Source: Salesforce Financial Services Cloud (Insureds)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.SFDC_INSURED (
    INSURED_ID          VARCHAR(30) NOT NULL,
    ACCOUNT_NAME        VARCHAR(200),
    ACCOUNT_TYPE        VARCHAR(20),           -- INDIVIDUAL, COMMERCIAL, NON_PROFIT
    INDUSTRY            VARCHAR(50),
    ANNUAL_REVENUE      NUMBER(15,2),
    EMPLOYEE_COUNT      NUMBER(10),
    ADDRESS             VARCHAR(300),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    AGENT_ID            VARCHAR(20),
    RELATIONSHIP_START  DATE,
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce FSC insured accounts - SCD2. Customer master. Source: SFDC Financial Services Cloud.';

-- Source: Salesforce Financial Services Cloud (Agents)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.SFDC_AGENT (
    AGENT_ID            VARCHAR(20) NOT NULL,
    AGENT_NAME          VARCHAR(200),
    AGENCY_NAME         VARCHAR(200),
    STATE               VARCHAR(5),
    LICENSE_NUMBER      VARCHAR(30),
    APPOINTED_DATE      DATE,
    COMMISSION_TIER     VARCHAR(10),           -- PLATINUM, GOLD, SILVER, BRONZE
    STATUS              VARCHAR(20),           -- ACTIVE, SUSPENDED, TERMINATED
    LINES_OF_AUTHORITY  VARIANT,              -- JSON array: ["PROPERTY", "CASUALTY", "LIFE"]
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce agent/producer master. Distribution channel management. Source: SFDC FSC.';

-- Source: Guidewire ClaimCenter (Reserve Transactions)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.GUIDEWIRE_RESERVE_TRANSACTION (
    TRANSACTION_ID      VARCHAR(30) NOT NULL,
    CLAIM_ID            VARCHAR(30),
    RESERVE_TYPE        VARCHAR(30),           -- INDEMNITY, EXPENSE, MEDICAL, LEGAL
    AMOUNT              NUMBER(12,2),
    TRANSACTION_DATE    DATE,
    ADJUSTER_ID         VARCHAR(30),
    NOTE                VARCHAR(1000),
    TRANSACTION_TYPE    VARCHAR(20),           -- INITIAL, INCREASE, DECREASE, PAYMENT
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Guidewire reserve transactions. Claim development tracking. Source: GW ClaimCenter.';

-- Source: Verisk (Catastrophe Events)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.VERISK_CATASTROPHE (
    CATASTROPHE_ID      VARCHAR(20) NOT NULL,
    CAT_NAME            VARCHAR(200),
    CAT_TYPE            VARCHAR(30),           -- HURRICANE, TORNADO, HAIL, WILDFIRE, FLOOD, WINTER_STORM, EARTHQUAKE
    EVENT_DATE          DATE,
    STATES_AFFECTED     VARIANT,              -- JSON array: ["FL", "GA", "SC"]
    ESTIMATED_INDUSTRY_LOSS NUMBER(15,2),
    PCS_NUMBER          VARCHAR(10),
    DURATION_DAYS       NUMBER(5),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Verisk PCS catastrophe events. Industry loss benchmarks. Source: Verisk/PCS.';

-- Source: Guidewire (Reinsurance)
CREATE OR REPLACE TABLE GUARDIAN_INS.SILVER.GUIDEWIRE_REINSURANCE (
    TREATY_ID           VARCHAR(30) NOT NULL,
    TREATY_NAME         VARCHAR(200),
    REINSURER           VARCHAR(200),
    LAYER               NUMBER(3),
    ATTACHMENT_POINT    NUMBER(12,2),
    LIMIT_AMOUNT        NUMBER(12,2),
    RATE                NUMBER(8,6),
    EFFECTIVE_DATE      DATE,
    EXPIRATION_DATE     DATE,
    TREATY_TYPE         VARCHAR(30),           -- QUOTA_SHARE, EXCESS_OF_LOSS, SURPLUS, FACULTATIVE
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Guidewire reinsurance treaties. Cession and recovery structures. Source: GW ReinsuranceMgmt.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS GUARDIAN_INS.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.DIM_INSURED (
    INSURED_KEY         NUMBER AUTOINCREMENT,
    INSURED_ID          VARCHAR(30) NOT NULL,
    ACCOUNT_NAME        VARCHAR(200),
    ACCOUNT_TYPE        VARCHAR(20),
    INDUSTRY            VARCHAR(50),
    STATE               VARCHAR(5),
    REGION              VARCHAR(50),
    ANNUAL_REVENUE      NUMBER(15,2),
    EMPLOYEE_COUNT      NUMBER(10),
    RELATIONSHIP_YEARS  NUMBER(5,1),
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Insured dimension - SCD2. Customer master from SFDC + Guidewire.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.DIM_POLICY (
    POLICY_KEY          NUMBER AUTOINCREMENT,
    POLICY_ID           VARCHAR(30) NOT NULL,
    POLICY_NUMBER       VARCHAR(20),
    PRODUCT_LINE        VARCHAR(30),
    EFFECTIVE_DATE      DATE,
    EXPIRATION_DATE     DATE,
    STATUS              VARCHAR(20),
    INSURED_KEY         NUMBER,
    AGENT_KEY           NUMBER,
    DEDUCTIBLE          NUMBER(10,2),
    LIMIT_AMOUNT        NUMBER(12,2)
) COMMENT = 'Policy dimension. Coverage details and lifecycle state.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.DIM_AGENT (
    AGENT_KEY           NUMBER AUTOINCREMENT,
    AGENT_ID            VARCHAR(20) NOT NULL,
    AGENT_NAME          VARCHAR(200),
    AGENCY_NAME         VARCHAR(200),
    STATE               VARCHAR(5),
    COMMISSION_TIER     VARCHAR(10),
    STATUS              VARCHAR(20),
    APPOINTED_DATE      DATE,
    TENURE_YEARS        NUMBER(5,1)
) COMMENT = 'Agent/producer dimension. Distribution channel performance tracking.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.DIM_PRODUCT (
    PRODUCT_KEY         NUMBER AUTOINCREMENT,
    PRODUCT_LINE        VARCHAR(30) NOT NULL,
    COVERAGE_TYPE       VARCHAR(30),
    SUB_LINE            VARCHAR(30),
    IS_COMMERCIAL       BOOLEAN,
    DESCRIPTION         VARCHAR(200)
) COMMENT = 'Product/line of business dimension.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_BUSINESS_DAY     BOOLEAN,
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2),
    ACCIDENT_YEAR       NUMBER(4),
    ACCIDENT_MONTH      NUMBER(2)
) COMMENT = 'Date dimension with accident year/month for actuarial triangles.';

-- Facts
CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.FACT_PREMIUM (
    PREMIUM_KEY         NUMBER AUTOINCREMENT,
    DATE_KEY            NUMBER,
    POLICY_KEY          NUMBER,
    PRODUCT_KEY         NUMBER,
    AGENT_KEY           NUMBER,
    INSURED_KEY         NUMBER,
    WRITTEN_PREMIUM     NUMBER(12,2),
    EARNED_PREMIUM      NUMBER(12,2),
    CEDED_PREMIUM       NUMBER(12,2),
    NET_PREMIUM         NUMBER(12,2),
    COMMISSION_AMOUNT   NUMBER(12,2)
) COMMENT = 'Premium fact. Written, earned, and ceded premium allocation.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.FACT_CLAIM (
    CLAIM_KEY           NUMBER AUTOINCREMENT,
    DATE_KEY            NUMBER,
    POLICY_KEY          NUMBER,
    INSURED_KEY         NUMBER,
    PRODUCT_KEY         NUMBER,
    CLAIM_TYPE          VARCHAR(30),
    INCURRED_AMOUNT     NUMBER(12,2),
    PAID_AMOUNT         NUMBER(12,2),
    RESERVE_AMOUNT      NUMBER(12,2),
    STATUS              VARCHAR(20),
    DAYS_TO_SETTLE      NUMBER(5),
    DAYS_TO_REPORT      NUMBER(5),
    LITIGATION_FLAG     BOOLEAN,
    CATASTROPHE_FLAG    BOOLEAN
) COMMENT = 'Claim fact. Incurred, paid, and reserve amounts with timing metrics.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.FACT_LOSS_DEVELOPMENT (
    EVALUATION_DATE_KEY NUMBER,
    ACCIDENT_MONTH_KEY  NUMBER,
    PRODUCT_KEY         NUMBER,
    PAID_CUMULATIVE     NUMBER(15,2),
    INCURRED_CUMULATIVE NUMBER(15,2),
    CASE_RESERVE        NUMBER(15,2),
    IBNR_ESTIMATE       NUMBER(15,2),
    DEVELOPMENT_FACTOR  NUMBER(8,6),
    CLAIM_COUNT         NUMBER(10),
    CLOSED_COUNT        NUMBER(10)
) COMMENT = 'Loss development triangle fact. Actuarial reserving and IBNR estimation.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.FACT_BILLING (
    BILLING_KEY         NUMBER AUTOINCREMENT,
    DATE_KEY            NUMBER,
    POLICY_KEY          NUMBER,
    INSURED_KEY         NUMBER,
    BILLED_AMOUNT       NUMBER(12,2),
    COLLECTED_AMOUNT    NUMBER(12,2),
    OUTSTANDING_BALANCE NUMBER(12,2),
    DAYS_PAST_DUE       NUMBER(5),
    WRITE_OFF_AMOUNT    NUMBER(12,2)
) COMMENT = 'Billing collection fact. Premium receivables and aging.';

-- Aggregates
CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.AGG_COMBINED_RATIO (
    MONTH_KEY           NUMBER,
    PRODUCT_KEY         NUMBER,
    EARNED_PREMIUM      NUMBER(15,2),
    INCURRED_LOSSES     NUMBER(15,2),
    LAE_EXPENSE         NUMBER(15,2),
    UNDERWRITING_EXPENSE NUMBER(15,2),
    LOSS_RATIO          NUMBER(7,4),
    EXPENSE_RATIO       NUMBER(7,4),
    COMBINED_RATIO      NUMBER(7,4),
    NET_UNDERWRITING_INCOME NUMBER(15,2)
) COMMENT = 'Monthly combined ratio by product. Core underwriting profitability metric.';

CREATE OR REPLACE TABLE GUARDIAN_INS.GOLD.AGG_AGENT_PRODUCTION (
    MONTH_KEY           NUMBER,
    AGENT_KEY           NUMBER,
    PRODUCT_KEY         NUMBER,
    POLICIES_WRITTEN    NUMBER(10),
    PREMIUM_WRITTEN     NUMBER(12,2),
    POLICIES_RENEWED    NUMBER(10),
    RETENTION_RATE      NUMBER(5,4),
    LOSS_RATIO          NUMBER(7,4),
    HIT_RATIO           NUMBER(5,4),           -- Quotes bound / quotes issued
    NEW_BUSINESS_PCT    NUMBER(5,4)
) COMMENT = 'Monthly agent production and book quality. Distribution performance management.';
