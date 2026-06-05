-- ============================================================================
-- FINANCIAL SERVICES VERTICAL - Sample DDL
-- Source Systems: SAP FICO (GL/AP/AR), Salesforce Financial Services Cloud,
--                 FIS/Temenos (Core Banking), Bloomberg (Market Data), Custom Risk Engine
-- Entity: Pinnacle Financial Holdings
-- ============================================================================

CREATE DATABASE IF NOT EXISTS PINNACLE_FIN;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS PINNACLE_FIN.SILVER;

-- Source: FIS Core Banking (Customer)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.FIS_CUSTOMER (
    CUSTOMER_ID         VARCHAR(20) NOT NULL,
    CUSTOMER_TYPE       VARCHAR(10),       -- INDIVIDUAL, JOINT, CORPORATE, TRUST
    FIRST_NAME          VARCHAR(100),
    LAST_NAME           VARCHAR(100),
    COMPANY_NAME        VARCHAR(200),
    DATE_OF_BIRTH       DATE,
    SSN_HASH            VARCHAR(64),
    ADDRESS_LINE_1      VARCHAR(200),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    COUNTRY             VARCHAR(5),
    PHONE_PRIMARY       VARCHAR(20),
    EMAIL               VARCHAR(200),
    KYC_STATUS          VARCHAR(20),       -- VERIFIED, PENDING, EXPIRED, ENHANCED
    KYC_LAST_REVIEW     DATE,
    RISK_RATING         VARCHAR(10),       -- LOW, MEDIUM, HIGH
    ONBOARDING_DATE     DATE,
    RELATIONSHIP_MANAGER VARCHAR(50),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'FIS Core Banking customer master - SCD2. KYC status tracked.';

-- Source: FIS Core Banking (Accounts)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.FIS_ACCOUNT (
    ACCOUNT_ID          VARCHAR(20) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    ACCOUNT_TYPE        VARCHAR(20),       -- CHECKING, SAVINGS, MONEY_MARKET, CD, LOAN, MORTGAGE, CREDIT_CARD
    ACCOUNT_SUBTYPE     VARCHAR(30),
    PRODUCT_CODE        VARCHAR(20),
    OPEN_DATE           DATE,
    CLOSE_DATE          DATE,
    STATUS              VARCHAR(20),       -- ACTIVE, DORMANT, CLOSED, FROZEN
    BRANCH_ID           VARCHAR(10),
    CURRENCY            VARCHAR(5),
    INTEREST_RATE       NUMBER(7,5),
    CREDIT_LIMIT        NUMBER(15,2),
    ORIGINAL_BALANCE    NUMBER(15,2),
    TERM_MONTHS         NUMBER(5),
    COLLATERAL_TYPE     VARCHAR(30),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'FIS Core Banking account master - SCD2. All product types.';

-- Source: FIS Core Banking (Transactions)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.FIS_TRANSACTION (
    TRANSACTION_ID      VARCHAR(30) NOT NULL,
    ACCOUNT_ID          VARCHAR(20),
    TRANSACTION_DATE    DATE,
    TRANSACTION_DATETIME TIMESTAMP_NTZ,
    TRANSACTION_TYPE    VARCHAR(20),       -- DEBIT, CREDIT, TRANSFER, FEE, INTEREST, PAYMENT
    TRANSACTION_CODE    VARCHAR(10),
    DESCRIPTION         VARCHAR(300),
    AMOUNT              NUMBER(15,2),
    RUNNING_BALANCE     NUMBER(15,2),
    CHANNEL             VARCHAR(20),       -- BRANCH, ATM, ONLINE, MOBILE, ACH, WIRE
    MERCHANT_NAME       VARCHAR(200),
    MERCHANT_CATEGORY   VARCHAR(10),       -- MCC code
    COUNTERPARTY_ACCOUNT VARCHAR(20),
    GEOLOCATION         VARCHAR(50),
    DEVICE_ID           VARCHAR(50),
    IP_ADDRESS          VARCHAR(50),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'FIS Core Banking transactions. All channels. High-volume event data.';

-- Source: FIS Core Banking (Daily Balances)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.FIS_DAILY_BALANCE (
    ACCOUNT_ID          VARCHAR(20) NOT NULL,
    BALANCE_DATE        DATE NOT NULL,
    LEDGER_BALANCE      NUMBER(15,2),
    AVAILABLE_BALANCE   NUMBER(15,2),
    HOLD_AMOUNT         NUMBER(15,2),
    ACCRUED_INTEREST    NUMBER(15,4),
    DAYS_PAST_DUE       NUMBER(5),
    DELINQUENCY_STATUS  VARCHAR(10),       -- CURRENT, 30DPD, 60DPD, 90DPD, CHARGE_OFF
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'FIS daily account balance snapshots. Delinquency tracking for credit risk.';

-- Source: Custom Risk Engine (Credit Scoring)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.RISK_CREDIT_SCORE (
    CUSTOMER_ID         VARCHAR(20) NOT NULL,
    SCORE_DATE          DATE NOT NULL,
    FICO_SCORE          NUMBER(3),
    INTERNAL_SCORE      NUMBER(5,2),
    PD_12M              NUMBER(7,6),       -- Probability of Default 12-month
    LGD_ESTIMATE        NUMBER(5,4),       -- Loss Given Default
    EAD_AMOUNT          NUMBER(15,2),      -- Exposure at Default
    DEBT_TO_INCOME      NUMBER(5,4),
    UTILIZATION_RATE    NUMBER(5,4),
    PAYMENT_HISTORY_SCORE NUMBER(5,2),
    MODEL_VERSION       VARCHAR(20),
    SCORE_REASON_CODES  VARIANT,           -- JSON array of top decline/score reasons
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Internal credit risk scoring engine output. PD/LGD/EAD for Basel compliance.';

-- Source: Custom Risk Engine (Fraud Alerts)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.RISK_FRAUD_ALERT (
    ALERT_ID            VARCHAR(30) NOT NULL,
    TRANSACTION_ID      VARCHAR(30),
    ACCOUNT_ID          VARCHAR(20),
    CUSTOMER_ID         VARCHAR(20),
    ALERT_DATETIME      TIMESTAMP_NTZ,
    ALERT_TYPE          VARCHAR(30),       -- VELOCITY, GEO_ANOMALY, AMOUNT_ANOMALY, PATTERN, DEVICE
    RISK_SCORE          NUMBER(5,4),
    ALERT_STATUS        VARCHAR(20),       -- OPEN, INVESTIGATING, CONFIRMED_FRAUD, FALSE_POSITIVE
    DISPOSITION         VARCHAR(30),
    ANALYST_ID          VARCHAR(50),
    RESOLUTION_DATETIME TIMESTAMP_NTZ,
    FRAUD_AMOUNT        NUMBER(15,2),
    RULE_TRIGGERED      VARCHAR(100),
    FEATURE_VECTOR      VARIANT,           -- JSON feature snapshot at alert time
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Real-time fraud detection alerts. Feature vectors stored for model feedback.';

-- Source: SAP FICO (General Ledger)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.SAP_GL_POSTING (
    DOCUMENT_NUMBER     VARCHAR(20) NOT NULL,
    LINE_ITEM           NUMBER(5) NOT NULL,
    COMPANY_CODE        VARCHAR(10),
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2),
    POSTING_DATE        DATE,
    GL_ACCOUNT          VARCHAR(20),
    COST_CENTER         VARCHAR(20),
    PROFIT_CENTER       VARCHAR(20),
    AMOUNT_LOCAL        NUMBER(15,2),
    CURRENCY_LOCAL      VARCHAR(5),
    AMOUNT_GROUP        NUMBER(15,2),
    CURRENCY_GROUP      VARCHAR(5),
    DEBIT_CREDIT        VARCHAR(1),
    REFERENCE           VARCHAR(50),
    TEXT                VARCHAR(200),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP FICO General Ledger postings. Source: BSEG/BKPF tables.';

-- Source: Salesforce Financial Services Cloud (CRM)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.SFDC_FINANCIAL_ACCOUNT (
    SF_ACCOUNT_ID       VARCHAR(30) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    HOUSEHOLD_ID        VARCHAR(20),
    FINANCIAL_ACCOUNT_NAME VARCHAR(200),
    ACCOUNT_TYPE        VARCHAR(30),
    ASSETS_UNDER_MGMT   NUMBER(15,2),
    ANNUAL_REVENUE      NUMBER(15,2),
    RELATIONSHIP_START  DATE,
    ADVISOR_ID          VARCHAR(30),
    SEGMENT             VARCHAR(30),       -- MASS_MARKET, AFFLUENT, HNW, UHNW
    NEXT_REVIEW_DATE    DATE,
    LIFE_EVENT_FLAGS    VARIANT,           -- JSON {retirement: true, new_home: false, ...}
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce FSC financial accounts/relationships. Wealth segmentation.';

-- Source: Salesforce Financial Services Cloud (Interactions)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.SFDC_INTERACTION (
    INTERACTION_ID      VARCHAR(30) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    HOUSEHOLD_ID        VARCHAR(20),
    INTERACTION_TYPE    VARCHAR(30),       -- MEETING, CALL, EMAIL, REVIEW, REFERRAL
    CHANNEL             VARCHAR(20),
    SUBJECT             VARCHAR(200),
    NOTES               VARCHAR(4000),
    OUTCOME             VARCHAR(50),
    ADVISOR_ID          VARCHAR(30),
    INTERACTION_DATE    DATE,
    NEXT_ACTION         VARCHAR(200),
    OPPORTUNITY_ID      VARCHAR(30),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce FSC advisor interactions. Relationship management activities.';

-- Source: Bloomberg (Market Data)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.BLOOMBERG_SECURITY_PRICE (
    SECURITY_ID         VARCHAR(20) NOT NULL,    -- Internal ID
    TICKER              VARCHAR(20),
    CUSIP               VARCHAR(12),
    ISIN                VARCHAR(15),
    PRICE_DATE          DATE NOT NULL,
    OPEN_PRICE          NUMBER(15,6),
    HIGH_PRICE          NUMBER(15,6),
    LOW_PRICE           NUMBER(15,6),
    CLOSE_PRICE         NUMBER(15,6),
    VOLUME              NUMBER(15),
    CURRENCY            VARCHAR(5),
    ASSET_CLASS         VARCHAR(20),       -- EQUITY, FIXED_INCOME, FX, COMMODITY, DERIVATIVE
    SECTOR              VARCHAR(50),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Bloomberg end-of-day security prices. OHLCV. Source: Bloomberg Terminal API.';

-- Source: FIS Core Banking (Investment Positions)
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.FIS_PORTFOLIO_POSITION (
    POSITION_ID         VARCHAR(30) NOT NULL,
    ACCOUNT_ID          VARCHAR(20),
    CUSTOMER_ID         VARCHAR(20),
    SECURITY_ID         VARCHAR(20),
    POSITION_DATE       DATE NOT NULL,
    QUANTITY            NUMBER(15,6),
    COST_BASIS          NUMBER(15,2),
    MARKET_VALUE        NUMBER(15,2),
    UNREALIZED_PL       NUMBER(15,2),
    WEIGHT_PCT          NUMBER(5,4),
    ASSET_CLASS         VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'FIS portfolio positions. Daily snapshots for performance and risk analytics.';

-- Source: Custom AML System
CREATE OR REPLACE TABLE PINNACLE_FIN.SILVER.AML_SUSPICIOUS_ACTIVITY (
    SAR_ID              VARCHAR(30) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    DETECTION_DATE      DATE,
    ACTIVITY_TYPE       VARCHAR(50),       -- STRUCTURING, RAPID_MOVEMENT, UNUSUAL_PATTERN, SANCTIONS_HIT
    TRANSACTION_IDS     ARRAY,
    TOTAL_AMOUNT        NUMBER(15,2),
    RISK_SCORE          NUMBER(5,4),
    STATUS              VARCHAR(20),       -- OPEN, INVESTIGATING, FILED, CLOSED_NO_ACTION
    ANALYST_ID          VARCHAR(50),
    NARRATIVE           VARCHAR(4000),
    FILED_DATE          DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'AML suspicious activity reports. BSA/FinCEN compliance pipeline.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS PINNACLE_FIN.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.DIM_CUSTOMER (
    CUSTOMER_KEY        NUMBER AUTOINCREMENT,
    CUSTOMER_ID         VARCHAR(20) NOT NULL,
    CUSTOMER_TYPE       VARCHAR(10),
    FULL_NAME           VARCHAR(200),
    AGE                 NUMBER(3),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    KYC_STATUS          VARCHAR(20),
    RISK_RATING         VARCHAR(10),
    SEGMENT             VARCHAR(30),
    RELATIONSHIP_TENURE_MONTHS NUMBER(5),
    TOTAL_PRODUCTS      NUMBER(3),
    TOTAL_BALANCE       NUMBER(15,2),
    AUM                 NUMBER(15,2),
    HOUSEHOLD_ID        VARCHAR(20),
    HOUSEHOLD_SIZE      NUMBER(3),
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Customer dimension - SCD2. Unified across core banking and CRM.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.DIM_ACCOUNT (
    ACCOUNT_KEY         NUMBER AUTOINCREMENT,
    ACCOUNT_ID          VARCHAR(20) NOT NULL,
    CUSTOMER_KEY        NUMBER,
    ACCOUNT_TYPE        VARCHAR(20),
    ACCOUNT_SUBTYPE     VARCHAR(30),
    PRODUCT_CODE        VARCHAR(20),
    PRODUCT_NAME        VARCHAR(100),
    OPEN_DATE           DATE,
    STATUS              VARCHAR(20),
    BRANCH_ID           VARCHAR(10),
    INTEREST_RATE       NUMBER(7,5),
    CREDIT_LIMIT        NUMBER(15,2),
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Account dimension - SCD2. All product types (deposits, loans, cards, investments).';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.DIM_SECURITY (
    SECURITY_KEY        NUMBER AUTOINCREMENT,
    SECURITY_ID         VARCHAR(20) NOT NULL,
    TICKER              VARCHAR(20),
    CUSIP               VARCHAR(12),
    ISIN                VARCHAR(15),
    SECURITY_NAME       VARCHAR(200),
    ASSET_CLASS         VARCHAR(20),
    SECTOR              VARCHAR(50),
    COUNTRY             VARCHAR(50),
    CURRENCY            VARCHAR(5),
    MATURITY_DATE       DATE,
    COUPON_RATE         NUMBER(7,5)
) COMMENT = 'Security/Instrument dimension. Equities, fixed income, derivatives.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_BUSINESS_DAY     BOOLEAN,
    IS_MONTH_END        BOOLEAN,
    IS_QUARTER_END      BOOLEAN,
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2)
) COMMENT = 'Date dimension with business day calendar.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.BRIDGE_HOUSEHOLD (
    HOUSEHOLD_ID        VARCHAR(20) NOT NULL,
    CUSTOMER_KEY        NUMBER NOT NULL,
    RELATIONSHIP_TYPE   VARCHAR(20),       -- PRIMARY, SPOUSE, DEPENDENT, BENEFICIARY
    IS_HEAD_OF_HOUSEHOLD BOOLEAN
) COMMENT = 'Household bridge table. Links customers to household units.';

-- Facts
CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.FACT_TRANSACTION (
    TRANSACTION_KEY     NUMBER AUTOINCREMENT,
    TRANSACTION_ID      VARCHAR(30),
    ACCOUNT_KEY         NUMBER,
    CUSTOMER_KEY        NUMBER,
    DATE_KEY            NUMBER,
    TRANSACTION_TYPE    VARCHAR(20),
    CHANNEL             VARCHAR(20),
    AMOUNT              NUMBER(15,2),
    MERCHANT_CATEGORY   VARCHAR(10),
    IS_RECURRING        BOOLEAN,
    FRAUD_FLAG          BOOLEAN,
    FRAUD_SCORE         NUMBER(5,4)
) COMMENT = 'Transaction fact. Core banking activity. Enriched with fraud indicators.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.FACT_DAILY_BALANCE (
    ACCOUNT_KEY         NUMBER,
    DATE_KEY            NUMBER,
    LEDGER_BALANCE      NUMBER(15,2),
    AVAILABLE_BALANCE   NUMBER(15,2),
    ACCRUED_INTEREST    NUMBER(15,4),
    DAYS_PAST_DUE       NUMBER(5),
    DELINQUENCY_BUCKET  VARCHAR(10),
    PD_SCORE            NUMBER(7,6),
    EAD_AMOUNT          NUMBER(15,2)
) COMMENT = 'Daily balance fact with risk overlays. Supports credit risk and Basel reporting.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.FACT_PORTFOLIO_POSITION (
    ACCOUNT_KEY         NUMBER,
    CUSTOMER_KEY        NUMBER,
    SECURITY_KEY        NUMBER,
    DATE_KEY            NUMBER,
    QUANTITY            NUMBER(15,6),
    MARKET_VALUE        NUMBER(15,2),
    COST_BASIS          NUMBER(15,2),
    UNREALIZED_PL       NUMBER(15,2),
    DAILY_RETURN_PCT    NUMBER(7,6),
    WEIGHT_PCT          NUMBER(5,4)
) COMMENT = 'Portfolio position fact. Daily grain for performance and risk analytics.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.FACT_FRAUD_CASE (
    CASE_KEY            NUMBER AUTOINCREMENT,
    ALERT_ID            VARCHAR(30),
    CUSTOMER_KEY        NUMBER,
    ACCOUNT_KEY         NUMBER,
    DATE_KEY            NUMBER,
    ALERT_TYPE          VARCHAR(30),
    RISK_SCORE          NUMBER(5,4),
    DISPOSITION         VARCHAR(30),
    IS_CONFIRMED_FRAUD  BOOLEAN,
    FRAUD_AMOUNT        NUMBER(15,2),
    RESOLUTION_HOURS    NUMBER(10,2)
) COMMENT = 'Fraud case fact. Alert-to-resolution lifecycle.';

-- Aggregates
CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.AGG_CUSTOMER_PROFITABILITY (
    CUSTOMER_KEY        NUMBER,
    MONTH_KEY           NUMBER,
    INTEREST_INCOME     NUMBER(15,2),
    FEE_INCOME          NUMBER(15,2),
    TRADING_INCOME      NUMBER(15,2),
    TOTAL_REVENUE       NUMBER(15,2),
    COST_TO_SERVE       NUMBER(15,2),
    PROVISION_EXPENSE   NUMBER(15,2),
    NET_CONTRIBUTION    NUMBER(15,2),
    PRODUCT_COUNT       NUMBER(3),
    CROSS_SELL_SCORE    NUMBER(5,4)
) COMMENT = 'Monthly customer profitability. Revenue - cost - provision.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.AGG_PORTFOLIO_RISK (
    CUSTOMER_KEY        NUMBER,
    DATE_KEY            NUMBER,
    TOTAL_AUM           NUMBER(15,2),
    EQUITY_PCT          NUMBER(5,4),
    FIXED_INCOME_PCT    NUMBER(5,4),
    ALTERNATIVES_PCT    NUMBER(5,4),
    CASH_PCT            NUMBER(5,4),
    VAR_95              NUMBER(15,2),
    SHARPE_RATIO        NUMBER(7,4),
    BETA                NUMBER(7,4),
    MAX_DRAWDOWN_PCT    NUMBER(5,4),
    CONCENTRATION_TOP5  NUMBER(5,4)
) COMMENT = 'Daily portfolio risk metrics. VaR, Sharpe, drawdown. Per customer.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.AGG_CREDIT_EXPOSURE (
    DATE_KEY            NUMBER,
    PRODUCT_CODE        VARCHAR(20),
    DELINQUENCY_BUCKET  VARCHAR(10),
    CUSTOMER_COUNT      NUMBER(10),
    TOTAL_EXPOSURE      NUMBER(15,2),
    TOTAL_PROVISION     NUMBER(15,2),
    AVG_PD              NUMBER(7,6),
    AVG_LGD             NUMBER(5,4),
    EXPECTED_LOSS       NUMBER(15,2),
    MIGRATION_IN        NUMBER(15,2),
    MIGRATION_OUT       NUMBER(15,2)
) COMMENT = 'Credit exposure aggregate by product/delinquency. Basel III/IFRS9/CECL reporting.';

CREATE OR REPLACE TABLE PINNACLE_FIN.GOLD.AGG_AML_METRICS (
    MONTH_KEY           NUMBER,
    ALERT_TYPE          VARCHAR(50),
    ALERTS_GENERATED    NUMBER(10),
    ALERTS_CLOSED_FALSE_POS NUMBER(10),
    ALERTS_ESCALATED    NUMBER(10),
    SARS_FILED          NUMBER(10),
    FALSE_POSITIVE_RATE NUMBER(5,4),
    AVG_RESOLUTION_HOURS NUMBER(10,2),
    TOTAL_SUSPICIOUS_AMOUNT NUMBER(15,2)
) COMMENT = 'Monthly AML operational metrics. Alert effectiveness and SAR filing rates.';

