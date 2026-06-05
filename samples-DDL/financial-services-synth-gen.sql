-- ============================================================================
-- FINANCIAL SERVICES VERTICAL - Synthetic Data Generation
-- Entity: Pinnacle Financial Holdings
-- Prerequisites: Run financial-services-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~5-8 minutes on XS warehouse
-- US calendar: Tax season Q1, year-end rebalancing, bonus deposits Jan/Mar
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE PINNACLE_FIN.GOLD.AGG_AML_METRICS;
TRUNCATE TABLE PINNACLE_FIN.GOLD.AGG_CREDIT_EXPOSURE;
TRUNCATE TABLE PINNACLE_FIN.GOLD.AGG_PORTFOLIO_RISK;
TRUNCATE TABLE PINNACLE_FIN.GOLD.AGG_CUSTOMER_PROFITABILITY;
TRUNCATE TABLE PINNACLE_FIN.GOLD.FACT_FRAUD_CASE;
TRUNCATE TABLE PINNACLE_FIN.GOLD.FACT_PORTFOLIO_POSITION;
TRUNCATE TABLE PINNACLE_FIN.GOLD.FACT_DAILY_BALANCE;
TRUNCATE TABLE PINNACLE_FIN.GOLD.FACT_TRANSACTION;
TRUNCATE TABLE PINNACLE_FIN.GOLD.BRIDGE_HOUSEHOLD;
TRUNCATE TABLE PINNACLE_FIN.GOLD.DIM_DATE;
TRUNCATE TABLE PINNACLE_FIN.GOLD.DIM_SECURITY;
TRUNCATE TABLE PINNACLE_FIN.GOLD.DIM_ACCOUNT;
TRUNCATE TABLE PINNACLE_FIN.GOLD.DIM_CUSTOMER;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span with business day calendar)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) NOT IN (0, 6) THEN TRUE ELSE FALSE END AS IS_BUSINESS_DAY,
    CASE WHEN DAY(LAST_DAY(d)) = DAY(d) THEN TRUE ELSE FALSE END AS IS_MONTH_END,
    CASE WHEN MONTH(d) IN (3,6,9,12) AND DAY(LAST_DAY(d)) = DAY(d) THEN TRUE ELSE FALSE END AS IS_QUARTER_END,
    YEAR(d)                                            AS FISCAL_YEAR,
    MONTH(d)                                           AS FISCAL_PERIOD
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_CUSTOMER (3,000 banking customers)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.DIM_CUSTOMER
    (CUSTOMER_KEY, CUSTOMER_ID, CUSTOMER_TYPE, FULL_NAME, AGE, STATE, ZIP_CODE,
     KYC_STATUS, RISK_RATING, SEGMENT, RELATIONSHIP_TENURE_MONTHS, TOTAL_PRODUCTS,
     TOTAL_BALANCE, AUM, HOUSEHOLD_ID, HOUSEHOLD_SIZE,
     _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS CUSTOMER_KEY,
    'CUS-' || LPAD(seq::VARCHAR, 7, '0')               AS CUSTOMER_ID,
    GET(ARRAY_CONSTRUCT('INDIVIDUAL', 'INDIVIDUAL', 'INDIVIDUAL', 'INDIVIDUAL', 'JOINT', 'JOINT', 'CORPORATE', 'TRUST'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS CUSTOMER_TYPE,
    GET(ARRAY_CONSTRUCT('James Smith', 'Maria Garcia', 'Robert Johnson', 'Patricia Williams', 'John Brown',
        'Jennifer Davis', 'Michael Miller', 'Linda Wilson', 'David Anderson', 'Elizabeth Taylor',
        'William Thomas', 'Barbara Jackson', 'Richard White', 'Susan Harris', 'Joseph Martin',
        'Jessica Thompson', 'Charles Robinson', 'Sarah Clark', 'Daniel Lewis', 'Karen Lee'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR || ' (' || seq::VARCHAR || ')' AS FULL_NAME,
    GREATEST(18, LEAST(95, ROUND(NORMAL(48, 15, RANDOM()))))::INT AS AGE,
    GET(ARRAY_CONSTRUCT('NY', 'CA', 'TX', 'FL', 'IL', 'PA', 'OH', 'GA', 'NC', 'NJ',
        'MI', 'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'CO'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS STATE,
    LPAD(UNIFORM(10001, 99999, RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    GET(ARRAY_CONSTRUCT('VERIFIED', 'VERIFIED', 'VERIFIED', 'VERIFIED', 'VERIFIED', 'PENDING', 'ENHANCED', 'EXPIRED'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS KYC_STATUS,
    GET(ARRAY_CONSTRUCT('LOW', 'LOW', 'LOW', 'LOW', 'MEDIUM', 'MEDIUM', 'HIGH'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS RISK_RATING,
    -- Wealth segment: power law
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 2 THEN 'UHNW'
        WHEN UNIFORM(0, 100, RANDOM()) < 8 THEN 'HNW'
        WHEN UNIFORM(0, 100, RANDOM()) < 25 THEN 'AFFLUENT'
        ELSE 'MASS_MARKET'
    END                                                AS SEGMENT,
    UNIFORM(6, 240, RANDOM())                          AS RELATIONSHIP_TENURE_MONTHS,
    UNIFORM(1, 8, RANDOM())                            AS TOTAL_PRODUCTS,
    -- Balance: log-normal (heavy tail)
    ROUND(EXP(NORMAL(9.5, 2.0, RANDOM())), 2)         AS TOTAL_BALANCE, -- median ~$13K, some >$1M
    -- AUM: only for affluent/HNW
    IFF(UNIFORM(0, 100, RANDOM()) < 30,
        ROUND(EXP(NORMAL(11.5, 1.8, RANDOM())), 2), NULL) AS AUM,
    'HH-' || LPAD(UNIFORM(1, 2000, RANDOM())::VARCHAR, 5, '0') AS HOUSEHOLD_ID,
    UNIFORM(1, 5, RANDOM())                            AS HOUSEHOLD_SIZE,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 3000)));

-- ============================================================================
-- 3. DIM_ACCOUNT (8,000 accounts across products)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.DIM_ACCOUNT
    (ACCOUNT_KEY, ACCOUNT_ID, CUSTOMER_KEY, ACCOUNT_TYPE, ACCOUNT_SUBTYPE, PRODUCT_CODE,
     PRODUCT_NAME, OPEN_DATE, STATUS, BRANCH_ID, INTEREST_RATE, CREDIT_LIMIT,
     _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS ACCOUNT_KEY,
    'ACC-' || LPAD(seq::VARCHAR, 8, '0')               AS ACCOUNT_ID,
    UNIFORM(1, 3000, RANDOM())                         AS CUSTOMER_KEY,
    GET(ARRAY_CONSTRUCT('CHECKING', 'CHECKING', 'SAVINGS', 'SAVINGS', 'MONEY_MARKET',
        'CREDIT_CARD', 'CREDIT_CARD', 'LOAN', 'MORTGAGE', 'CD'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ACCOUNT_TYPE,
    GET(ARRAY_CONSTRUCT('PREMIUM_CHECKING', 'BASIC_CHECKING', 'HIGH_YIELD_SAVINGS', 'REGULAR_SAVINGS',
        'MONEY_MARKET_PLUS', 'PLATINUM_CARD', 'REWARDS_CARD', 'PERSONAL_LOAN', 'HOME_MORTGAGE_30Y', 'CD_12M'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ACCOUNT_SUBTYPE,
    'PRD-' || LPAD(UNIFORM(1, 30, RANDOM())::VARCHAR, 3, '0') AS PRODUCT_CODE,
    GET(ARRAY_CONSTRUCT('Pinnacle Premium Checking', 'Pinnacle Basic Checking', 'High Yield Savings Plus',
        'Regular Savings', 'Money Market Plus', 'Platinum Rewards Card', 'Cash Back Card',
        'Personal Flex Loan', 'Home Mortgage 30Y Fixed', 'Certificate 12-Month'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS PRODUCT_NAME,
    DATEADD('day', -UNIFORM(30, 1800, RANDOM()), CURRENT_DATE()) AS OPEN_DATE,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, 'CLOSED',
        IFF(UNIFORM(0, 100, RANDOM()) < 3, 'DORMANT', 'ACTIVE')) AS STATUS,
    'BR-' || LPAD(UNIFORM(1, 50, RANDOM())::VARCHAR, 3, '0') AS BRANCH_ID,
    CASE
        WHEN UNIFORM(0, 9, RANDOM()) IN (0, 1) THEN 0.01     -- checking
        WHEN UNIFORM(0, 9, RANDOM()) IN (2, 3) THEN ROUND(UNIFORM(200, 500, RANDOM()) / 10000.0, 5) -- savings
        WHEN UNIFORM(0, 9, RANDOM()) = 4 THEN ROUND(UNIFORM(350, 550, RANDOM()) / 10000.0, 5) -- MM
        WHEN UNIFORM(0, 9, RANDOM()) IN (5, 6) THEN ROUND(UNIFORM(1500, 2499, RANDOM()) / 10000.0, 5) -- CC
        WHEN UNIFORM(0, 9, RANDOM()) = 7 THEN ROUND(UNIFORM(600, 1200, RANDOM()) / 10000.0, 5) -- personal loan
        WHEN UNIFORM(0, 9, RANDOM()) = 8 THEN ROUND(UNIFORM(350, 750, RANDOM()) / 10000.0, 5) -- mortgage
        ELSE ROUND(UNIFORM(400, 550, RANDOM()) / 10000.0, 5) -- CD
    END                                                AS INTEREST_RATE,
    CASE
        WHEN UNIFORM(0, 9, RANDOM()) IN (5, 6) THEN ROUND(EXP(NORMAL(9.0, 1.0, RANDOM())), 2) -- CC limit
        ELSE NULL
    END                                                AS CREDIT_LIMIT,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 8000)));

-- ============================================================================
-- 4. DIM_SECURITY (200 securities)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.DIM_SECURITY
    (SECURITY_KEY, SECURITY_ID, TICKER, CUSIP, ISIN, SECURITY_NAME, ASSET_CLASS,
     SECTOR, COUNTRY, CURRENCY, MATURITY_DATE, COUPON_RATE)
SELECT
    seq                                                AS SECURITY_KEY,
    'SEC-' || LPAD(seq::VARCHAR, 5, '0')               AS SECURITY_ID,
    GET(ARRAY_CONSTRUCT('AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'META', 'TSLA', 'JPM',
        'V', 'JNJ', 'WMT', 'PG', 'XOM', 'UNH', 'HD', 'BAC', 'PFE', 'ABBV', 'KO', 'PEP',
        'AGG', 'BND', 'LQD', 'TLT', 'HYG', 'MUB', 'VCIT', 'SCHZ', 'IGIB', 'TIPS'),
        MOD(seq - 1, 30))::VARCHAR || IFF(seq > 30, CEIL(seq/30)::VARCHAR, '') AS TICKER,
    LPAD(UNIFORM(10000000, 99999999, RANDOM())::VARCHAR, 9, '0') AS CUSIP,
    'US' || LPAD(UNIFORM(10000000, 99999999, RANDOM())::VARCHAR, 10, '0') || UNIFORM(0, 9, RANDOM())::VARCHAR AS ISIN,
    GET(ARRAY_CONSTRUCT('Apple Inc', 'Microsoft Corp', 'Alphabet Inc', 'Amazon.com Inc', 'NVIDIA Corp',
        'Meta Platforms', 'Tesla Inc', 'JPMorgan Chase', 'Visa Inc', 'Johnson & Johnson',
        'Walmart Inc', 'Procter & Gamble', 'Exxon Mobil', 'UnitedHealth Group', 'Home Depot',
        'Bank of America', 'Pfizer Inc', 'AbbVie Inc', 'Coca-Cola Co', 'PepsiCo Inc',
        'iShares Core US Agg Bond', 'Vanguard Total Bond', 'iShares IG Corp', 'iShares 20+ Treasury',
        'iShares High Yield', 'iShares Muni Bond', 'Vanguard Intermediate Corp', 'Schwab US Agg Bond',
        'iShares IG Corp Bond', 'iShares TIPS Bond'),
        MOD(seq - 1, 30))::VARCHAR                     AS SECURITY_NAME,
    IFF(MOD(seq - 1, 30) < 20, 'EQUITY', 'FIXED_INCOME') AS ASSET_CLASS,
    GET(ARRAY_CONSTRUCT('Technology', 'Technology', 'Technology', 'Consumer Discretionary', 'Technology',
        'Technology', 'Consumer Discretionary', 'Financials', 'Financials', 'Healthcare',
        'Consumer Staples', 'Consumer Staples', 'Energy', 'Healthcare', 'Consumer Discretionary',
        'Financials', 'Healthcare', 'Healthcare', 'Consumer Staples', 'Consumer Staples',
        'Aggregate', 'Aggregate', 'Corporate', 'Government', 'High Yield',
        'Municipal', 'Corporate', 'Aggregate', 'Corporate', 'Government'),
        MOD(seq - 1, 30))::VARCHAR                     AS SECTOR,
    'US'                                               AS COUNTRY,
    'USD'                                              AS CURRENCY,
    IFF(MOD(seq - 1, 30) >= 20, DATEADD('year', UNIFORM(1, 20, RANDOM()), CURRENT_DATE()), NULL) AS MATURITY_DATE,
    IFF(MOD(seq - 1, 30) >= 20, ROUND(UNIFORM(100, 600, RANDOM()) / 10000.0, 5), NULL) AS COUPON_RATE
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 200)));

-- ============================================================================
-- 5. BRIDGE_HOUSEHOLD
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.BRIDGE_HOUSEHOLD
    (HOUSEHOLD_ID, CUSTOMER_KEY, RELATIONSHIP_TYPE, IS_HEAD_OF_HOUSEHOLD)
SELECT
    HOUSEHOLD_ID,
    CUSTOMER_KEY,
    IFF(ROW_NUMBER() OVER (PARTITION BY HOUSEHOLD_ID ORDER BY CUSTOMER_KEY) = 1, 'PRIMARY',
        GET(ARRAY_CONSTRUCT('SPOUSE', 'DEPENDENT', 'BENEFICIARY'), UNIFORM(0, 2, RANDOM()))::VARCHAR) AS RELATIONSHIP_TYPE,
    IFF(ROW_NUMBER() OVER (PARTITION BY HOUSEHOLD_ID ORDER BY CUSTOMER_KEY) = 1, TRUE, FALSE) AS IS_HEAD_OF_HOUSEHOLD
FROM PINNACLE_FIN.GOLD.DIM_CUSTOMER
WHERE _IS_CURRENT = TRUE;

-- ============================================================================
-- 6. FACT_TRANSACTION (~1,000,000 transactions over 5 years)
-- Seasonality: Tax refunds Q1 (+25%), bonus deposits Jan/Mar (+15%),
--              holiday spending Nov-Dec (+30%), summer travel (+10%)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.FACT_TRANSACTION
    (TRANSACTION_ID, ACCOUNT_KEY, CUSTOMER_KEY, DATE_KEY, TRANSACTION_TYPE,
     CHANNEL, AMOUNT, MERCHANT_CATEGORY, IS_RECURRING, FRAUD_FLAG, FRAUD_SCORE)
SELECT
    'TXN-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY, acct)::VARCHAR, 9, '0') AS TRANSACTION_ID,
    acct                                               AS ACCOUNT_KEY,
    UNIFORM(1, 3000, RANDOM())                         AS CUSTOMER_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    GET(ARRAY_CONSTRUCT('DEBIT', 'DEBIT', 'DEBIT', 'CREDIT', 'TRANSFER', 'FEE', 'PAYMENT', 'INTEREST'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS TRANSACTION_TYPE,
    GET(ARRAY_CONSTRUCT('ONLINE', 'ONLINE', 'MOBILE', 'MOBILE', 'ATM', 'BRANCH', 'ACH', 'WIRE'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS CHANNEL,
    -- Amount: log-normal with seasonal adjustment
    ROUND(EXP(NORMAL(4.0, 1.5, RANDOM()))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (1, 2, 3) THEN 0.15 ELSE 0 END  -- tax season
            + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12) THEN 0.25 ELSE 0 END   -- holiday
            + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7) THEN 0.08 ELSE 0 END     -- summer travel
        )
        * IFF(UNIFORM(0, 1000, RANDOM()) < 3, 10.0, 1.0) -- 0.3% large anomaly
    , 2)                                               AS AMOUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0')) AS MERCHANT_CATEGORY,
    IFF(UNIFORM(0, 100, RANDOM()) < 20, TRUE, FALSE)  AS IS_RECURRING,
    IFF(UNIFORM(0, 10000, RANDOM()) < 15, TRUE, FALSE) AS FRAUD_FLAG, -- 0.15% fraud rate
    LEAST(1.0, GREATEST(0.0, ROUND(
        IFF(UNIFORM(0, 10000, RANDOM()) < 15,
            NORMAL(0.85, 0.1, RANDOM()),  -- fraud cases score high
            NORMAL(0.12, 0.08, RANDOM())  -- legitimate cases score low
        ), 4)))                                        AS FRAUD_SCORE
FROM PINNACLE_FIN.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 8000, RANDOM()) AS acct FROM TABLE(GENERATOR(ROWCOUNT => 15))) accounts
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < (
      50
      + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12) THEN 15 ELSE 0 END
      + CASE WHEN MONTH(d.FULL_DATE) IN (1, 2, 3) THEN 10 ELSE 0 END
      + CASE WHEN DAYOFWEEK(d.FULL_DATE) = 5 THEN 8 ELSE 0 END -- Friday payday boost
  );

-- ============================================================================
-- 7. FACT_DAILY_BALANCE (~200,000 rows: sample of accounts x business days)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.FACT_DAILY_BALANCE
    (ACCOUNT_KEY, DATE_KEY, LEDGER_BALANCE, AVAILABLE_BALANCE, ACCRUED_INTEREST,
     DAYS_PAST_DUE, DELINQUENCY_BUCKET, PD_SCORE, EAD_AMOUNT)
SELECT
    acct                                               AS ACCOUNT_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    -- Balance: random walk with drift
    ROUND(EXP(NORMAL(9.0, 1.8, RANDOM()))
        * (1.0 + 0.02 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12), 2) AS LEDGER_BALANCE,
    ROUND(EXP(NORMAL(8.8, 1.8, RANDOM()))
        * (1.0 + 0.02 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12), 2) AS AVAILABLE_BALANCE,
    ROUND(GREATEST(0, NORMAL(5, 3, RANDOM())), 4)     AS ACCRUED_INTEREST,
    -- DPD: mostly 0, some delinquent
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 88 THEN 0
        WHEN UNIFORM(0, 100, RANDOM()) < 94 THEN UNIFORM(1, 30, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 97 THEN UNIFORM(31, 60, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 99 THEN UNIFORM(61, 90, RANDOM())
        ELSE UNIFORM(91, 180, RANDOM())
    END                                                AS DAYS_PAST_DUE,
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 88 THEN 'CURRENT'
        WHEN UNIFORM(0, 100, RANDOM()) < 94 THEN '30DPD'
        WHEN UNIFORM(0, 100, RANDOM()) < 97 THEN '60DPD'
        WHEN UNIFORM(0, 100, RANDOM()) < 99 THEN '90DPD'
        ELSE 'CHARGE_OFF'
    END                                                AS DELINQUENCY_BUCKET,
    LEAST(1.0, GREATEST(0.0001, ROUND(NORMAL(0.02, 0.03, RANDOM()), 6))) AS PD_SCORE,
    ROUND(EXP(NORMAL(9.0, 1.8, RANDOM())), 2)         AS EAD_AMOUNT
FROM PINNACLE_FIN.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 8000, RANDOM()) AS acct FROM TABLE(GENERATOR(ROWCOUNT => 5))) sample_accounts
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 15; -- sample 15% of days

-- ============================================================================
-- 8. FACT_PORTFOLIO_POSITION (~100,000 positions)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.FACT_PORTFOLIO_POSITION
    (ACCOUNT_KEY, CUSTOMER_KEY, SECURITY_KEY, DATE_KEY, QUANTITY, MARKET_VALUE,
     COST_BASIS, UNREALIZED_PL, DAILY_RETURN_PCT, WEIGHT_PCT)
SELECT
    UNIFORM(1, 8000, RANDOM())                         AS ACCOUNT_KEY,
    UNIFORM(1, 3000, RANDOM())                         AS CUSTOMER_KEY,
    sec_key                                            AS SECURITY_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    ROUND(GREATEST(1, NORMAL(500, 300, RANDOM())), 6)  AS QUANTITY,
    -- Market value with growth trend + volatility
    ROUND(EXP(NORMAL(9.5, 1.5, RANDOM()))
        * (1.0 + 0.08 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60) -- 8% annual growth
        * (1.0 + NORMAL(0, 0.02, RANDOM())) -- daily volatility
    , 2)                                               AS MARKET_VALUE,
    ROUND(EXP(NORMAL(9.3, 1.5, RANDOM())), 2)         AS COST_BASIS,
    ROUND(NORMAL(500, 2000, RANDOM()), 2)              AS UNREALIZED_PL,
    -- Daily return: normal with fat tails
    ROUND(NORMAL(0.0003, 0.012, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 3.0, 1.0) -- 2% chance of tail event
    , 6)                                               AS DAILY_RETURN_PCT,
    ROUND(UNIFORM(1, 20, RANDOM()) / 100.0, 4)        AS WEIGHT_PCT
FROM PINNACLE_FIN.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 200, RANDOM()) AS sec_key FROM TABLE(GENERATOR(ROWCOUNT => 3))) securities
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 8; -- monthly-ish snapshots

-- ============================================================================
-- 9. FACT_FRAUD_CASE (~5,000 fraud cases)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.FACT_FRAUD_CASE
    (ALERT_ID, CUSTOMER_KEY, ACCOUNT_KEY, DATE_KEY, ALERT_TYPE, RISK_SCORE,
     DISPOSITION, IS_CONFIRMED_FRAUD, FRAUD_AMOUNT, RESOLUTION_HOURS)
SELECT
    'FRD-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY)::VARCHAR, 7, '0') AS ALERT_ID,
    UNIFORM(1, 3000, RANDOM())                         AS CUSTOMER_KEY,
    UNIFORM(1, 8000, RANDOM())                         AS ACCOUNT_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    GET(ARRAY_CONSTRUCT('VELOCITY', 'GEO_ANOMALY', 'AMOUNT_ANOMALY', 'PATTERN', 'DEVICE', 'IDENTITY'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS ALERT_TYPE,
    LEAST(1.0, GREATEST(0.3, ROUND(NORMAL(0.72, 0.15, RANDOM()), 4))) AS RISK_SCORE,
    GET(ARRAY_CONSTRUCT('FALSE_POSITIVE', 'FALSE_POSITIVE', 'FALSE_POSITIVE', 'CONFIRMED_FRAUD', 'CONFIRMED_FRAUD', 'INVESTIGATING'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS DISPOSITION,
    IFF(UNIFORM(0, 100, RANDOM()) < 35, TRUE, FALSE)  AS IS_CONFIRMED_FRAUD, -- 35% of alerts are real
    IFF(UNIFORM(0, 100, RANDOM()) < 35,
        ROUND(EXP(NORMAL(6.5, 1.5, RANDOM())), 2), NULL) AS FRAUD_AMOUNT,
    GREATEST(0.5, ROUND(NORMAL(24, 18, RANDOM()), 2)) AS RESOLUTION_HOURS
FROM PINNACLE_FIN.GOLD.DIM_DATE d
WHERE d.IS_BUSINESS_DAY = TRUE
  -- Higher fraud around holidays and online shopping peaks
  AND UNIFORM(0, 100, RANDOM()) < (
      3
      + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12) THEN 2 ELSE 0 END
      + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (0, 6) THEN 1 ELSE 0 END
  );

-- ============================================================================
-- 10. AGG_CUSTOMER_PROFITABILITY (monthly)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.AGG_CUSTOMER_PROFITABILITY
    (CUSTOMER_KEY, MONTH_KEY, INTEREST_INCOME, FEE_INCOME, TRADING_INCOME,
     TOTAL_REVENUE, COST_TO_SERVE, PROVISION_EXPENSE, NET_CONTRIBUTION,
     PRODUCT_COUNT, CROSS_SELL_SCORE)
SELECT
    cust_key                                           AS CUSTOMER_KEY,
    d.DATE_KEY                                         AS MONTH_KEY,
    ROUND(GREATEST(0, NORMAL(150, 80, RANDOM())), 2)   AS INTEREST_INCOME,
    ROUND(GREATEST(0, NORMAL(45, 25, RANDOM())), 2)    AS FEE_INCOME,
    IFF(UNIFORM(0, 100, RANDOM()) < 20, ROUND(NORMAL(80, 50, RANDOM()), 2), 0) AS TRADING_INCOME,
    ROUND(GREATEST(10, NORMAL(250, 120, RANDOM())), 2) AS TOTAL_REVENUE,
    ROUND(GREATEST(20, NORMAL(80, 30, RANDOM())), 2)   AS COST_TO_SERVE,
    ROUND(GREATEST(0, NORMAL(15, 20, RANDOM())), 2)    AS PROVISION_EXPENSE,
    ROUND(NORMAL(150, 100, RANDOM()), 2)               AS NET_CONTRIBUTION,
    UNIFORM(1, 8, RANDOM())                            AS PRODUCT_COUNT,
    LEAST(1.0, GREATEST(0.0, ROUND(NORMAL(0.35, 0.2, RANDOM()), 4))) AS CROSS_SELL_SCORE
FROM PINNACLE_FIN.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 3000, RANDOM()) AS cust_key FROM TABLE(GENERATOR(ROWCOUNT => 200))) customers
WHERE DAY(d.FULL_DATE) = 1; -- monthly grain, first of month

-- ============================================================================
-- 11. AGG_CREDIT_EXPOSURE (daily by product/bucket)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.AGG_CREDIT_EXPOSURE
    (DATE_KEY, PRODUCT_CODE, DELINQUENCY_BUCKET, CUSTOMER_COUNT, TOTAL_EXPOSURE,
     TOTAL_PROVISION, AVG_PD, AVG_LGD, EXPECTED_LOSS, MIGRATION_IN, MIGRATION_OUT)
SELECT
    d.DATE_KEY,
    GET(ARRAY_CONSTRUCT('CREDIT_CARD', 'PERSONAL_LOAN', 'MORTGAGE', 'AUTO_LOAN', 'LINE_OF_CREDIT'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS PRODUCT_CODE,
    GET(ARRAY_CONSTRUCT('CURRENT', 'CURRENT', 'CURRENT', '30DPD', '60DPD', '90DPD'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS DELINQUENCY_BUCKET,
    UNIFORM(50, 5000, RANDOM())                        AS CUSTOMER_COUNT,
    ROUND(EXP(NORMAL(16, 1.5, RANDOM())), 2)          AS TOTAL_EXPOSURE,
    ROUND(EXP(NORMAL(13, 1.5, RANDOM())), 2)          AS TOTAL_PROVISION,
    LEAST(1.0, GREATEST(0.001, ROUND(NORMAL(0.025, 0.02, RANDOM()), 6))) AS AVG_PD,
    LEAST(1.0, GREATEST(0.1, ROUND(NORMAL(0.45, 0.15, RANDOM()), 4))) AS AVG_LGD,
    ROUND(EXP(NORMAL(12, 1.5, RANDOM())), 2)          AS EXPECTED_LOSS,
    ROUND(EXP(NORMAL(11, 1.5, RANDOM())), 2)          AS MIGRATION_IN,
    ROUND(EXP(NORMAL(11, 1.5, RANDOM())), 2)          AS MIGRATION_OUT
FROM PINNACLE_FIN.GOLD.DIM_DATE d
WHERE d.IS_MONTH_END = TRUE; -- monthly reporting dates

-- ============================================================================
-- 12. AGG_AML_METRICS (monthly)
-- ============================================================================
INSERT INTO PINNACLE_FIN.GOLD.AGG_AML_METRICS
    (MONTH_KEY, ALERT_TYPE, ALERTS_GENERATED, ALERTS_CLOSED_FALSE_POS, ALERTS_ESCALATED,
     SARS_FILED, FALSE_POSITIVE_RATE, AVG_RESOLUTION_HOURS, TOTAL_SUSPICIOUS_AMOUNT)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    alert_type                                         AS ALERT_TYPE,
    UNIFORM(50, 500, RANDOM())                         AS ALERTS_GENERATED,
    UNIFORM(30, 400, RANDOM())                         AS ALERTS_CLOSED_FALSE_POS,
    UNIFORM(5, 80, RANDOM())                           AS ALERTS_ESCALATED,
    UNIFORM(1, 15, RANDOM())                           AS SARS_FILED,
    LEAST(0.95, GREATEST(0.40, ROUND(NORMAL(0.65, 0.12, RANDOM()), 4))) AS FALSE_POSITIVE_RATE,
    GREATEST(4, ROUND(NORMAL(36, 18, RANDOM()), 2))   AS AVG_RESOLUTION_HOURS,
    ROUND(EXP(NORMAL(13, 1.5, RANDOM())), 2)          AS TOTAL_SUSPICIOUS_AMOUNT
FROM PINNACLE_FIN.GOLD.DIM_DATE d
CROSS JOIN (SELECT column1 AS alert_type FROM VALUES
    ('STRUCTURING'), ('RAPID_MOVEMENT'), ('UNUSUAL_PATTERN'), ('SANCTIONS_HIT'), ('HIGH_RISK_GEO')) types
WHERE DAY(d.FULL_DATE) = 1;
