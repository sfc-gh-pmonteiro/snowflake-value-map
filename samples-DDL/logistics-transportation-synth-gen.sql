-- ============================================================================
-- LOGISTICS & TRANSPORTATION VERTICAL - Synthetic Data Generation
-- Entity: Atlas Logistics Inc (3PL/Freight)
-- Prerequisites: Run logistics-transportation-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- Seasonality: Holiday peak Oct-Dec (+40%), summer produce Jun-Aug (+15%),
--              weather delays in winter, Monday/Friday warehouse peaks
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.AGG_FACILITY_KPI;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.AGG_LANE_ECONOMICS;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.AGG_CARRIER_SCORECARD;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.FACT_DELIVERY_PERFORMANCE;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.FACT_WAREHOUSE_THROUGHPUT;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.FACT_FLEET_DAILY;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.FACT_SHIPMENT;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.DIM_DATE;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.DIM_LANE;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.DIM_FACILITY;
TRUNCATE TABLE ATLAS_LOGISTICS.GOLD.DIM_CARRIER;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) NOT IN (0, 6) THEN TRUE ELSE FALSE END AS IS_BUSINESS_DAY,
    YEAR(d)                                            AS FISCAL_YEAR,
    MONTH(d)                                           AS FISCAL_PERIOD
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_CARRIER (50 carriers)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.DIM_CARRIER
    (CARRIER_KEY, CARRIER_ID, CARRIER_NAME, CARRIER_TYPE, SCAC_CODE,
     SAFETY_RATING, STATUS, INSURANCE_CURRENT, _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS CARRIER_KEY,
    'CAR-' || LPAD(seq::VARCHAR, 4, '0')               AS CARRIER_ID,
    GET(ARRAY_CONSTRUCT('Swift Transport', 'Werner Enterprises', 'Schneider National', 'J.B. Hunt',
        'Knight Transportation', 'Heartland Express', 'Old Dominion Freight', 'XPO Logistics',
        'Saia Inc', 'Estes Express', 'R+L Carriers', 'FedEx Freight', 'ABF Freight',
        'YRC Worldwide', 'Holland Motor Express', 'Conway Freight', 'UPS Freight',
        'Central Transport', 'Southeastern Freight', 'Averitt Express'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR || ' (' || seq::VARCHAR || ')' AS CARRIER_NAME,
    GET(ARRAY_CONSTRUCT('ASSET', 'ASSET', 'ASSET', 'BROKERAGE', 'BROKERAGE', 'INTERMODAL', 'PARCEL', 'DRAYAGE'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS CARRIER_TYPE,
    UPPER(SUBSTR(GET(ARRAY_CONSTRUCT('SWFT', 'WERN', 'SNDR', 'JBHT', 'KNGT', 'HTLD', 'ODFL', 'XPOL',
        'SAIA', 'ESTE', 'RLCA', 'FDXF', 'ABFR', 'YRCW', 'HOLM', 'CNWY', 'UPSF',
        'CTII', 'SEFL', 'AVRT'), UNIFORM(0, 19, RANDOM()))::VARCHAR, 1, 4)) AS SCAC_CODE,
    GET(ARRAY_CONSTRUCT('SATISFACTORY', 'SATISFACTORY', 'SATISFACTORY', 'SATISFACTORY', 'CONDITIONAL'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS SAFETY_RATING,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, 'SUSPENDED',
        IFF(UNIFORM(0, 100, RANDOM()) < 8, 'INACTIVE', 'ACTIVE')) AS STATUS,
    IFF(UNIFORM(0, 100, RANDOM()) < 95, TRUE, FALSE)  AS INSURANCE_CURRENT,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- ============================================================================
-- 3. DIM_FACILITY (20 facilities)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.DIM_FACILITY
    (FACILITY_KEY, FACILITY_ID, FACILITY_NAME, FACILITY_TYPE, ADDRESS, CITY, STATE,
     REGION, CAPACITY_SQFT, DOCK_DOORS)
SELECT
    seq                                                AS FACILITY_KEY,
    'FAC-' || LPAD(seq::VARCHAR, 3, '0')               AS FACILITY_ID,
    GET(ARRAY_CONSTRUCT('Atlanta Hub', 'Chicago Gateway', 'Dallas Distribution Center', 'Los Angeles Terminal',
        'Newark Cross-Dock', 'Memphis Sort Center', 'Louisville Hub', 'Phoenix DC',
        'Seattle Cold Storage', 'Miami Import Center', 'Denver Regional', 'Charlotte Hub',
        'Indianapolis Cross-Dock', 'Kansas City Terminal', 'Columbus DC',
        'Nashville Sort', 'Salt Lake Distribution', 'Portland Cold Storage',
        'Houston Gateway', 'Philadelphia Terminal'),
        seq - 1)::VARCHAR                              AS FACILITY_NAME,
    GET(ARRAY_CONSTRUCT('DISTRIBUTION_CENTER', 'DISTRIBUTION_CENTER', 'CROSS_DOCK', 'CROSS_DOCK',
        'COLD_STORAGE', 'YARD'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS FACILITY_TYPE,
    '123 Industrial Pkwy'                              AS ADDRESS,
    GET(ARRAY_CONSTRUCT('Atlanta', 'Chicago', 'Dallas', 'Los Angeles', 'Newark',
        'Memphis', 'Louisville', 'Phoenix', 'Seattle', 'Miami',
        'Denver', 'Charlotte', 'Indianapolis', 'Kansas City', 'Columbus',
        'Nashville', 'Salt Lake City', 'Portland', 'Houston', 'Philadelphia'),
        seq - 1)::VARCHAR                              AS CITY,
    GET(ARRAY_CONSTRUCT('GA', 'IL', 'TX', 'CA', 'NJ', 'TN', 'KY', 'AZ', 'WA', 'FL',
        'CO', 'NC', 'IN', 'MO', 'OH', 'TN', 'UT', 'OR', 'TX', 'PA'),
        seq - 1)::VARCHAR                              AS STATE,
    GET(ARRAY_CONSTRUCT('Southeast', 'Midwest', 'Southwest', 'West', 'Northeast',
        'Southeast', 'Midwest', 'Southwest', 'West', 'Southeast',
        'West', 'Southeast', 'Midwest', 'Midwest', 'Midwest',
        'Southeast', 'West', 'West', 'Southwest', 'Northeast'),
        seq - 1)::VARCHAR                              AS REGION,
    UNIFORM(50000, 500000, RANDOM())                   AS CAPACITY_SQFT,
    UNIFORM(12, 120, RANDOM())                         AS DOCK_DOORS
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 20)));

-- ============================================================================
-- 4. DIM_LANE (200 lanes)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.DIM_LANE
    (LANE_KEY, LANE_ID, ORIGIN_REGION, DESTINATION_REGION, DISTANCE_MILES, MODE, TRANSIT_DAYS_STD)
SELECT
    seq                                                AS LANE_KEY,
    'LN-' || LPAD(seq::VARCHAR, 4, '0')                AS LANE_ID,
    GET(ARRAY_CONSTRUCT('Southeast', 'Midwest', 'Northeast', 'Southwest', 'West',
        'Mid-Atlantic', 'Great Lakes', 'Pacific NW', 'Gulf Coast', 'Mountain'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ORIGIN_REGION,
    GET(ARRAY_CONSTRUCT('Southeast', 'Midwest', 'Northeast', 'Southwest', 'West',
        'Mid-Atlantic', 'Great Lakes', 'Pacific NW', 'Gulf Coast', 'Mountain'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS DESTINATION_REGION,
    ROUND(UNIFORM(100, 3000, RANDOM()), 1)             AS DISTANCE_MILES,
    GET(ARRAY_CONSTRUCT('FTL', 'FTL', 'FTL', 'LTL', 'LTL', 'INTERMODAL', 'PARCEL'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS MODE,
    GREATEST(1, ROUND(UNIFORM(100, 3000, RANDOM()) / 500.0)::INT) AS TRANSIT_DAYS_STD
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 200)));

-- ============================================================================
-- 5. FACT_SHIPMENT (~100K shipments)
-- Seasonality: Holiday peak Oct-Dec (+40%), summer produce Jun-Aug (+15%)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.FACT_SHIPMENT
    (DATE_KEY, LANE_KEY, CARRIER_KEY, FACILITY_KEY, ON_TIME_FLAG,
     TRANSIT_DAYS, COST_TOTAL, COST_PER_MILE, WEIGHT_LBS, PIECES,
     SERVICE_LEVEL, EXCEPTION_FLAG)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 200, RANDOM())                          AS LANE_KEY,
    UNIFORM(1, 50, RANDOM())                           AS CARRIER_KEY,
    UNIFORM(1, 20, RANDOM())                           AS FACILITY_KEY,
    -- On-time: 88% average, degraded in winter
    IFF(UNIFORM(0, 100, RANDOM()) < (
        88
        - CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 8 ELSE 0 END   -- winter delays
        - CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 3 ELSE 0 END -- peak congestion
    ), TRUE, FALSE)                                    AS ON_TIME_FLAG,
    -- Transit days: log-normal (mode 2, tail to 14)
    GREATEST(0.5, LEAST(21.0, ROUND(EXP(NORMAL(0.9, 0.5, RANDOM()))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.3 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11) THEN 0.15 ELSE 0 END
        )
    , 1)))                                             AS TRANSIT_DAYS,
    -- Cost: varies by distance and service
    ROUND(EXP(NORMAL(6.8, 0.9, RANDOM()))
        * (1.0 + 0.04 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60) -- 4% annual inflation
        * IFF(UNIFORM(0, 1000, RANDOM()) < 5, 4.0, 1.0) -- 0.5% cost anomaly
    , 2)                                               AS COST_TOTAL,
    ROUND(UNIFORM(150, 450, RANDOM()) / 100.0
        * (1.0 + 0.035 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60)
    , 4)                                               AS COST_PER_MILE,
    -- Weight: log-normal
    ROUND(EXP(NORMAL(8.5, 1.2, RANDOM())), 2)         AS WEIGHT_LBS,
    UNIFORM(1, 40, RANDOM())                           AS PIECES,
    GET(ARRAY_CONSTRUCT('FTL', 'FTL', 'FTL', 'LTL', 'LTL', 'EXPEDITED', 'PARCEL', 'INTERMODAL'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS SERVICE_LEVEL,
    -- Exceptions: ~5%, more in winter
    IFF(UNIFORM(0, 100, RANDOM()) < (
        5
        + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 4 ELSE 0 END
        + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11) THEN 2 ELSE 0 END
    ), TRUE, FALSE)                                    AS EXCEPTION_FLAG
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < (
      30
      + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 18 ELSE 0 END  -- holiday peak
      + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8) THEN 8 ELSE 0 END     -- summer produce
      + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (1, 5) THEN 5 ELSE 0 END    -- Mon/Fri shipping
  );

-- ============================================================================
-- 6. FACT_FLEET_DAILY (~80K vehicle × day records)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.FACT_FLEET_DAILY
    (DATE_KEY, VEHICLE_ID, MILES_DRIVEN, FUEL_GALLONS, IDLE_HOURS,
     DRIVE_HOURS, SPEED_AVG, HARD_BRAKES, MPG, UTILIZATION_PCT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    'VEH-' || LPAD(UNIFORM(1, 500, RANDOM())::VARCHAR, 5, '0') AS VEHICLE_ID,
    -- Miles: correlate with shipment volume seasonality
    ROUND(GREATEST(0, NORMAL(350, 120, RANDOM())
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.30 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8) THEN 0.10 ELSE 0 END
        )
    ), 1)                                              AS MILES_DRIVEN,
    -- Fuel: derived from miles and efficiency
    ROUND(GREATEST(0, NORMAL(350, 120, RANDOM()) / UNIFORM(5, 8, RANDOM())), 2) AS FUEL_GALLONS,
    ROUND(GREATEST(0, NORMAL(1.5, 0.8, RANDOM())), 2) AS IDLE_HOURS,
    GREATEST(0, LEAST(11.0, ROUND(NORMAL(8.5, 1.5, RANDOM()), 2))) AS DRIVE_HOURS,
    ROUND(GREATEST(30, LEAST(70, NORMAL(52, 8, RANDOM()))), 1) AS SPEED_AVG,
    GREATEST(0, ROUND(NORMAL(2, 2, RANDOM()))::INT)    AS HARD_BRAKES,
    -- MPG: varies by vehicle age and conditions
    ROUND(GREATEST(3.0, LEAST(10.0, NORMAL(6.2, 1.0, RANDOM()))), 2) AS MPG,
    -- Utilization: percentage of available hours driven
    LEAST(1.0, GREATEST(0.0, ROUND(NORMAL(0.72, 0.15, RANDOM()), 4))) AS UTILIZATION_PCT
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 35;  -- sample ~35% of days per vehicle

-- ============================================================================
-- 7. FACT_WAREHOUSE_THROUGHPUT (daily per facility)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.FACT_WAREHOUSE_THROUGHPUT
    (DATE_KEY, FACILITY_KEY, ORDERS_RECEIVED, ORDERS_SHIPPED, UNITS_PICKED,
     PICK_ACCURACY_PCT, DOCK_TO_STOCK_HOURS, LINES_PER_LABOR_HR)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    fac                                                AS FACILITY_KEY,
    -- Orders received: Mon/Fri peaks from weekend ordering
    GREATEST(10, ROUND(NORMAL(350, 100, RANDOM())
        * (1.0
            + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (1, 5) THEN 0.25 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.35 ELSE 0 END
        )
    )::INT)                                            AS ORDERS_RECEIVED,
    GREATEST(10, ROUND(NORMAL(340, 100, RANDOM())
        * (1.0
            + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (2, 3, 4) THEN 0.10 ELSE 0 END
            + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.35 ELSE 0 END
        )
    )::INT)                                            AS ORDERS_SHIPPED,
    GREATEST(50, ROUND(NORMAL(2500, 800, RANDOM())
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.40 ELSE 0 END)
    )::INT)                                            AS UNITS_PICKED,
    -- Pick accuracy: mostly high (99.5%+)
    LEAST(1.0, GREATEST(0.96, ROUND(NORMAL(0.997, 0.003, RANDOM()), 4))) AS PICK_ACCURACY_PCT,
    -- Dock to stock hours: target < 4
    GREATEST(0.5, ROUND(NORMAL(3.2, 1.5, RANDOM()), 2)) AS DOCK_TO_STOCK_HOURS,
    -- Lines per labor hour
    GREATEST(5, ROUND(NORMAL(28, 8, RANDOM()), 2))    AS LINES_PER_LABOR_HR
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 20, RANDOM()) AS fac FROM TABLE(GENERATOR(ROWCOUNT => 3))) facilities
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 70;

-- ============================================================================
-- 8. FACT_DELIVERY_PERFORMANCE (daily per carrier × lane)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.FACT_DELIVERY_PERFORMANCE
    (DATE_KEY, CARRIER_KEY, LANE_KEY, SHIPMENTS, ON_TIME_PCT,
     AVG_TRANSIT_DAYS, AVG_DELAY_HOURS, EXCEPTIONS, DAMAGE_CLAIMS)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 50, RANDOM())                           AS CARRIER_KEY,
    UNIFORM(1, 200, RANDOM())                          AS LANE_KEY,
    UNIFORM(1, 20, RANDOM())                           AS SHIPMENTS,
    -- OTD varies by carrier quality and season
    LEAST(1.0, GREATEST(0.50, ROUND(NORMAL(0.88, 0.08, RANDOM())
        - CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.06 ELSE 0 END
    , 4)))                                             AS ON_TIME_PCT,
    GREATEST(0.5, ROUND(NORMAL(2.8, 1.2, RANDOM())
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.25 ELSE 0 END)
    , 2))                                              AS AVG_TRANSIT_DAYS,
    GREATEST(0, ROUND(NORMAL(3, 6, RANDOM()), 2))     AS AVG_DELAY_HOURS,
    GREATEST(0, ROUND(NORMAL(0.5, 0.8, RANDOM()))::INT) AS EXCEPTIONS,
    IFF(UNIFORM(0, 100, RANDOM()) < 3, UNIFORM(1, 3, RANDOM()), 0) AS DAMAGE_CLAIMS
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
WHERE d.IS_BUSINESS_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 15;

