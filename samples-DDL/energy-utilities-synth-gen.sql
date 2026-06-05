-- ============================================================================
-- ENERGY & UTILITIES VERTICAL - Synthetic Data Generation
-- Entity: Meridian Energy Corp
-- Prerequisites: Run energy-utilities-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- Patterns: Summer AC peaks, winter heating, storm-correlated outages, sinusoidal load
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.AGG_REVENUE_BY_CLASS;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.AGG_RELIABILITY_MONTHLY;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.FACT_LOAD_PROFILE;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.FACT_ASSET_CONDITION;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.FACT_BILLING;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.FACT_OUTAGE;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.FACT_METER_DAILY;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.DIM_DATE;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.DIM_FEEDER;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.DIM_ASSET;
TRUNCATE TABLE MERIDIAN_ENERGY.GOLD.DIM_METER;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span with utility-specific attributes)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN TRUE ELSE FALSE END AS IS_WEEKEND,
    CASE WHEN MONTH(d) IN (12) AND DAY(d) = 25 THEN TRUE
         WHEN MONTH(d) = 1 AND DAY(d) = 1 THEN TRUE
         WHEN MONTH(d) = 7 AND DAY(d) = 4 THEN TRUE
         ELSE FALSE END                                AS IS_HOLIDAY,
    CASE WHEN MONTH(d) IN (6, 7, 8) THEN 'SUMMER'
         WHEN MONTH(d) IN (12, 1, 2) THEN 'WINTER'
         WHEN MONTH(d) IN (3, 4, 5) THEN 'SPRING'
         ELSE 'FALL' END                               AS SEASON,
    -- Heating degree days (base 65F): higher in winter
    GREATEST(0, ROUND(
        CASE WHEN MONTH(d) IN (12, 1, 2) THEN NORMAL(30, 8, RANDOM())
             WHEN MONTH(d) IN (3, 11) THEN NORMAL(15, 5, RANDOM())
             WHEN MONTH(d) IN (4, 10) THEN NORMAL(5, 3, RANDOM())
             ELSE 0 END, 1))                           AS HEATING_DEGREE_DAYS,
    -- Cooling degree days (base 65F): higher in summer
    GREATEST(0, ROUND(
        CASE WHEN MONTH(d) IN (7, 8) THEN NORMAL(18, 5, RANDOM())
             WHEN MONTH(d) IN (6, 9) THEN NORMAL(10, 4, RANDOM())
             WHEN MONTH(d) IN (5, 10) THEN NORMAL(3, 2, RANDOM())
             ELSE 0 END, 1))                           AS COOLING_DEGREE_DAYS
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_METER (~50K meters)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.DIM_METER
    (METER_KEY, METER_ID, ACCOUNT_ID, CUSTOMER_NAME, RATE_CLASS, SERVICE_TYPE,
     SERVICE_ADDRESS, CITY, STATE, ZIP_CODE, BUDGET_BILLING_FLAG, _IS_CURRENT)
