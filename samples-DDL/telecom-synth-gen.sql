-- ============================================================================
-- TELECOM VERTICAL - Synthetic Data Generation
-- Entity: Horizon Telecom Inc
-- Prerequisites: Run telecom-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~5-8 minutes on XS warehouse
-- US calendar: Holiday call/data spikes, summer roaming, back-to-school activations
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE HORIZON_TELCO.GOLD.AGG_REVENUE_ASSURANCE;
TRUNCATE TABLE HORIZON_TELCO.GOLD.AGG_CAMPAIGN_PERFORMANCE;
TRUNCATE TABLE HORIZON_TELCO.GOLD.AGG_NETWORK_CAPACITY;
TRUNCATE TABLE HORIZON_TELCO.GOLD.AGG_SUBSCRIBER_HEALTH;
TRUNCATE TABLE HORIZON_TELCO.GOLD.FACT_CONTACT_CENTER;
TRUNCATE TABLE HORIZON_TELCO.GOLD.FACT_CHURN_EVENT;
TRUNCATE TABLE HORIZON_TELCO.GOLD.FACT_NETWORK_HOURLY;
TRUNCATE TABLE HORIZON_TELCO.GOLD.FACT_BILLING;
TRUNCATE TABLE HORIZON_TELCO.GOLD.FACT_USAGE_DAILY;
TRUNCATE TABLE HORIZON_TELCO.GOLD.DIM_DATE;
TRUNCATE TABLE HORIZON_TELCO.GOLD.DIM_PLAN;
TRUNCATE TABLE HORIZON_TELCO.GOLD.DIM_SITE;
TRUNCATE TABLE HORIZON_TELCO.GOLD.DIM_SUBSCRIBER;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN TRUE ELSE FALSE END AS IS_WEEKEND,
    YEAR(d)                                            AS FISCAL_YEAR,
    MONTH(d)                                           AS FISCAL_PERIOD
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_SUBSCRIBER (10,000 subscribers)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.DIM_SUBSCRIBER
    (SUBSCRIBER_KEY, SUBSCRIBER_ID, ACCOUNT_ID, MSISDN, SUBSCRIBER_TYPE, SEGMENT,
     CURRENT_PLAN, SPEED_TIER, MONTHLY_RECURRING, TENURE_MONTHS, CONTRACT_REMAINING_MONTHS,
     CREDIT_CLASS, STATE, CITY, ACTIVATION_DATE, _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS SUBSCRIBER_KEY,
    'SUB-' || LPAD(seq::VARCHAR, 7, '0')               AS SUBSCRIBER_ID,
    'ACC-' || LPAD(CEIL(seq / 2.5)::VARCHAR, 6, '0')  AS ACCOUNT_ID,
    '+1' || LPAD(UNIFORM(2000000000, 9999999999, RANDOM())::VARCHAR, 10, '0') AS MSISDN,
    GET(ARRAY_CONSTRUCT('POSTPAID', 'POSTPAID', 'POSTPAID', 'POSTPAID', 'PREPAID', 'HYBRID'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS SUBSCRIBER_TYPE,
    GET(ARRAY_CONSTRUCT('CONSUMER', 'CONSUMER', 'CONSUMER', 'CONSUMER', 'SMB', 'ENTERPRISE'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS SEGMENT,
    GET(ARRAY_CONSTRUCT(
        'Horizon Unlimited 5G', 'Horizon Premium 5G', 'Horizon Essential 4G', 'Horizon Basic 4G',
        'Horizon Family Share', 'Horizon Business Pro', 'Horizon Prepaid 10GB', 'Horizon Data Only'
    ), UNIFORM(0, 7, RANDOM()))::VARCHAR               AS CURRENT_PLAN,
    GET(ARRAY_CONSTRUCT('5G_UNLIMITED', '5G_PREMIUM', '5G_UNLIMITED', '4G_BASIC', '5G_PREMIUM', '5G_UNLIMITED', '4G_BASIC', '4G_BASIC'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS SPEED_TIER,
    -- MRC: tiered by plan
    CASE UNIFORM(0, 7, RANDOM())
        WHEN 0 THEN 85.0
        WHEN 1 THEN 75.0
        WHEN 2 THEN 55.0
        WHEN 3 THEN 40.0
        WHEN 4 THEN 120.0
        WHEN 5 THEN 95.0
        WHEN 6 THEN 30.0
        ELSE 25.0
    END + ROUND(NORMAL(0, 5, RANDOM()), 2)             AS MONTHLY_RECURRING,
    UNIFORM(1, 120, RANDOM())                          AS TENURE_MONTHS,
    GREATEST(0, UNIFORM(-6, 24, RANDOM()))             AS CONTRACT_REMAINING_MONTHS,
    GET(ARRAY_CONSTRUCT('A', 'A', 'A', 'B', 'B', 'C'), UNIFORM(0, 5, RANDOM()))::VARCHAR AS CREDIT_CLASS,
    GET(ARRAY_CONSTRUCT('NY', 'CA', 'TX', 'FL', 'IL', 'PA', 'OH', 'GA', 'NC', 'NJ',
        'MI', 'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'CO'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS STATE,
    GET(ARRAY_CONSTRUCT('New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
        'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'Austin',
        'Jacksonville', 'Columbus', 'Charlotte', 'Indianapolis', 'San Francisco',
        'Seattle', 'Denver', 'Nashville', 'Portland', 'Detroit'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS CITY,
    DATEADD('day', -UNIFORM(30, 1800, RANDOM()), CURRENT_DATE()) AS ACTIVATION_DATE,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 10000)));

-- ============================================================================
-- 3. DIM_SITE (300 cell sites)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.DIM_SITE
    (SITE_KEY, SITE_ID, SITE_NAME, SITE_TYPE, LATITUDE, LONGITUDE, CITY, STATE,
     REGION, MARKET, TECHNOLOGY_SUPPORT, CAPACITY_TIER, BACKHAUL_TYPE)
SELECT
    seq                                                AS SITE_KEY,
    'SITE-' || LPAD(seq::VARCHAR, 5, '0')              AS SITE_ID,
    'Tower ' || GET(ARRAY_CONSTRUCT('Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot',
        'Golf', 'Hotel', 'India', 'Juliet'), MOD(seq - 1, 10))::VARCHAR || '-' || seq::VARCHAR AS SITE_NAME,
    GET(ARRAY_CONSTRUCT('MACRO', 'MACRO', 'MACRO', 'MACRO', 'SMALL_CELL', 'SMALL_CELL', 'INDOOR', 'ROOFTOP'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS SITE_TYPE,
    ROUND(UNIFORM(2500, 4800, RANDOM()) / 100.0, 4)   AS LATITUDE,
    ROUND(-UNIFORM(7000, 12500, RANDOM()) / 100.0, 4) AS LONGITUDE,
    GET(ARRAY_CONSTRUCT('New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
        'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'Austin',
        'Jacksonville', 'Columbus', 'Charlotte', 'Indianapolis', 'San Francisco',
        'Seattle', 'Denver', 'Nashville', 'Portland', 'Detroit'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS CITY,
    GET(ARRAY_CONSTRUCT('NY', 'CA', 'IL', 'TX', 'AZ', 'PA', 'TX', 'CA', 'TX', 'TX',
        'FL', 'OH', 'NC', 'IN', 'CA', 'WA', 'CO', 'TN', 'OR', 'MI'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS STATE,
    GET(ARRAY_CONSTRUCT('Northeast', 'West', 'Midwest', 'South', 'West'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS REGION,
    GET(ARRAY_CONSTRUCT('NYC Metro', 'LA Metro', 'Chicago Metro', 'Houston Metro', 'Phoenix Metro',
        'Philly Metro', 'DFW Metro', 'Bay Area', 'Seattle Metro', 'Denver Metro'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS MARKET,
    GET(ARRAY_CONSTRUCT('4G+5G_SA', '4G+5G_NSA', '4G+5G_SA', '4G_ONLY', '5G_SA', '4G+5G_NSA'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS TECHNOLOGY_SUPPORT,
    GET(ARRAY_CONSTRUCT('HIGH', 'HIGH', 'MEDIUM', 'MEDIUM', 'MEDIUM', 'LOW'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS CAPACITY_TIER,
    GET(ARRAY_CONSTRUCT('FIBER', 'FIBER', 'FIBER', 'MICROWAVE', 'MICROWAVE', 'SATELLITE'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS BACKHAUL_TYPE
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 300)));

-- ============================================================================
-- 4. DIM_PLAN (20 plans)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.DIM_PLAN
    (PLAN_KEY, PLAN_CODE, PLAN_NAME, PLAN_TYPE, MONTHLY_PRICE, DATA_ALLOWANCE_GB,
     SPEED_TIER, IS_5G, IS_UNLIMITED, LAUNCH_DATE, RETIRE_DATE)
SELECT
    seq                                                AS PLAN_KEY,
    'PLN-' || LPAD(seq::VARCHAR, 3, '0')               AS PLAN_CODE,
    GET(ARRAY_CONSTRUCT(
        'Horizon Unlimited 5G', 'Horizon Premium 5G', 'Horizon Essential 4G', 'Horizon Basic 4G',
        'Horizon Family Share', 'Horizon Business Pro', 'Horizon Business Elite', 'Horizon Prepaid 10GB',
        'Horizon Prepaid 5GB', 'Horizon Data Only 50GB', 'Horizon Student 5G', 'Horizon Senior Basic',
        'Horizon IoT Enterprise', 'Horizon IoT Starter', 'Horizon International', 'Horizon Hotspot 30GB',
        'Horizon Tablet Plan', 'Horizon Watch Plan', 'Horizon Connected Car', 'Horizon Legacy 3G'
    ), seq - 1)::VARCHAR                               AS PLAN_NAME,
    GET(ARRAY_CONSTRUCT('BUNDLE', 'BUNDLE', 'BUNDLE', 'BUNDLE', 'BUNDLE', 'BUNDLE', 'BUNDLE',
        'DATA', 'DATA', 'DATA', 'BUNDLE', 'BUNDLE', 'DATA', 'DATA', 'ADD_ON', 'DATA', 'DATA', 'DATA', 'DATA', 'BUNDLE'),
        seq - 1)::VARCHAR                              AS PLAN_TYPE,
    GET(ARRAY_CONSTRUCT(85, 75, 55, 40, 120, 95, 150, 30, 20, 50, 45, 35, 15, 8, 25, 40, 20, 10, 15, 30),
        seq - 1)::NUMBER                               AS MONTHLY_PRICE,
    GET(ARRAY_CONSTRUCT(999, 100, 50, 15, 200, 100, 500, 10, 5, 50, 75, 10, 5, 1, 10, 30, 20, 2, 5, 5),
        seq - 1)::NUMBER                               AS DATA_ALLOWANCE_GB,
    GET(ARRAY_CONSTRUCT('5G_UNLIMITED', '5G_PREMIUM', '4G_50MBPS', '4G_BASIC', '5G_PREMIUM', '5G_UNLIMITED',
        '5G_UNLIMITED', '4G_BASIC', '4G_BASIC', '5G_PREMIUM', '5G_PREMIUM', '4G_BASIC',
        'NB_IOT', 'NB_IOT', '4G_50MBPS', '5G_PREMIUM', '4G_50MBPS', '4G_BASIC', 'LTE_M', '3G'),
        seq - 1)::VARCHAR                              AS SPEED_TIER,
    IFF(seq <= 7 OR seq = 11, TRUE, FALSE)            AS IS_5G,
    IFF(seq = 1, TRUE, FALSE)                         AS IS_UNLIMITED,
    DATEADD('day', -UNIFORM(100, 1800, RANDOM()), CURRENT_DATE()) AS LAUNCH_DATE,
    IFF(seq = 20, DATEADD('day', -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()), NULL) AS RETIRE_DATE
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 20)));

-- ============================================================================
-- 5. FACT_USAGE_DAILY (~500,000 rows: 10K subs x sampled days)
-- Seasonality: Holiday spikes Dec/Jan (+25%), summer travel (+15% roaming),
--              weekends higher data, evenings higher voice
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.FACT_USAGE_DAILY
    (SUBSCRIBER_KEY, DATE_KEY, VOICE_MINUTES, SMS_COUNT, DATA_BYTES_DL, DATA_BYTES_UL,
     DATA_SESSIONS, AVG_THROUGHPUT_MBPS, AVG_LATENCY_MS, ROAMING_FLAG,
     OVER_ALLOWANCE_FLAG, REVENUE_USAGE)
SELECT
    sub_key                                            AS SUBSCRIBER_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    -- Voice: declining YoY trend, holiday spikes
    GREATEST(0, ROUND(NORMAL(15, 10, RANDOM())
        * (1.0 - 0.05 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)) -- 5% annual decline
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1) THEN 0.3 ELSE 0 END) -- holiday calls
        * IFF(d.IS_WEEKEND, 1.2, 1.0)
    ))                                                 AS VOICE_MINUTES,
    -- SMS: steady decline
    GREATEST(0, ROUND(NORMAL(8, 5, RANDOM())
        * (1.0 - 0.10 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE))
    ))                                                 AS SMS_COUNT,
    -- Data download: strong YoY growth (+25%), weekend heavy, seasonal
    GREATEST(0, ROUND(NORMAL(800000000, 400000000, RANDOM()) -- ~800MB avg
        * (1.0 + 0.25 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)) -- 25% YoY growth
        * IFF(d.IS_WEEKEND, 1.4, 1.0)  -- weekends higher
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1) THEN 0.2 ELSE 0 END)  -- holiday streaming
        * IFF(UNIFORM(0, 100, RANDOM()) < 1, 5.0, 1.0) -- 1% heavy users burst
    ))                                                 AS DATA_BYTES_DL,
    -- Upload: ~15% of download
    GREATEST(0, ROUND(NORMAL(120000000, 80000000, RANDOM())
        * (1.0 + 0.25 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE))
        * IFF(d.IS_WEEKEND, 1.3, 1.0)
    ))                                                 AS DATA_BYTES_UL,
    GREATEST(1, ROUND(NORMAL(25, 12, RANDOM())))::INT  AS DATA_SESSIONS,
    GREATEST(1, ROUND(NORMAL(45, 20, RANDOM()), 2))   AS AVG_THROUGHPUT_MBPS,
    GREATEST(5, ROUND(NORMAL(25, 10, RANDOM()), 2))   AS AVG_LATENCY_MS,
    -- Roaming: higher in summer (travel)
    IFF(UNIFORM(0, 100, RANDOM()) < IFF(MONTH(d.FULL_DATE) IN (6, 7, 8), 5, 1), TRUE, FALSE) AS ROAMING_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, TRUE, FALSE)   AS OVER_ALLOWANCE_FLAG,
    ROUND(GREATEST(0, NORMAL(2.5, 2.0, RANDOM())), 4) AS REVENUE_USAGE
FROM HORIZON_TELCO.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 10000, RANDOM()) AS sub_key FROM TABLE(GENERATOR(ROWCOUNT => 5))) subs
WHERE UNIFORM(0, 100, RANDOM()) < 30; -- ~30% sample for volume control

-- ============================================================================
-- 6. FACT_BILLING (~120,000 rows: monthly per subscriber sample)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.FACT_BILLING
    (SUBSCRIBER_KEY, DATE_KEY, RECURRING_REVENUE, USAGE_REVENUE, ONE_TIME_REVENUE,
     TOTAL_REVENUE, PAYMENT_AMOUNT, BALANCE_OUTSTANDING, DAYS_PAST_DUE, ARPU)
SELECT
    sub_key                                            AS SUBSCRIBER_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    -- MRC with slight annual increase
    ROUND(NORMAL(65, 25, RANDOM())
        * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 2) AS RECURRING_REVENUE,
    ROUND(GREATEST(0, NORMAL(8, 6, RANDOM())), 2)     AS USAGE_REVENUE,
    IFF(UNIFORM(0, 100, RANDOM()) < 10,
        ROUND(UNIFORM(10, 200, RANDOM()) * 1.0, 2), 0) AS ONE_TIME_REVENUE, -- device payments, activation
    ROUND(NORMAL(75, 30, RANDOM())
        * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 2) AS TOTAL_REVENUE,
    -- Payment: usually covers bill, sometimes partial
    ROUND(NORMAL(75, 30, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 92, 1.0, UNIFORM(30, 80, RANDOM()) / 100.0), 2) AS PAYMENT_AMOUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, ROUND(UNIFORM(20, 300, RANDOM()) * 1.0, 2), 0) AS BALANCE_OUTSTANDING,
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 88 THEN 0
        WHEN UNIFORM(0, 100, RANDOM()) < 95 THEN UNIFORM(1, 30, RANDOM())
        ELSE UNIFORM(31, 90, RANDOM())
    END                                                AS DAYS_PAST_DUE,
    ROUND(NORMAL(65, 20, RANDOM())
        * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 2) AS ARPU
FROM HORIZON_TELCO.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 10000, RANDOM()) AS sub_key FROM TABLE(GENERATOR(ROWCOUNT => 80))) subs
WHERE DAY(d.FULL_DATE) = 1; -- monthly billing cycle

-- ============================================================================
-- 7. FACT_NETWORK_HOURLY (~200,000 rows: 300 sites x sampled days x hours)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.FACT_NETWORK_HOURLY
    (SITE_KEY, DATE_KEY, HOUR, TECHNOLOGY, ACTIVE_USERS, PRB_UTILIZATION_PCT,
     THROUGHPUT_DL_MBPS, LATENCY_MS, PACKET_LOSS_PCT, CALL_DROP_RATE,
     HANDOVER_SUCCESS_PCT, ALARM_COUNT, CRITICAL_ALARM_FLAG)
SELECT
    site_key                                           AS SITE_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    hr                                                 AS HOUR,
    GET(ARRAY_CONSTRUCT('4G', '4G', '5G', '5G'), UNIFORM(0, 3, RANDOM()))::VARCHAR AS TECHNOLOGY,
    -- Users: peak at 8-9am and 5-8pm, low at night
    GREATEST(1, ROUND(NORMAL(150, 60, RANDOM())
        * CASE
            WHEN hr BETWEEN 7 AND 9 THEN 1.5   -- morning commute
            WHEN hr BETWEEN 12 AND 13 THEN 1.3  -- lunch
            WHEN hr BETWEEN 17 AND 21 THEN 1.8  -- evening peak
            WHEN hr BETWEEN 0 AND 5 THEN 0.3    -- overnight
            ELSE 1.0
          END
        * IFF(d.IS_WEEKEND, 0.8, 1.0)  -- weekdays busier
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1) THEN 0.15 ELSE 0 END)  -- holiday crowds
    ))                                                 AS ACTIVE_USERS,
    -- PRB utilization: follows user patterns
    LEAST(100, GREATEST(5, ROUND(NORMAL(45, 15, RANDOM())
        * CASE
            WHEN hr BETWEEN 17 AND 21 THEN 1.6
            WHEN hr BETWEEN 0 AND 5 THEN 0.3
            ELSE 1.0
          END
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 1.8, 1.0) -- 2% congestion events
    , 2)))                                             AS PRB_UTILIZATION_PCT,
    GREATEST(5, ROUND(NORMAL(80, 30, RANDOM())
        * (1.0 + 0.15 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 2)) AS THROUGHPUT_DL_MBPS,
    GREATEST(5, ROUND(NORMAL(20, 8, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 3.0, 1.0), 2)) AS LATENCY_MS, -- occasional spikes
    LEAST(5.0, GREATEST(0, ROUND(NORMAL(0.3, 0.2, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 5.0, 1.0), 4))) AS PACKET_LOSS_PCT,
    LEAST(3.0, GREATEST(0, ROUND(NORMAL(0.2, 0.15, RANDOM()), 4))) AS CALL_DROP_RATE,
    LEAST(100, GREATEST(90, ROUND(NORMAL(98.5, 1.2, RANDOM()), 4))) AS HANDOVER_SUCCESS_PCT,
    GREATEST(0, ROUND(NORMAL(0.3, 0.5, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 1, 8.0, 1.0)))::INT AS ALARM_COUNT,
    IFF(UNIFORM(0, 1000, RANDOM()) < 5, TRUE, FALSE)  AS CRITICAL_ALARM_FLAG -- 0.5% critical
FROM HORIZON_TELCO.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 300, RANDOM()) AS site_key FROM TABLE(GENERATOR(ROWCOUNT => 10))) sites
CROSS JOIN (SELECT SEQ4() AS hr FROM TABLE(GENERATOR(ROWCOUNT => 24))) hours
WHERE UNIFORM(0, 100, RANDOM()) < 5; -- heavy sampling to keep volume manageable