-- ============================================================================
-- 9. AGG_CARRIER_SCORECARD (monthly)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.AGG_CARRIER_SCORECARD
    (MONTH_KEY, CARRIER_KEY, SHIPMENTS, OTD_PCT, DAMAGE_PCT,
     INVOICE_ACCURACY_PCT, TENDER_ACCEPT_PCT, COMPOSITE_SCORE)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    car                                                AS CARRIER_KEY,
    UNIFORM(20, 500, RANDOM())                         AS SHIPMENTS,
    LEAST(1.0, GREATEST(0.60, ROUND(NORMAL(0.88, 0.06, RANDOM()), 4))) AS OTD_PCT,
    LEAST(0.10, GREATEST(0.0, ROUND(NORMAL(0.015, 0.008, RANDOM()), 4))) AS DAMAGE_PCT,
    LEAST(1.0, GREATEST(0.80, ROUND(NORMAL(0.96, 0.03, RANDOM()), 4))) AS INVOICE_ACCURACY_PCT,
    LEAST(1.0, GREATEST(0.50, ROUND(NORMAL(0.85, 0.08, RANDOM()), 4))) AS TENDER_ACCEPT_PCT,
    -- Composite: weighted average
    ROUND(
        LEAST(1.0, GREATEST(0.60, NORMAL(0.88, 0.06, RANDOM()))) * 40 +
        (1.0 - LEAST(0.10, GREATEST(0.0, NORMAL(0.015, 0.008, RANDOM())))) * 20 +
        LEAST(1.0, GREATEST(0.80, NORMAL(0.96, 0.03, RANDOM()))) * 20 +
        LEAST(1.0, GREATEST(0.50, NORMAL(0.85, 0.08, RANDOM()))) * 20
    , 2)                                               AS COMPOSITE_SCORE
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 50, RANDOM()) AS car FROM TABLE(GENERATOR(ROWCOUNT => 10))) carriers
WHERE DAY(d.FULL_DATE) = 1;