SELECT
    seq                                                AS METER_KEY,
    'MTR-' || LPAD(seq::VARCHAR, 7, '0')               AS METER_ID,
    'ACC-' || LPAD(seq::VARCHAR, 7, '0')               AS ACCOUNT_ID,
    GET(ARRAY_CONSTRUCT('Smith Residence', 'Johnson Family', 'Williams Home', 'Brown Household',
        'Davis Property', 'Miller Residence', 'Wilson Home', 'Moore Family',
        'Taylor Household', 'Anderson Property', 'Metro Office Park', 'Sunrise Mall',
        'Valley Medical Center', 'Central High School', 'City Water Plant',
        'Greenfield Apartments', 'Riverside Plaza', 'Industrial Complex A',
        'Pacific Steel Works', 'Prairie Wind Farm'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR || ' (' || seq::VARCHAR || ')' AS CUSTOMER_NAME,
    -- Rate class: 60% residential, 30% commercial, 10% industrial
    GET(ARRAY_CONSTRUCT('RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL',
        'COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL', 'INDUSTRIAL'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS RATE_CLASS,
    GET(ARRAY_CONSTRUCT('ELECTRIC', 'ELECTRIC', 'ELECTRIC', 'ELECTRIC', 'GAS', 'COMBO'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS SERVICE_TYPE,
    LPAD(UNIFORM(100, 9999, RANDOM())::VARCHAR, 4, '0') || ' ' ||
        GET(ARRAY_CONSTRUCT('Main St', 'Oak Ave', 'Elm Dr', 'Park Blvd', 'Cedar Ln',
            'Maple Rd', 'Pine Way', 'Lake Dr', 'Hill Rd', 'River Ct'),
            UNIFORM(0, 9, RANDOM()))::VARCHAR          AS SERVICE_ADDRESS,
    GET(ARRAY_CONSTRUCT('Springfield', 'Riverside', 'Lakewood', 'Fairview', 'Georgetown',
        'Oakdale', 'Greenville', 'Salem', 'Madison', 'Clinton'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS CITY,
    GET(ARRAY_CONSTRUCT('OH', 'IN', 'IL', 'MI', 'KY', 'WV', 'PA', 'TN', 'VA', 'NC'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS STATE,
    LPAD(UNIFORM(40000, 49999, RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    IFF(UNIFORM(0, 100, RANDOM()) < 15, TRUE, FALSE)  AS BUDGET_BILLING_FLAG,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 50000)));

-- ============================================================================
-- 3. DIM_ASSET (~2000 distribution assets)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.DIM_ASSET
    (ASSET_KEY, ASSET_ID, ASSET_TYPE, MANUFACTURER, MODEL, INSTALLATION_DATE,
     AGE_YEARS, EXPECTED_LIFE_YEARS, CONDITION_SCORE, FEEDER_ID, SUBSTATION_ID,
     REPLACEMENT_COST, _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS ASSET_KEY,
    'AST-' || LPAD(seq::VARCHAR, 6, '0')               AS ASSET_ID,
    GET(ARRAY_CONSTRUCT('TRANSFORMER', 'TRANSFORMER', 'TRANSFORMER', 'POLE', 'POLE', 'POLE',
        'SWITCH', 'RECLOSER', 'CAPACITOR_BANK', 'REGULATOR'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ASSET_TYPE,
    GET(ARRAY_CONSTRUCT('ABB', 'Siemens', 'GE', 'Eaton', 'Schneider', 'Cooper Power',
        'S&C Electric', 'Howard Industries', 'Hubbell', 'Hitachi'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS MANUFACTURER,
    GET(ARRAY_CONSTRUCT('TX-500kVA', 'TX-1000kVA', 'TX-2500kVA', 'CL-45', 'CL-60', 'CL-70',
        'SW-Auto', 'RC-Triple', 'CB-300kVAR', 'VR-32Step'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS MODEL,
    DATEADD('day', -UNIFORM(365, 14600, RANDOM()), CURRENT_DATE()) AS INSTALLATION_DATE,
    ROUND(UNIFORM(1, 40, RANDOM()) + NORMAL(0, 3, RANDOM()), 1) AS AGE_YEARS,
    GET(ARRAY_CONSTRUCT(30, 35, 40, 45, 50), UNIFORM(0, 4, RANDOM()))::NUMBER AS EXPECTED_LIFE_YEARS,
    -- Condition: degrades with age (100=new)
    GREATEST(10, LEAST(100, ROUND(100 - UNIFORM(1, 40, RANDOM()) * 2.0 + NORMAL(0, 8, RANDOM()))))::INT AS CONDITION_SCORE,
    'FDR-' || LPAD(UNIFORM(1, 100, RANDOM())::VARCHAR, 4, '0') AS FEEDER_ID,
    'SUB-' || LPAD(UNIFORM(1, 20, RANDOM())::VARCHAR, 3, '0') AS SUBSTATION_ID,
    ROUND(EXP(NORMAL(10.5, 1.2, RANDOM())), 2)        AS REPLACEMENT_COST,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 2000)));

-- ============================================================================
-- 4. DIM_FEEDER (100 feeders)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.DIM_FEEDER
    (FEEDER_KEY, FEEDER_ID, SUBSTATION_ID, SUBSTATION_NAME, VOLTAGE_LEVEL,
     TOTAL_CUSTOMERS, CIRCUIT_MILES, OVERHEAD_PCT, UNDERGROUND_PCT, REGION)
SELECT
    seq                                                AS FEEDER_KEY,
    'FDR-' || LPAD(seq::VARCHAR, 4, '0')               AS FEEDER_ID,
    'SUB-' || LPAD(CEIL(seq / 5.0)::VARCHAR, 3, '0')  AS SUBSTATION_ID,
    GET(ARRAY_CONSTRUCT('Riverside Sub', 'Lakewood Sub', 'Fairview Sub', 'Oakdale Sub',
        'Summit Sub', 'Valley Sub', 'Central Sub', 'Westside Sub', 'Eastgate Sub', 'Northpark Sub',
        'Greenfield Sub', 'Hillcrest Sub', 'Meadow Sub', 'Bayshore Sub', 'Pinecrest Sub',
        'Harbor Sub', 'Sunset Sub', 'Highland Sub', 'Brookside Sub', 'Edgewood Sub'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS SUBSTATION_NAME,
    GET(ARRAY_CONSTRUCT('PRIMARY', 'PRIMARY', 'PRIMARY', 'PRIMARY', 'SUB_TRANSMISSION'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS VOLTAGE_LEVEL,
    UNIFORM(200, 3000, RANDOM())                       AS TOTAL_CUSTOMERS,
    ROUND(UNIFORM(3, 25, RANDOM()) + NORMAL(0, 2, RANDOM()), 2) AS CIRCUIT_MILES,
    ROUND(UNIFORM(30, 80, RANDOM()) * 1.0, 2)         AS OVERHEAD_PCT,
    ROUND(UNIFORM(20, 70, RANDOM()) * 1.0, 2)         AS UNDERGROUND_PCT,
    GET(ARRAY_CONSTRUCT('Northern', 'Southern', 'Eastern', 'Western', 'Central'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS REGION
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- ============================================================================
-- 5. FACT_METER_DAILY (~200K rows, meter x day sample)
-- Strong seasonality: summer AC peaks Jul-Aug, winter heating Dec-Feb
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.FACT_METER_DAILY
    (DATE_KEY, METER_KEY, TOTAL_KWH_DELIVERED, TOTAL_KWH_RECEIVED, PEAK_DEMAND_KW,
     AVG_VOLTAGE, AVG_POWER_FACTOR, READ_COUNT, ESTIMATED_READ_COUNT,
     ON_PEAK_KWH, OFF_PEAK_KWH)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    mtr_key                                            AS METER_KEY,
    -- KWH: strong seasonal pattern (summer AC + winter heating)
    GREATEST(5, ROUND(NORMAL(35, 15, RANDOM())
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.60 ELSE 0 END       -- summer AC peak
            + CASE WHEN MONTH(d.FULL_DATE) IN (6, 9) THEN 0.30 ELSE 0 END       -- shoulder summer
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.40 ELSE 0 END   -- winter heating
            + CASE WHEN MONTH(d.FULL_DATE) IN (11, 3) THEN 0.15 ELSE 0 END      -- shoulder winter
        )
        * IFF(DAYOFWEEK(d.FULL_DATE) IN (0, 6), 1.1, 1.0)  -- slightly higher weekends (home)
        * IFF(UNIFORM(0, 1000, RANDOM()) < 5, 3.0, 1.0)     -- 0.5% meter anomalies
    , 3))                                              AS TOTAL_KWH_DELIVERED,
    -- Net metering (solar): ~5% of meters, higher in summer
    IFF(UNIFORM(0, 100, RANDOM()) < 5,
        ROUND(NORMAL(8, 4, RANDOM())
            * CASE WHEN MONTH(d.FULL_DATE) IN (5,6,7,8) THEN 1.5 ELSE 0.5 END, 3), 0) AS TOTAL_KWH_RECEIVED,
    ROUND(GREATEST(1, NORMAL(5.0, 2.5, RANDOM())
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.5 ELSE 0 END)), 3) AS PEAK_DEMAND_KW,
    -- Voltage: normally 120V +/- 5%
    ROUND(NORMAL(120.0, 2.5, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 1, 0.92, 1.0), 2) AS AVG_VOLTAGE,  -- rare sags
    LEAST(1.0, GREATEST(0.70, ROUND(NORMAL(0.95, 0.03, RANDOM()), 4))) AS AVG_POWER_FACTOR,
    96                                                 AS READ_COUNT,  -- 15-min intervals x 24hr
    IFF(UNIFORM(0, 100, RANDOM()) < 2, UNIFORM(1, 10, RANDOM()), 0) AS ESTIMATED_READ_COUNT,
    -- On-peak: ~40% of total during peak hours
    ROUND(GREATEST(5, NORMAL(35, 15, RANDOM())) * 0.40, 3) AS ON_PEAK_KWH,
    ROUND(GREATEST(5, NORMAL(35, 15, RANDOM())) * 0.60, 3) AS OFF_PEAK_KWH
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 50000, RANDOM()) AS mtr_key FROM TABLE(GENERATOR(ROWCOUNT => 5))) meters
WHERE UNIFORM(0, 100, RANDOM()) < 20;  -- sample to control volume

-- ============================================================================
-- 6. FACT_OUTAGE (~5K outage events across 5 years)
-- Weather-correlated (storms Jun-Sep), power law duration, tree-contact in spring/fall
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.FACT_OUTAGE
    (DATE_KEY, FEEDER_KEY, OUTAGE_ID, DURATION_MINUTES, CUSTOMERS_AFFECTED,
     CAUSE_CODE, OUTAGE_TYPE, SAIDI_CONTRIBUTION, SAIFI_CONTRIBUTION,
     RESTORATION_PRIORITY, CREW_RESPONSE_MINUTES)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 100, RANDOM())                          AS FEEDER_KEY,
    'OUT-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY)::VARCHAR, 7, '0') AS OUTAGE_ID,
    -- Duration: power law (most short, few long)
    GREATEST(5, ROUND(EXP(NORMAL(4.0, 1.2, RANDOM()))
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 5.0, 1.0)))::INT AS DURATION_MINUTES, -- 3% major events
    -- Customers affected: varies widely
    GREATEST(1, ROUND(EXP(NORMAL(4.5, 1.5, RANDOM()))))::INT AS CUSTOMERS_AFFECTED,
    -- Cause codes: weather-heavy in storm season, vegetation in spring/fall
    CASE
        WHEN MONTH(d.FULL_DATE) IN (6, 7, 8, 9) AND UNIFORM(0, 100, RANDOM()) < 45 THEN 'WEATHER'
        WHEN MONTH(d.FULL_DATE) IN (4, 5, 10, 11) AND UNIFORM(0, 100, RANDOM()) < 30 THEN 'VEGETATION'
        ELSE GET(ARRAY_CONSTRUCT('EQUIPMENT', 'EQUIPMENT', 'ANIMAL', 'VEGETATION', 'WEATHER', 'UNKNOWN'),
            UNIFORM(0, 5, RANDOM()))::VARCHAR
    END                                                AS CAUSE_CODE,
    GET(ARRAY_CONSTRUCT('SUSTAINED', 'SUSTAINED', 'SUSTAINED', 'MOMENTARY', 'MOMENTARY', 'PLANNED'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS OUTAGE_TYPE,
    -- SAIDI: duration * customers / total customers
    ROUND(EXP(NORMAL(4.0, 1.2, RANDOM())) * EXP(NORMAL(4.5, 1.5, RANDOM())) / 150000.0, 4) AS SAIDI_CONTRIBUTION,
    -- SAIFI: customers / total customers
    ROUND(EXP(NORMAL(4.5, 1.5, RANDOM())) / 150000.0, 6) AS SAIFI_CONTRIBUTION,
    GET(ARRAY_CONSTRUCT('P1', 'P2', 'P2', 'P3', 'P3'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS RESTORATION_PRIORITY,
    GREATEST(5, ROUND(EXP(NORMAL(3.5, 0.8, RANDOM()))))::INT AS CREW_RESPONSE_MINUTES
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    -- Higher outage rate in storm season and winter ice
    2
    + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8, 9) THEN 3 ELSE 0 END  -- storm season
    + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 2 ELSE 0 END    -- ice storms
    + CASE WHEN MONTH(d.FULL_DATE) IN (4, 5) THEN 1 ELSE 0 END        -- spring growth
);

-- ============================================================================
-- 7. FACT_BILLING (monthly per meter sample)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.FACT_BILLING
    (DATE_KEY, METER_KEY, KWH_BILLED, DEMAND_KW_BILLED, AMOUNT_BILLED,
     AMOUNT_COLLECTED, REVENUE_CLASS, DAYS_IN_PERIOD, AVG_RATE_PER_KWH)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    mtr_key                                            AS METER_KEY,
    -- KWH billed: seasonal
    GREATEST(100, ROUND(NORMAL(900, 400, RANDOM())
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.50 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.35 ELSE 0 END
        ), 3))                                         AS KWH_BILLED,
    ROUND(GREATEST(2, NORMAL(8, 4, RANDOM())), 3)     AS DEMAND_KW_BILLED,
    -- Amount: based on usage + fixed charges
    ROUND(GREATEST(20, NORMAL(120, 60, RANDOM())
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.45 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.30 ELSE 0 END
        )
        * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)) -- rate increases
    ), 2)                                              AS AMOUNT_BILLED,
    -- Collected: mostly full, some partial
    ROUND(GREATEST(20, NORMAL(120, 60, RANDOM()))
        * IFF(UNIFORM(0, 100, RANDOM()) < 92, 1.0, UNIFORM(40, 85, RANDOM()) / 100.0), 2) AS AMOUNT_COLLECTED,
    GET(ARRAY_CONSTRUCT('RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL', 'RESIDENTIAL',
        'COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL', 'INDUSTRIAL'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS REVENUE_CLASS,
    UNIFORM(28, 33, RANDOM())                          AS DAYS_IN_PERIOD,
    -- Rate per kWh: residential ~$0.12, commercial ~$0.10, industrial ~$0.08
    ROUND(NORMAL(0.11, 0.02, RANDOM())
        * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 5) AS AVG_RATE_PER_KWH
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 50000, RANDOM()) AS mtr_key FROM TABLE(GENERATOR(ROWCOUNT => 20))) meters
WHERE DAY(d.FULL_DATE) = 1;  -- monthly billing

-- ============================================================================
-- 8. FACT_ASSET_CONDITION (quarterly snapshots)
-- Degrading over time, random failures
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.FACT_ASSET_CONDITION
    (DATE_KEY, ASSET_KEY, CONDITION_SCORE, FAILURE_PROBABILITY, MAINTENANCE_COST_YTD,
     WORK_ORDERS_YTD, DAYS_SINCE_INSPECTION, REMAINING_LIFE_YEARS, RISK_PRIORITY_NUMBER)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    ast_key                                            AS ASSET_KEY,
    -- Condition score: degrades slightly each quarter
    GREATEST(10, LEAST(100, ROUND(80 - UNIFORM(0, 50, RANDOM())
        + NORMAL(0, 5, RANDOM())
        - 0.5 * DATEDIFF('quarter', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)
    )))::INT                                           AS CONDITION_SCORE,
    -- Failure probability: inversely correlated with condition
    LEAST(0.50, GREATEST(0.001, ROUND(
        0.01 + (100 - GREATEST(10, 80 - UNIFORM(0, 50, RANDOM()))) / 200.0
        + NORMAL(0, 0.02, RANDOM()), 4)))              AS FAILURE_PROBABILITY,
    ROUND(GREATEST(0, EXP(NORMAL(7.5, 1.5, RANDOM()))), 2) AS MAINTENANCE_COST_YTD,
    GREATEST(0, ROUND(NORMAL(2, 1.5, RANDOM())))::INT  AS WORK_ORDERS_YTD,
    UNIFORM(30, 730, RANDOM())                         AS DAYS_SINCE_INSPECTION,
    GREATEST(0, ROUND(NORMAL(15, 8, RANDOM()), 1))    AS REMAINING_LIFE_YEARS,
    -- Risk priority: condition x consequence
    LEAST(100, GREATEST(1, ROUND(NORMAL(35, 18, RANDOM()), 2))) AS RISK_PRIORITY_NUMBER
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 2000, RANDOM()) AS ast_key FROM TABLE(GENERATOR(ROWCOUNT => 50))) assets
WHERE MONTH(d.FULL_DATE) IN (3, 6, 9, 12) AND DAY(d.FULL_DATE) = 1;  -- quarterly

-- ============================================================================
-- 9. FACT_LOAD_PROFILE (hourly x feeder, sampled)
-- Sinusoidal daily pattern, seasonal amplitude shift
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.FACT_LOAD_PROFILE
    (DATE_KEY, FEEDER_KEY, HOUR, LOAD_MW, CAPACITY_MW, UTILIZATION_PCT,
     TEMPERATURE_F, IS_PEAK_HOUR, FORECAST_LOAD_MW, FORECAST_ERROR_PCT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    fdr_key                                            AS FEEDER_KEY,
    hr                                                 AS HOUR,
    -- Load: sinusoidal daily pattern with seasonal amplitude
    GREATEST(0.5, ROUND(NORMAL(8, 2, RANDOM())
        * (0.6 + 0.4 * SIN(3.14159 * (hr - 6) / 12.0))  -- daily sinusoid peak at noon
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.40 ELSE 0 END     -- summer peak
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.25 ELSE 0 END -- winter peak
            + CASE WHEN hr BETWEEN 14 AND 18 THEN 0.20 ELSE 0 END             -- afternoon peak
        )
        * IFF(d.IS_WEEKEND, 0.85, 1.0)
    , 3))                                              AS LOAD_MW,
    ROUND(NORMAL(15, 3, RANDOM()), 3)                  AS CAPACITY_MW,
    -- Utilization: load/capacity
    LEAST(100, GREATEST(5, ROUND(
        (NORMAL(8, 2, RANDOM()) * (0.6 + 0.4 * SIN(3.14159 * (hr - 6) / 12.0)))
        / NORMAL(15, 3, RANDOM()) * 100
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 1.5, 1.0), 2))) AS UTILIZATION_PCT,
    -- Temperature: follows seasonal + diurnal pattern
    ROUND(NORMAL(60, 15, RANDOM())
        + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 25 WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN -15 ELSE 0 END
        + 5 * SIN(3.14159 * (hr - 4) / 12.0), 1)     AS TEMPERATURE_F,
    IFF(hr BETWEEN 14 AND 19, TRUE, FALSE)            AS IS_PEAK_HOUR,
    -- Forecast: close to actual with small error
    GREATEST(0.5, ROUND(NORMAL(8, 2, RANDOM())
        * (0.6 + 0.4 * SIN(3.14159 * (hr - 6) / 12.0))
        * (1.0 + NORMAL(0, 0.05, RANDOM())), 3))      AS FORECAST_LOAD_MW,
    ROUND(NORMAL(3, 2, RANDOM()), 2)                   AS FORECAST_ERROR_PCT
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 100, RANDOM()) AS fdr_key FROM TABLE(GENERATOR(ROWCOUNT => 5))) feeders
CROSS JOIN (SELECT SEQ4() AS hr FROM TABLE(GENERATOR(ROWCOUNT => 24))) hours
WHERE UNIFORM(0, 100, RANDOM()) < 3;  -- heavy sampling control

-- ============================================================================
-- 10. AGG_RELIABILITY_MONTHLY (SAIDI/SAIFI rollup per feeder)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.AGG_RELIABILITY_MONTHLY
    (MONTH_KEY, FEEDER_KEY, SAIDI_MINUTES, SAIFI_EVENTS, CAIDI_MINUTES,
     MAIFI_EVENTS, CUSTOMERS_SERVED, OUTAGE_COUNT, MAJOR_EVENT_COUNT, WORST_CAUSE)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    fdr_key                                            AS FEEDER_KEY,
    -- SAIDI: higher in storm season
    GREATEST(0, ROUND(NORMAL(15, 10, RANDOM())
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8, 9) THEN 0.60 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.30 ELSE 0 END
        )
        * IFF(UNIFORM(0, 100, RANDOM()) < 5, 4.0, 1.0), 4)) AS SAIDI_MINUTES, -- 5% major event months
    LEAST(2.0, GREATEST(0, ROUND(NORMAL(0.12, 0.08, RANDOM())
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8, 9) THEN 0.50 ELSE 0 END), 6))) AS SAIFI_EVENTS,
    -- CAIDI: SAIDI / SAIFI (avg outage duration)
    GREATEST(30, ROUND(NORMAL(90, 40, RANDOM()), 4))  AS CAIDI_MINUTES,
    LEAST(5.0, GREATEST(0, ROUND(NORMAL(0.3, 0.2, RANDOM()), 6))) AS MAIFI_EVENTS,
    UNIFORM(500, 3000, RANDOM())                       AS CUSTOMERS_SERVED,
    GREATEST(0, ROUND(NORMAL(3, 2, RANDOM())
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8, 9) THEN 0.5 ELSE 0 END)))::INT AS OUTAGE_COUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, UNIFORM(1, 3, RANDOM()), 0) AS MAJOR_EVENT_COUNT,
    CASE
        WHEN MONTH(d.FULL_DATE) IN (6, 7, 8, 9) THEN
            GET(ARRAY_CONSTRUCT('WEATHER', 'WEATHER', 'EQUIPMENT', 'VEGETATION'), UNIFORM(0, 3, RANDOM()))::VARCHAR
        WHEN MONTH(d.FULL_DATE) IN (4, 5, 10, 11) THEN
            GET(ARRAY_CONSTRUCT('VEGETATION', 'EQUIPMENT', 'ANIMAL', 'WEATHER'), UNIFORM(0, 3, RANDOM()))::VARCHAR
        ELSE
            GET(ARRAY_CONSTRUCT('EQUIPMENT', 'WEATHER', 'UNKNOWN', 'ANIMAL'), UNIFORM(0, 3, RANDOM()))::VARCHAR
    END                                                AS WORST_CAUSE
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 100, RANDOM()) AS fdr_key FROM TABLE(GENERATOR(ROWCOUNT => 10))) feeders
WHERE DAY(d.FULL_DATE) = 1;