-- ============================================================================
-- 8. FACT_CHURN_EVENT (~3,000 churns over 5 years, ~2% monthly rate)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.FACT_CHURN_EVENT
    (SUBSCRIBER_KEY, DATE_KEY, CHURN_TYPE, CHURN_REASON, TENURE_AT_CHURN, LAST_PLAN,
     LAST_ARPU, NPS_LAST, COMPLAINT_COUNT_90D, DATA_USAGE_TREND,
     RETENTION_OFFERED, RETENTION_ACCEPTED)
SELECT
    UNIFORM(1, 10000, RANDOM())                        AS SUBSCRIBER_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    GET(ARRAY_CONSTRUCT('VOLUNTARY', 'VOLUNTARY', 'VOLUNTARY', 'INVOLUNTARY', 'PORT_OUT'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS CHURN_TYPE,
    GET(ARRAY_CONSTRUCT(
        'Price - too expensive', 'Coverage - poor signal', 'Competitor offer', 'Customer service',
        'Moving - no coverage', 'Contract ended', 'Non-payment', 'Network quality',
        'Data speeds slow', 'Device issues'
    ), UNIFORM(0, 9, RANDOM()))::VARCHAR               AS CHURN_REASON,
    UNIFORM(1, 96, RANDOM())                           AS TENURE_AT_CHURN,
    GET(ARRAY_CONSTRUCT('Horizon Unlimited 5G', 'Horizon Premium 5G', 'Horizon Essential 4G',
        'Horizon Basic 4G', 'Horizon Prepaid 10GB'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS LAST_PLAN,
    ROUND(NORMAL(55, 20, RANDOM()), 2)                 AS LAST_ARPU,
    IFF(UNIFORM(0, 100, RANDOM()) < 3, NULL, UNIFORM(0, 10, RANDOM())) AS NPS_LAST,
    GREATEST(0, ROUND(NORMAL(1.5, 1.5, RANDOM())))::INT AS COMPLAINT_COUNT_90D,
    GET(ARRAY_CONSTRUCT('INCREASING', 'STABLE', 'DECLINING', 'DECLINING', 'DECLINING'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS DATA_USAGE_TREND,
    IFF(UNIFORM(0, 100, RANDOM()) < 60, TRUE, FALSE)  AS RETENTION_OFFERED,
    IFF(UNIFORM(0, 100, RANDOM()) < 25, TRUE, FALSE)  AS RETENTION_ACCEPTED
FROM HORIZON_TELCO.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    -- Churn higher after contract ends (Jan surge from holiday activations ending)
    2
    + CASE WHEN MONTH(d.FULL_DATE) IN (1, 2) THEN 1 ELSE 0 END
    + CASE WHEN MONTH(d.FULL_DATE) IN (9, 10) THEN 1 ELSE 0 END -- back-to-school port-outs
);

-- ============================================================================
-- 9. FACT_CONTACT_CENTER (~40,000 interactions)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.FACT_CONTACT_CENTER
    (SUBSCRIBER_KEY, DATE_KEY, MEDIA_TYPE, DIRECTION, HANDLE_TIME_SEC, WAIT_TIME_SEC,
     WRAP_UP_CATEGORY, SENTIMENT_SCORE, NPS_SCORE, FCR_FLAG, TRANSFER_COUNT)
SELECT
    UNIFORM(1, 10000, RANDOM())                        AS SUBSCRIBER_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    GET(ARRAY_CONSTRUCT('VOICE', 'VOICE', 'VOICE', 'CHAT', 'CHAT', 'EMAIL', 'SMS'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS MEDIA_TYPE,
    GET(ARRAY_CONSTRUCT('INBOUND', 'INBOUND', 'INBOUND', 'INBOUND', 'OUTBOUND'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS DIRECTION,
    GREATEST(30, ROUND(NORMAL(320, 150, RANDOM())))    AS HANDLE_TIME_SEC,
    GREATEST(0, ROUND(NORMAL(90, 60, RANDOM())))       AS WAIT_TIME_SEC,
    GET(ARRAY_CONSTRUCT('BILLING_INQUIRY', 'TECH_SUPPORT', 'PLAN_CHANGE', 'COMPLAINT',
        'CANCEL_REQUEST', 'DEVICE_SUPPORT', 'COVERAGE_ISSUE', 'ACCOUNT_UPDATE'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS WRAP_UP_CATEGORY,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        LEAST(1.0, GREATEST(0.0, ROUND(NORMAL(0.60, 0.22, RANDOM()), 4)))) AS SENTIMENT_SCORE,
    IFF(UNIFORM(0, 100, RANDOM()) < 30, NULL, UNIFORM(0, 10, RANDOM())) AS NPS_SCORE,
    IFF(UNIFORM(0, 100, RANDOM()) < 68, TRUE, FALSE)  AS FCR_FLAG,
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 75 THEN 0
        WHEN UNIFORM(0, 100, RANDOM()) < 92 THEN 1
        ELSE UNIFORM(2, 4, RANDOM())
    END                                                AS TRANSFER_COUNT
FROM HORIZON_TELCO.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    -- Higher contact volumes after billing cycle (1st-5th), outages, holiday
    15
    + CASE WHEN DAY(d.FULL_DATE) BETWEEN 1 AND 5 THEN 5 ELSE 0 END -- post-bill inquiries
    + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1) THEN 4 ELSE 0 END -- holiday device activation help
    + CASE WHEN MONTH(d.FULL_DATE) = 9 THEN 3 ELSE 0 END -- back-to-school
);

-- ============================================================================
-- 10. AGG_SUBSCRIBER_HEALTH (weekly health scores)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.AGG_SUBSCRIBER_HEALTH
    (SUBSCRIBER_KEY, COMPUTED_DATE, CHURN_PROPENSITY, UPSELL_PROPENSITY,
     NETWORK_QUALITY_SCORE, ENGAGEMENT_SCORE, PAYMENT_HEALTH_SCORE,
     COMPLAINT_TREND, USAGE_TREND_DATA, USAGE_TREND_VOICE,
     OVERALL_HEALTH_TIER, DAYS_TO_CONTRACT_END, RECOMMENDED_ACTION)
SELECT
    sub_key                                            AS SUBSCRIBER_KEY,
    d.FULL_DATE                                        AS COMPUTED_DATE,
    LEAST(1.0, GREATEST(0.01, ROUND(NORMAL(0.12, 0.10, RANDOM()), 4))) AS CHURN_PROPENSITY,
    LEAST(1.0, GREATEST(0.01, ROUND(NORMAL(0.25, 0.15, RANDOM()), 4))) AS UPSELL_PROPENSITY,
    GREATEST(1, LEAST(10, ROUND(NORMAL(7.5, 1.5, RANDOM()), 2))) AS NETWORK_QUALITY_SCORE,
    GREATEST(1, LEAST(10, ROUND(NORMAL(6.0, 2.0, RANDOM()), 2))) AS ENGAGEMENT_SCORE,
    GREATEST(1, LEAST(10, ROUND(NORMAL(8.0, 1.5, RANDOM()), 2))) AS PAYMENT_HEALTH_SCORE,
    GET(ARRAY_CONSTRUCT('IMPROVING', 'STABLE', 'STABLE', 'STABLE', 'WORSENING'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS COMPLAINT_TREND,
    GET(ARRAY_CONSTRUCT('INCREASING', 'INCREASING', 'STABLE', 'STABLE', 'DECLINING'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS USAGE_TREND_DATA,
    GET(ARRAY_CONSTRUCT('DECLINING', 'DECLINING', 'STABLE', 'STABLE', 'DECLINING'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS USAGE_TREND_VOICE,
    CASE
        WHEN NORMAL(0.12, 0.10, RANDOM()) > 0.25 THEN 'RED'
        WHEN NORMAL(0.12, 0.10, RANDOM()) > 0.10 THEN 'YELLOW'
        ELSE 'GREEN'
    END                                                AS OVERALL_HEALTH_TIER,
    GREATEST(0, UNIFORM(-6, 24, RANDOM()) * 30)       AS DAYS_TO_CONTRACT_END,
    GET(ARRAY_CONSTRUCT('NO_ACTION', 'NO_ACTION', 'PROACTIVE_OUTREACH', 'UPSELL_5G',
        'RETENTION_OFFER', 'PLAN_RIGHT_SIZE', 'COVERAGE_CHECK'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS RECOMMENDED_ACTION
FROM HORIZON_TELCO.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 10000, RANDOM()) AS sub_key FROM TABLE(GENERATOR(ROWCOUNT => 100))) subs
WHERE DAYOFWEEK(d.FULL_DATE) = 1  -- weekly Monday snapshots
  AND UNIFORM(0, 100, RANDOM()) < 30;

-- ============================================================================
-- 11. AGG_NETWORK_CAPACITY (daily by site)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.AGG_NETWORK_CAPACITY
    (SITE_KEY, DATE_KEY, PEAK_UTILIZATION_PCT, AVG_UTILIZATION_PCT, CAPACITY_HEADROOM_PCT,
     FORECAST_EXHAUSTION_DATE, CONGESTION_HOURS, AFFECTED_SUBSCRIBERS, UPGRADE_PRIORITY)
SELECT
    SITE_KEY,
    d.DATE_KEY,
    LEAST(100, GREATEST(20, ROUND(NORMAL(55, 18, RANDOM())
        * IFF(d.IS_WEEKEND, 0.85, 1.0)
        * (1.0 + 0.10 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 2))) AS PEAK_UTILIZATION_PCT,
    LEAST(85, GREATEST(10, ROUND(NORMAL(35, 12, RANDOM()), 2))) AS AVG_UTILIZATION_PCT,
    GREATEST(0, LEAST(80, ROUND(NORMAL(40, 15, RANDOM()), 2))) AS CAPACITY_HEADROOM_PCT,
    IFF(UNIFORM(0, 100, RANDOM()) < 20,
        DATEADD('month', UNIFORM(3, 24, RANDOM()), d.FULL_DATE), NULL) AS FORECAST_EXHAUSTION_DATE,
    GREATEST(0, ROUND(NORMAL(1.5, 1.5, RANDOM())))::INT AS CONGESTION_HOURS,
    GREATEST(0, ROUND(NORMAL(50, 40, RANDOM())))::INT  AS AFFECTED_SUBSCRIBERS,
    CASE
        WHEN NORMAL(55, 18, RANDOM()) > 75 THEN 'CRITICAL'
        WHEN NORMAL(55, 18, RANDOM()) > 60 THEN 'HIGH'
        WHEN NORMAL(55, 18, RANDOM()) > 45 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                AS UPGRADE_PRIORITY
FROM HORIZON_TELCO.GOLD.DIM_DATE d
CROSS JOIN (SELECT SITE_KEY FROM HORIZON_TELCO.GOLD.DIM_SITE LIMIT 100) sites
WHERE UNIFORM(0, 100, RANDOM()) < 10; -- ~10% of days per site

-- ============================================================================
-- 12. AGG_CAMPAIGN_PERFORMANCE (~500 campaign summaries)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.AGG_CAMPAIGN_PERFORMANCE
    (CAMPAIGN_ID, SEGMENT, SUBSCRIBERS_TARGETED, SUBSCRIBERS_REACHED,
     OPEN_RATE, CLICK_RATE, CONVERSION_RATE, REVENUE_ATTRIBUTED,
     COST_PER_ACQUISITION, ROI_PCT, INCREMENTAL_ARPU)
SELECT
    'CMP-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY)::VARCHAR, 5, '0') AS CAMPAIGN_ID,
    GET(ARRAY_CONSTRUCT('CONSUMER_HIGH_VALUE', 'CONSUMER_AT_RISK', 'SMB_GROWTH', 'NEW_ACTIVATIONS',
        'UPGRADE_5G', 'WINBACK', 'PREPAID_TO_POST', 'ENTERPRISE_EXPAND'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS SEGMENT,
    UNIFORM(5000, 200000, RANDOM())                    AS SUBSCRIBERS_TARGETED,
    UNIFORM(3000, 180000, RANDOM())                    AS SUBSCRIBERS_REACHED,
    LEAST(0.6, GREATEST(0.05, ROUND(NORMAL(0.22, 0.08, RANDOM()), 4))) AS OPEN_RATE,
    LEAST(0.3, GREATEST(0.01, ROUND(NORMAL(0.05, 0.03, RANDOM()), 4))) AS CLICK_RATE,
    LEAST(0.15, GREATEST(0.005, ROUND(NORMAL(0.025, 0.015, RANDOM()), 4))) AS CONVERSION_RATE,
    ROUND(EXP(NORMAL(10, 1.5, RANDOM())), 2)          AS REVENUE_ATTRIBUTED,
    ROUND(GREATEST(5, NORMAL(85, 40, RANDOM())), 2)   AS COST_PER_ACQUISITION,
    ROUND(NORMAL(180, 100, RANDOM()), 4)              AS ROI_PCT,
    ROUND(NORMAL(5, 3, RANDOM()), 2)                  AS INCREMENTAL_ARPU
FROM HORIZON_TELCO.GOLD.DIM_DATE d
WHERE DAY(d.FULL_DATE) = 15  -- one campaign review per month mid-month
  AND UNIFORM(0, 100, RANDOM()) < 70;

-- ============================================================================
-- 13. AGG_REVENUE_ASSURANCE (daily reconciliation)
-- ============================================================================
INSERT INTO HORIZON_TELCO.GOLD.AGG_REVENUE_ASSURANCE
    (DATE_KEY, SERVICE_TYPE, CDR_RATED_COUNT, CDR_BILLED_COUNT, RATED_REVENUE,
     BILLED_REVENUE, LEAKAGE_AMOUNT, LEAKAGE_PCT, ANOMALY_FLAG)
SELECT
    d.DATE_KEY,
    svc.SERVICE_TYPE                                   AS SERVICE_TYPE,
    UNIFORM(50000, 500000, RANDOM())                   AS CDR_RATED_COUNT,
    -- Billed slightly less than rated (leakage)
    UNIFORM(49000, 499000, RANDOM())                   AS CDR_BILLED_COUNT,
    ROUND(UNIFORM(50000, 500000, RANDOM()) * UNIFORM(1, 5, RANDOM()) / 100.0, 2) AS RATED_REVENUE,
    ROUND(UNIFORM(49000, 499000, RANDOM()) * UNIFORM(1, 5, RANDOM()) / 100.0, 2) AS BILLED_REVENUE,
    -- Leakage: usually 0.5-2%, occasional spikes
    ROUND(GREATEST(0, NORMAL(500, 300, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 5.0, 1.0)), 2) AS LEAKAGE_AMOUNT,
    LEAST(0.05, GREATEST(0.001, ROUND(NORMAL(0.012, 0.008, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 4.0, 1.0), 4))) AS LEAKAGE_PCT,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, TRUE, FALSE)   AS ANOMALY_FLAG
FROM HORIZON_TELCO.GOLD.DIM_DATE d
CROSS JOIN (SELECT column1 AS SERVICE_TYPE FROM VALUES ('VOICE'), ('DATA'), ('SMS'), ('ROAMING')) svc
WHERE UNIFORM(0, 100, RANDOM()) < 50;