-- ============================================================================
-- 10. AGG_LANE_ECONOMICS (monthly)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.AGG_LANE_ECONOMICS
    (MONTH_KEY, LANE_KEY, SHIPMENTS, AVG_COST_PER_MILE, VOLUME_LBS,
     UTILIZATION_PCT, RATE_VS_BENCHMARK, CARRIER_DIVERSITY)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    ln                                                 AS LANE_KEY,
    UNIFORM(5, 200, RANDOM())                          AS SHIPMENTS,
    -- Cost per mile: inflation + fuel volatility
    ROUND(UNIFORM(150, 450, RANDOM()) / 100.0
        * (1.0 + 0.04 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60)
        * (1.0 + NORMAL(0, 0.05, RANDOM()))  -- fuel volatility
    , 4)                                               AS AVG_COST_PER_MILE,
    ROUND(EXP(NORMAL(11.5, 1.0, RANDOM())), 2)        AS VOLUME_LBS,
    LEAST(1.0, GREATEST(0.20, ROUND(NORMAL(0.72, 0.15, RANDOM()), 4))) AS UTILIZATION_PCT,
    -- Rate vs benchmark: some lanes above/below market
    ROUND(NORMAL(0.0, 0.08, RANDOM()), 4)             AS RATE_VS_BENCHMARK,
    UNIFORM(1, 8, RANDOM())                            AS CARRIER_DIVERSITY
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 200, RANDOM()) AS ln FROM TABLE(GENERATOR(ROWCOUNT => 5))) lanes
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 60;