-- ============================================================================
-- 11. AGG_REVENUE_BY_CLASS (monthly per rate class)
-- ============================================================================
INSERT INTO MERIDIAN_ENERGY.GOLD.AGG_REVENUE_BY_CLASS
    (MONTH_KEY, RATE_CLASS, KWH_SOLD, REVENUE, CUSTOMER_COUNT,
     AVG_RATE_PER_KWH, DEMAND_MW_PEAK, LOAD_FACTOR, REVENUE_PER_CUSTOMER)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    rate_class                                         AS RATE_CLASS,
    -- KWH sold: seasonal and by class
    ROUND(EXP(NORMAL(17, 0.8, RANDOM()))
        * IFF(rate_class = 'INDUSTRIAL', 3.0, IFF(rate_class = 'COMMERCIAL', 1.5, 1.0))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.35 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.20 ELSE 0 END
        )
        * (1.0 + 0.02 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 3) AS KWH_SOLD,
    -- Revenue: KWH * rate
    ROUND(EXP(NORMAL(14.5, 0.8, RANDOM()))
        * IFF(rate_class = 'INDUSTRIAL', 2.5, IFF(rate_class = 'COMMERCIAL', 1.4, 1.0))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8) THEN 0.35 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.20 ELSE 0 END
        )
        * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 2) AS REVENUE,
    IFF(rate_class = 'RESIDENTIAL', UNIFORM(25000, 35000, RANDOM()),
        IFF(rate_class = 'COMMERCIAL', UNIFORM(8000, 15000, RANDOM()),
            UNIFORM(500, 2000, RANDOM())))             AS CUSTOMER_COUNT,
    -- Rate per kWh by class
    ROUND(CASE rate_class
        WHEN 'RESIDENTIAL' THEN NORMAL(0.125, 0.01, RANDOM())
        WHEN 'COMMERCIAL' THEN NORMAL(0.105, 0.008, RANDOM())
        ELSE NORMAL(0.078, 0.006, RANDOM())
    END * (1.0 + 0.03 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)), 5) AS AVG_RATE_PER_KWH,
    ROUND(GREATEST(10, NORMAL(250, 80, RANDOM())
        * IFF(rate_class = 'INDUSTRIAL', 2.0, IFF(rate_class = 'COMMERCIAL', 1.3, 1.0))), 3) AS DEMAND_MW_PEAK,
    LEAST(0.95, GREATEST(0.35, ROUND(NORMAL(0.60, 0.10, RANDOM())
        * IFF(rate_class = 'INDUSTRIAL', 1.2, IFF(rate_class = 'RESIDENTIAL', 0.85, 1.0)), 4))) AS LOAD_FACTOR,
    ROUND(GREATEST(30, NORMAL(120, 50, RANDOM())
        * IFF(rate_class = 'INDUSTRIAL', 5.0, IFF(rate_class = 'COMMERCIAL', 2.5, 1.0))), 2) AS REVENUE_PER_CUSTOMER
FROM MERIDIAN_ENERGY.GOLD.DIM_DATE d
CROSS JOIN (SELECT column1 AS rate_class FROM VALUES ('RESIDENTIAL'), ('COMMERCIAL'), ('INDUSTRIAL')) classes
WHERE DAY(d.FULL_DATE) = 1;