-- ============================================================================
-- 11. AGG_FACILITY_KPI (monthly)
-- ============================================================================
INSERT INTO ATLAS_LOGISTICS.GOLD.AGG_FACILITY_KPI
    (MONTH_KEY, FACILITY_KEY, THROUGHPUT_UNITS, FILL_RATE_PCT,
     ORDER_CYCLE_HOURS, LABOR_PRODUCTIVITY, INVENTORY_TURNS, SPACE_UTILIZATION_PCT)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    fac                                                AS FACILITY_KEY,
    -- Throughput: seasonal with growth
    ROUND(EXP(NORMAL(10.5, 0.8, RANDOM()))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.40 ELSE 0 END
            + 0.08 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60
        )
    )::INT                                             AS THROUGHPUT_UNITS,
    LEAST(1.0, GREATEST(0.85, ROUND(NORMAL(0.965, 0.02, RANDOM()), 4))) AS FILL_RATE_PCT,
    GREATEST(1.0, ROUND(NORMAL(4.5, 1.5, RANDOM()), 2)) AS ORDER_CYCLE_HOURS,
    GREATEST(10, ROUND(NORMAL(32, 8, RANDOM()), 2))   AS LABOR_PRODUCTIVITY,
    ROUND(GREATEST(4, LEAST(20, NORMAL(9, 3, RANDOM()))), 2) AS INVENTORY_TURNS,
    LEAST(1.0, GREATEST(0.50, ROUND(NORMAL(0.78, 0.10, RANDOM())
        + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.10 ELSE 0 END
    , 4)))                                             AS SPACE_UTILIZATION_PCT
FROM ATLAS_LOGISTICS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 20, RANDOM()) AS fac FROM TABLE(GENERATOR(ROWCOUNT => 5))) facilities
WHERE DAY(d.FULL_DATE) = 1;
