-- ============================================================================
-- MANUFACTURING VERTICAL - Synthetic Data Generation
-- Entity: Apex Manufacturing Corp
-- Prerequisites: Run manufacturing-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- US calendar assumed (Thanksgiving, Christmas, July 4th shutdowns)
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE APEX_MFG.GOLD.AGG_SUPPLIER_SCORECARD;
TRUNCATE TABLE APEX_MFG.GOLD.AGG_OEE_DAILY;
TRUNCATE TABLE APEX_MFG.GOLD.FACT_SUPPLY_CHAIN;
TRUNCATE TABLE APEX_MFG.GOLD.FACT_SENSOR_DAILY;
TRUNCATE TABLE APEX_MFG.GOLD.FACT_QUALITY;
TRUNCATE TABLE APEX_MFG.GOLD.FACT_MAINTENANCE;
TRUNCATE TABLE APEX_MFG.GOLD.FACT_PRODUCTION;
TRUNCATE TABLE APEX_MFG.GOLD.DIM_DATE;
TRUNCATE TABLE APEX_MFG.GOLD.DIM_SUPPLIER;
TRUNCATE TABLE APEX_MFG.GOLD.DIM_MATERIAL;
TRUNCATE TABLE APEX_MFG.GOLD.DIM_EQUIPMENT;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span: 5 years ago to yesterday)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    YEAR(d)                                            AS FISCAL_YEAR,
    MONTH(d)                                           AS FISCAL_PERIOD,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN FALSE ELSE TRUE END AS IS_WORKING_DAY
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_EQUIPMENT (50 machines across 3 plants)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.DIM_EQUIPMENT
    (EQUIPMENT_KEY, EQUIPMENT_ID, EQUIPMENT_DESC, EQUIPMENT_CATEGORY, PLANT_CODE, PLANT_NAME,
     COST_CENTER, MANUFACTURER, MODEL_NUMBER, CRITICALITY_CLASS, STATUS, INSTALLATION_DATE, AGE_YEARS,
     _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    ROW_NUMBER() OVER (ORDER BY seq)                   AS EQUIPMENT_KEY,
    'EQ-' || LPAD(seq::VARCHAR, 5, '0')                AS EQUIPMENT_ID,
    GET(ARRAY_CONSTRUCT(
        'CNC Milling Center', 'Hydraulic Press 500T', 'Injection Molder A', 'Assembly Robot Arm',
        'Conveyor Line Main', 'Welding Station Auto', 'Paint Booth #1', 'Heat Treatment Furnace',
        'Grinding Machine CL', 'Packaging Line Auto', 'Laser Cutter HD', 'Stamping Press 200T',
        'Plasma Cutter XL', 'EDM Wire Machine', 'Surface Grinder PRO', 'Lathe CNC 5-Axis',
        'Boring Mill Vertical', 'Broaching Machine', 'Honing Machine', 'Deburring Station'
    ), MOD(seq - 1, 20))::VARCHAR || ' - Unit ' || CEIL(seq / 20)::VARCHAR AS EQUIPMENT_DESC,
    GET(ARRAY_CONSTRUCT('M', 'M', 'M', 'M', 'P'), MOD(seq - 1, 5))::VARCHAR AS EQUIPMENT_CATEGORY,
    GET(ARRAY_CONSTRUCT('P100', 'P200', 'P300'), MOD(seq - 1, 3))::VARCHAR AS PLANT_CODE,
    GET(ARRAY_CONSTRUCT('Detroit Main Plant', 'Toledo Assembly', 'Cleveland Precision'), MOD(seq - 1, 3))::VARCHAR AS PLANT_NAME,
    'CC-' || LPAD((MOD(seq - 1, 10) + 1)::VARCHAR, 4, '0') AS COST_CENTER,
    GET(ARRAY_CONSTRUCT('Fanuc', 'Siemens', 'ABB', 'KUKA', 'Mazak', 'DMG Mori', 'Haas', 'Trumpf'), MOD(seq - 1, 8))::VARCHAR AS MANUFACTURER,
    'MDL-' || UNIFORM(1000, 9999, RANDOM())::VARCHAR   AS MODEL_NUMBER,
    GET(ARRAY_CONSTRUCT('A', 'A', 'B', 'B', 'C'), MOD(seq - 1, 5))::VARCHAR AS CRITICALITY_CLASS,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, 'INACTIVE', 'ACTIVE') AS STATUS,
    DATEADD('day', -UNIFORM(365, 5000, RANDOM()), CURRENT_DATE()) AS INSTALLATION_DATE,
    ROUND(DATEDIFF('day', DATEADD('day', -UNIFORM(365, 5000, RANDOM()), CURRENT_DATE()), CURRENT_DATE()) / 365.25, 1) AS AGE_YEARS,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- ============================================================================
-- 3. DIM_MATERIAL (100 materials)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.DIM_MATERIAL
    (MATERIAL_KEY, MATERIAL_NUMBER, MATERIAL_DESC, MATERIAL_TYPE, MATERIAL_GROUP,
     MATERIAL_GROUP_DESC, SUPPLIER_ID, SUPPLIER_NAME, LEAD_TIME_DAYS, _IS_CURRENT)
SELECT
    ROW_NUMBER() OVER (ORDER BY seq)                   AS MATERIAL_KEY,
    'MAT-' || LPAD(seq::VARCHAR, 6, '0')               AS MATERIAL_NUMBER,
    GET(ARRAY_CONSTRUCT(
        'Steel Plate 10mm', 'Aluminum Bar 25mm', 'Copper Wire 2.5mm', 'Titanium Rod 12mm',
        'Stainless Sheet 3mm', 'Brass Fitting M8', 'Carbon Fiber Sheet', 'Nylon Bushing Kit',
        'Bearing SKF 6205', 'Hydraulic Seal Set', 'Motor 5HP 3Phase', 'PLC Module IO-16',
        'Coolant Fluid 20L', 'Abrasive Disc 150mm', 'Weld Wire ER70S-6', 'Lubricant Grade 46',
        'Filter Element HYD', 'Belt Drive V-Type', 'Gasket Set NBR', 'Fastener Kit M10x50'
    ), MOD(seq - 1, 20))::VARCHAR || ' #' || CEIL(seq / 20)::VARCHAR AS MATERIAL_DESC,
    GET(ARRAY_CONSTRUCT('ROH', 'ROH', 'ROH', 'HALB', 'HALB', 'ERSA', 'ERSA', 'HIBE', 'HIBE', 'FERT'), MOD(seq - 1, 10))::VARCHAR AS MATERIAL_TYPE,
    GET(ARRAY_CONSTRUCT('RAW_METAL', 'RAW_METAL', 'COMPONENTS', 'COMPONENTS', 'CONSUMABLES', 'ELECTRICAL', 'PACKAGING', 'FLUIDS'), MOD(seq - 1, 8))::VARCHAR AS MATERIAL_GROUP,
    GET(ARRAY_CONSTRUCT('Raw Metals', 'Raw Metals', 'Mechanical Components', 'Mechanical Components', 'Consumables', 'Electrical Parts', 'Packaging Materials', 'Fluids & Lubricants'), MOD(seq - 1, 8))::VARCHAR AS MATERIAL_GROUP_DESC,
    'SUP-' || LPAD((MOD(seq - 1, 20) + 1)::VARCHAR, 4, '0') AS SUPPLIER_ID,
    GET(ARRAY_CONSTRUCT(
        'US Steel Corp', 'Alcoa Materials', 'Fastenal Co', 'Grainger Industrial', 'MSC Industrial',
        'Parker Hannifin', 'SKF Bearings Inc', 'Siemens Elec Supply', 'Shell Lubricants', 'Lincoln Electric',
        'McMaster-Carr', '3M Industrial', 'Timken Bearings', 'Bosch Rexroth', 'Eaton Hydraulics',
        'Sandvik Coromant', 'Kennametal Inc', 'Mitsubishi Materials', 'Walter Tools', 'Seco Tools'
    ), MOD(seq - 1, 20))::VARCHAR AS SUPPLIER_NAME,
    UNIFORM(3, 45, RANDOM())                           AS LEAD_TIME_DAYS,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- ============================================================================
-- 4. DIM_SUPPLIER (20 suppliers)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.DIM_SUPPLIER
    (SUPPLIER_KEY, SUPPLIER_ID, SUPPLIER_NAME, COUNTRY, REGION, SUPPLIER_TIER, CERTIFICATION_STATUS, _IS_CURRENT)
SELECT
    ROW_NUMBER() OVER (ORDER BY seq)                   AS SUPPLIER_KEY,
    'SUP-' || LPAD(seq::VARCHAR, 4, '0')               AS SUPPLIER_ID,
    GET(ARRAY_CONSTRUCT(
        'US Steel Corp', 'Alcoa Materials', 'Fastenal Co', 'Grainger Industrial', 'MSC Industrial',
        'Parker Hannifin', 'SKF Bearings Inc', 'Siemens Elec Supply', 'Shell Lubricants', 'Lincoln Electric',
        'McMaster-Carr', '3M Industrial', 'Timken Bearings', 'Bosch Rexroth', 'Eaton Hydraulics',
        'Sandvik Coromant', 'Kennametal Inc', 'Mitsubishi Materials', 'Walter Tools', 'Seco Tools'
    ), seq - 1)::VARCHAR AS SUPPLIER_NAME,
    GET(ARRAY_CONSTRUCT('US', 'US', 'US', 'US', 'US', 'US', 'Sweden', 'Germany', 'Netherlands', 'US',
                         'US', 'US', 'US', 'Germany', 'Ireland', 'Sweden', 'US', 'Japan', 'Germany', 'Sweden'),
        seq - 1)::VARCHAR AS COUNTRY,
    GET(ARRAY_CONSTRUCT('Americas', 'Americas', 'Americas', 'Americas', 'Americas', 'Americas', 'EMEA', 'EMEA', 'EMEA', 'Americas',
                         'Americas', 'Americas', 'Americas', 'EMEA', 'EMEA', 'EMEA', 'Americas', 'APAC', 'EMEA', 'EMEA'),
        seq - 1)::VARCHAR AS REGION,
    GET(ARRAY_CONSTRUCT('TIER_1', 'TIER_1', 'TIER_2', 'TIER_2', 'TIER_2', 'TIER_1', 'TIER_1', 'TIER_1', 'TIER_1', 'TIER_2',
                         'TIER_2', 'TIER_1', 'TIER_1', 'TIER_1', 'TIER_1', 'TIER_1', 'TIER_2', 'TIER_1', 'TIER_2', 'TIER_2'),
        seq - 1)::VARCHAR AS SUPPLIER_TIER,
    IFF(UNIFORM(0, 100, RANDOM()) < 80, 'CERTIFIED', 'PENDING') AS CERTIFICATION_STATUS,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 20)));

-- ============================================================================
-- 5. FACT_PRODUCTION (~25,000 rows: ~50 machines x ~250 working days x 5 years / sampling)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.FACT_PRODUCTION
    (ORDER_NUMBER, EQUIPMENT_KEY, MATERIAL_KEY, DATE_KEY, SHIFT_CODE,
     PLANNED_QTY, PRODUCED_QTY, SCRAP_QTY, REWORK_QTY,
     RUNTIME_MINUTES, DOWNTIME_MINUTES, CHANGEOVER_MINUTES,
     CYCLE_TIME_ACTUAL, CYCLE_TIME_IDEAL, FIRST_PASS_YIELD,
     OEE_AVAILABILITY, OEE_PERFORMANCE, OEE_QUALITY, OEE_OVERALL)
SELECT
    'PO-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY, eq_key)::VARCHAR, 8, '0') AS ORDER_NUMBER,
    eq_key                                             AS EQUIPMENT_KEY,
    UNIFORM(1, 100, RANDOM())                          AS MATERIAL_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    GET(ARRAY_CONSTRUCT('A', 'B', 'C'), MOD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY, eq_key) - 1, 3))::VARCHAR AS SHIFT_CODE,
    -- Planned qty with seasonal adjustment (Q4 push +20%, summer maintenance dip -15%)
    GREATEST(50, ROUND(NORMAL(200, 30, RANDOM())
        * (1.0 + 0.2 * CASE WHEN MONTH(d.FULL_DATE) IN (10,11,12) THEN 1 WHEN MONTH(d.FULL_DATE) IN (7,8) THEN -0.75 ELSE 0 END)
        * (1.0 + 0.03 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12) -- YoY growth 3%
    ))                                                 AS PLANNED_QTY,
    -- Produced qty: ~92-97% of planned
    GREATEST(40, ROUND(NORMAL(200, 30, RANDOM())
        * (1.0 + 0.2 * CASE WHEN MONTH(d.FULL_DATE) IN (10,11,12) THEN 1 WHEN MONTH(d.FULL_DATE) IN (7,8) THEN -0.75 ELSE 0 END)
        * UNIFORM(920, 970, RANDOM()) / 1000.0
        * (1.0 + 0.03 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12)
    ))                                                 AS PRODUCED_QTY,
    -- Scrap: 1-5% with occasional spikes
    ROUND(NORMAL(200, 30, RANDOM()) * IFF(UNIFORM(0, 1000, RANDOM()) < 5, UNIFORM(8, 15, RANDOM()) / 100.0, UNIFORM(1, 5, RANDOM()) / 100.0)) AS SCRAP_QTY,
    -- Rework: 0-3%
    ROUND(NORMAL(200, 30, RANDOM()) * UNIFORM(0, 3, RANDOM()) / 100.0) AS REWORK_QTY,
    -- Runtime: 400-480 min per shift (8 hours)
    UNIFORM(380, 480, RANDOM())                        AS RUNTIME_MINUTES,
    -- Downtime: higher in summer (maintenance), occasional breakdowns
    GREATEST(0, ROUND(NORMAL(25, 15, RANDOM())
        * IFF(MONTH(d.FULL_DATE) IN (7,8), 1.8, 1.0)
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 4.0, 1.0) -- 3% chance of major breakdown
    ))                                                 AS DOWNTIME_MINUTES,
    UNIFORM(10, 45, RANDOM())                          AS CHANGEOVER_MINUTES,
    ROUND(NORMAL(2.5, 0.3, RANDOM()), 2)              AS CYCLE_TIME_ACTUAL,
    2.0                                                AS CYCLE_TIME_IDEAL,
    -- First pass yield: mostly 0.94-0.99, occasional drops
    LEAST(0.995, GREATEST(0.80, ROUND(NORMAL(0.965, 0.015, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 0.9, 1.0), 4))) AS FIRST_PASS_YIELD,
    -- OEE components
    LEAST(0.99, GREATEST(0.65, ROUND(NORMAL(0.90, 0.04, RANDOM()), 4))) AS OEE_AVAILABILITY,
    LEAST(0.99, GREATEST(0.70, ROUND(NORMAL(0.88, 0.05, RANDOM()), 4))) AS OEE_PERFORMANCE,
    LEAST(0.999, GREATEST(0.85, ROUND(NORMAL(0.965, 0.015, RANDOM()), 4))) AS OEE_QUALITY,
    -- OEE overall (will be close to product of above but computed independently for realism)
    LEAST(0.95, GREATEST(0.45, ROUND(NORMAL(0.76, 0.08, RANDOM()), 4))) AS OEE_OVERALL
FROM APEX_MFG.GOLD.DIM_DATE d
CROSS JOIN (SELECT EQUIPMENT_KEY AS eq_key FROM APEX_MFG.GOLD.DIM_EQUIPMENT WHERE _IS_CURRENT = TRUE ORDER BY EQUIPMENT_KEY LIMIT 20) e
WHERE d.IS_WORKING_DAY = TRUE
  -- Sample ~60% of days to keep volume manageable
  AND UNIFORM(0, 100, RANDOM()) < 60;

-- ============================================================================
-- 6. FACT_MAINTENANCE (~5,000 rows over 5 years)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.FACT_MAINTENANCE
    (ORDER_NUMBER, EQUIPMENT_KEY, DATE_KEY, ORDER_TYPE, IS_BREAKDOWN,
     FAILURE_CODE, FAILURE_CATEGORY, TIME_TO_REPAIR_HRS, TIME_BETWEEN_FAIL,
     PLANNED_COST, ACTUAL_COST, SPARE_PARTS_COST, LABOR_COST)
SELECT
    'MO-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY, eq_key)::VARCHAR, 7, '0') AS ORDER_NUMBER,
    eq_key                                             AS EQUIPMENT_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    -- Mix: 30% corrective, 50% preventive, 20% condition-based
    GET(ARRAY_CONSTRUCT('PM01', 'PM01', 'PM01', 'PM02', 'PM02', 'PM02', 'PM02', 'PM02', 'PM03', 'PM03'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ORDER_TYPE,
    IFF(UNIFORM(0, 10, RANDOM()) < 3, TRUE, FALSE)    AS IS_BREAKDOWN,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GET(ARRAY_CONSTRUCT('MECH_WEAR', 'ELEC_FAIL', 'HYD_LEAK', 'BEAR_FAIL', 'MOTOR_OVHT',
                            'SENSOR_ERR', 'CNTRL_FAULT', 'STRUCT_CRACK', 'LUBRICATION', 'ALIGNMENT'),
            UNIFORM(0, 9, RANDOM()))::VARCHAR)         AS FAILURE_CODE,
    GET(ARRAY_CONSTRUCT('Mechanical', 'Electrical', 'Hydraulic', 'Mechanical', 'Electrical',
                        'Instrumentation', 'Controls', 'Structural', 'Lubrication', 'Alignment'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS FAILURE_CATEGORY,
    -- TTR: mostly 1-8 hrs, breakdowns take longer
    GREATEST(0.5, ROUND(NORMAL(4.0, 2.5, RANDOM())
        * IFF(UNIFORM(0, 10, RANDOM()) < 3, 2.0, 1.0), 2)) AS TIME_TO_REPAIR_HRS,
    -- Time between failures: 100-2000 hrs
    ROUND(GREATEST(50, NORMAL(500, 200, RANDOM())), 2) AS TIME_BETWEEN_FAIL,
    ROUND(GREATEST(200, NORMAL(2500, 1000, RANDOM())), 2) AS PLANNED_COST,
    -- Actual cost: usually near planned, sometimes way over (breakdowns)
    ROUND(GREATEST(200, NORMAL(2500, 1000, RANDOM())
        * IFF(UNIFORM(0, 10, RANDOM()) < 3, UNIFORM(150, 300, RANDOM()) / 100.0, UNIFORM(80, 120, RANDOM()) / 100.0)), 2) AS ACTUAL_COST,
    ROUND(GREATEST(50, NORMAL(800, 400, RANDOM())), 2) AS SPARE_PARTS_COST,
    ROUND(GREATEST(100, NORMAL(600, 200, RANDOM())), 2) AS LABOR_COST
FROM APEX_MFG.GOLD.DIM_DATE d
CROSS JOIN (SELECT EQUIPMENT_KEY AS eq_key FROM APEX_MFG.GOLD.DIM_EQUIPMENT WHERE _IS_CURRENT = TRUE) e
WHERE d.IS_WORKING_DAY = TRUE
  -- ~2 maintenance events per equipment per month
  AND UNIFORM(0, 100, RANDOM()) < 10
  -- Higher maintenance in summer shutdown period
  AND (UNIFORM(0, 100, RANDOM()) < IFF(MONTH(d.FULL_DATE) IN (7, 8), 70, 50));

-- ============================================================================
-- 7. FACT_QUALITY (~8,000 rows over 5 years)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.FACT_QUALITY
    (INSPECTION_LOT, EQUIPMENT_KEY, MATERIAL_KEY, DATE_KEY, BATCH_NUMBER,
     LOT_SIZE, SAMPLE_SIZE, DEFECT_COUNT, DEFECT_CLASS, RESULT_CODE,
     YIELD_RATE, SIGMA_LEVEL, CPK_VALUE)
SELECT
    'IL-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY)::VARCHAR, 8, '0') AS INSPECTION_LOT,
    UNIFORM(1, 50, RANDOM())                           AS EQUIPMENT_KEY,
    UNIFORM(1, 100, RANDOM())                          AS MATERIAL_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    'B' || TO_CHAR(d.FULL_DATE, 'YYYYMMDD') || '-' || LPAD(UNIFORM(1, 20, RANDOM())::VARCHAR, 2, '0') AS BATCH_NUMBER,
    UNIFORM(100, 5000, RANDOM())                       AS LOT_SIZE,
    UNIFORM(10, 200, RANDOM())                         AS SAMPLE_SIZE,
    -- Defects: mostly 0-3, occasional quality excursion
    GREATEST(0, ROUND(NORMAL(1.5, 1.2, RANDOM())
        * IFF(UNIFORM(0, 1000, RANDOM()) < 5, 5.0, 1.0))) AS DEFECT_COUNT, -- 0.5% chance of excursion
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GET(ARRAY_CONSTRUCT('MI', 'MI', 'MI', 'MI', 'MA', 'MA', 'CR'), UNIFORM(0, 6, RANDOM()))::VARCHAR) AS DEFECT_CLASS,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, 'R', 'A')      AS RESULT_CODE, -- 5% rejection rate
    LEAST(0.999, GREATEST(0.85, ROUND(NORMAL(0.975, 0.012, RANDOM()), 4))) AS YIELD_RATE,
    GREATEST(2.0, LEAST(6.5, ROUND(NORMAL(4.2, 0.7, RANDOM()), 2))) AS SIGMA_LEVEL,
    GREATEST(0.8, LEAST(3.0, ROUND(NORMAL(1.5, 0.3, RANDOM()), 3))) AS CPK_VALUE
FROM APEX_MFG.GOLD.DIM_DATE d
WHERE d.IS_WORKING_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 30; -- ~30% of working days have inspections per batch

-- ============================================================================
-- 8. FACT_SENSOR_DAILY (~180,000 rows: 50 equip x 5 sensor types x ~1800 days * sampling)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.FACT_SENSOR_DAILY
    (EQUIPMENT_KEY, SENSOR_TYPE, DATE_KEY, READING_COUNT, VALUE_MIN, VALUE_MAX,
     VALUE_AVG, VALUE_STDDEV, VALUE_P95, ANOMALY_COUNT, OUT_OF_SPEC_COUNT)
SELECT
    eq_key                                             AS EQUIPMENT_KEY,
    s.SENSOR_TYPE                                      AS SENSOR_TYPE,
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1000, 86400, RANDOM())                     AS READING_COUNT,
    -- Values depend on sensor type
    CASE s.SENSOR_TYPE
        WHEN 'VIBRATION' THEN ROUND(GREATEST(0.1, NORMAL(2.5, 0.8, RANDOM())), 2)
        WHEN 'TEMPERATURE' THEN ROUND(NORMAL(65, 8, RANDOM()), 2)
        WHEN 'PRESSURE' THEN ROUND(NORMAL(150, 20, RANDOM()), 2)
        WHEN 'CURRENT' THEN ROUND(GREATEST(0, NORMAL(25, 5, RANDOM())), 2)
        ELSE ROUND(NORMAL(50, 10, RANDOM()), 2)
    END                                                AS VALUE_MIN,
    CASE s.SENSOR_TYPE
        WHEN 'VIBRATION' THEN ROUND(GREATEST(1, NORMAL(8.0, 2.5, RANDOM()) * IFF(UNIFORM(0,100,RANDOM())<1, 3.0, 1.0)), 2)
        WHEN 'TEMPERATURE' THEN ROUND(NORMAL(85, 10, RANDOM()) * IFF(UNIFORM(0,100,RANDOM())<1, 1.3, 1.0), 2)
        WHEN 'PRESSURE' THEN ROUND(NORMAL(180, 15, RANDOM()) * IFF(UNIFORM(0,100,RANDOM())<1, 1.4, 1.0), 2)
        WHEN 'CURRENT' THEN ROUND(NORMAL(45, 8, RANDOM()) * IFF(UNIFORM(0,100,RANDOM())<1, 1.5, 1.0), 2)
        ELSE ROUND(NORMAL(80, 15, RANDOM()), 2)
    END                                                AS VALUE_MAX,
    CASE s.SENSOR_TYPE
        WHEN 'VIBRATION' THEN ROUND(NORMAL(4.5, 1.0, RANDOM()), 2)
        WHEN 'TEMPERATURE' THEN ROUND(NORMAL(72, 5, RANDOM()), 2)
        WHEN 'PRESSURE' THEN ROUND(NORMAL(160, 10, RANDOM()), 2)
        WHEN 'CURRENT' THEN ROUND(NORMAL(32, 4, RANDOM()), 2)
        ELSE ROUND(NORMAL(60, 8, RANDOM()), 2)
    END                                                AS VALUE_AVG,
    CASE s.SENSOR_TYPE
        WHEN 'VIBRATION' THEN ROUND(NORMAL(1.2, 0.3, RANDOM()), 2)
        WHEN 'TEMPERATURE' THEN ROUND(NORMAL(3.5, 0.8, RANDOM()), 2)
        WHEN 'PRESSURE' THEN ROUND(NORMAL(8, 2, RANDOM()), 2)
        WHEN 'CURRENT' THEN ROUND(NORMAL(4, 1, RANDOM()), 2)
        ELSE ROUND(NORMAL(5, 1.5, RANDOM()), 2)
    END                                                AS VALUE_STDDEV,
    CASE s.SENSOR_TYPE
        WHEN 'VIBRATION' THEN ROUND(NORMAL(6.5, 1.5, RANDOM()), 2)
        WHEN 'TEMPERATURE' THEN ROUND(NORMAL(80, 6, RANDOM()), 2)
        WHEN 'PRESSURE' THEN ROUND(NORMAL(175, 12, RANDOM()), 2)
        WHEN 'CURRENT' THEN ROUND(NORMAL(40, 5, RANDOM()), 2)
        ELSE ROUND(NORMAL(72, 10, RANDOM()), 2)
    END                                                AS VALUE_P95,
    -- Anomalies: 0-2 per day normally, spike on bad days
    GREATEST(0, ROUND(NORMAL(0.5, 0.8, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 8.0, 1.0)))::INT AS ANOMALY_COUNT,
    GREATEST(0, ROUND(NORMAL(0.3, 0.5, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 1, 10.0, 1.0)))::INT AS OUT_OF_SPEC_COUNT
FROM APEX_MFG.GOLD.DIM_DATE d
CROSS JOIN (SELECT EQUIPMENT_KEY AS eq_key FROM APEX_MFG.GOLD.DIM_EQUIPMENT WHERE _IS_CURRENT = TRUE LIMIT 30) e
CROSS JOIN (SELECT column1 AS SENSOR_TYPE FROM VALUES ('VIBRATION'), ('TEMPERATURE'), ('PRESSURE'), ('CURRENT'), ('FLOW')) s
WHERE d.IS_WORKING_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 80; -- 80% coverage (some days equipment offline)

-- ============================================================================
-- 9. FACT_SUPPLY_CHAIN (~12,000 rows)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.FACT_SUPPLY_CHAIN
    (SUPPLIER_KEY, MATERIAL_KEY, DATE_KEY, QUANTITY_ORDERED, QUANTITY_RECEIVED,
     ON_TIME_FLAG, DAYS_EARLY_LATE, UNIT_COST, TOTAL_COST, QUALITY_PASS_FLAG)
SELECT
    UNIFORM(1, 20, RANDOM())                           AS SUPPLIER_KEY,
    UNIFORM(1, 100, RANDOM())                          AS MATERIAL_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    ROUND(GREATEST(10, NORMAL(500, 200, RANDOM())))    AS QUANTITY_ORDERED,
    -- Received: usually matches ordered, sometimes short
    ROUND(GREATEST(10, NORMAL(500, 200, RANDOM()) * IFF(UNIFORM(0,100,RANDOM()) < 10, UNIFORM(80,95,RANDOM())/100.0, 1.0))) AS QUANTITY_RECEIVED,
    IFF(UNIFORM(0, 100, RANDOM()) < 82, TRUE, FALSE)  AS ON_TIME_FLAG, -- 82% OTD
    -- Days early/late: positive = late
    ROUND(NORMAL(0, 3, RANDOM()))                      AS DAYS_EARLY_LATE,
    -- Unit cost with slight inflation over time
    ROUND(GREATEST(0.50, NORMAL(25, 15, RANDOM())
        * (1.0 + 0.02 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12)), 4) AS UNIT_COST,
    ROUND(GREATEST(50, NORMAL(12000, 8000, RANDOM())), 2) AS TOTAL_COST,
    IFF(UNIFORM(0, 100, RANDOM()) < 95, TRUE, FALSE)  AS QUALITY_PASS_FLAG -- 95% pass incoming inspection
FROM APEX_MFG.GOLD.DIM_DATE d
WHERE d.IS_WORKING_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 20; -- ~20% of working days have PO receipts

-- ============================================================================
-- 10. AGG_OEE_DAILY (computed summary)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.AGG_OEE_DAILY
    (EQUIPMENT_KEY, DATE_KEY, PLANNED_PRODUCTION_TIME_MIN, ACTUAL_RUN_TIME_MIN,
     TOTAL_UNITS, GOOD_UNITS, IDEAL_CYCLE_TIME,
     AVAILABILITY, PERFORMANCE, QUALITY_RATE, OEE,
     DOWNTIME_LOSSES_MIN, SPEED_LOSSES_MIN, QUALITY_LOSSES_UNITS, TOP_LOSS_CATEGORY)
SELECT
    EQUIPMENT_KEY,
    DATE_KEY,
    480                                                AS PLANNED_PRODUCTION_TIME_MIN,
    RUNTIME_MINUTES                                    AS ACTUAL_RUN_TIME_MIN,
    PRODUCED_QTY::INT + SCRAP_QTY::INT                 AS TOTAL_UNITS,
    PRODUCED_QTY::INT                                  AS GOOD_UNITS,
    CYCLE_TIME_IDEAL                                   AS IDEAL_CYCLE_TIME,
    OEE_AVAILABILITY                                   AS AVAILABILITY,
    OEE_PERFORMANCE                                    AS PERFORMANCE,
    OEE_QUALITY                                        AS QUALITY_RATE,
    OEE_OVERALL                                        AS OEE,
    DOWNTIME_MINUTES                                   AS DOWNTIME_LOSSES_MIN,
    GREATEST(0, 480 - RUNTIME_MINUTES - DOWNTIME_MINUTES - CHANGEOVER_MINUTES) AS SPEED_LOSSES_MIN,
    SCRAP_QTY::INT + REWORK_QTY::INT                   AS QUALITY_LOSSES_UNITS,
    GET(ARRAY_CONSTRUCT('Unplanned Stops', 'Setup/Changeover', 'Speed Loss', 'Defects/Rework', 'Planned Downtime'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS TOP_LOSS_CATEGORY
FROM APEX_MFG.GOLD.FACT_PRODUCTION;

-- ============================================================================
-- 11. AGG_SUPPLIER_SCORECARD (monthly rollup)
-- ============================================================================
INSERT INTO APEX_MFG.GOLD.AGG_SUPPLIER_SCORECARD
    (SUPPLIER_KEY, MONTH_KEY, TOTAL_PO_LINES, ON_TIME_DELIVERY_PCT,
     QUALITY_ACCEPT_PCT, AVG_LEAD_TIME_DAYS, COST_VARIANCE_PCT, COMPOSITE_SCORE)
SELECT
    SUPPLIER_KEY,
    TO_NUMBER(TO_CHAR(d.FULL_DATE, 'YYYYMM') || '01') AS MONTH_KEY,
    COUNT(*)                                           AS TOTAL_PO_LINES,
    ROUND(AVG(IFF(ON_TIME_FLAG, 1.0, 0.0)), 4)        AS ON_TIME_DELIVERY_PCT,
    ROUND(AVG(IFF(QUALITY_PASS_FLAG, 1.0, 0.0)), 4)   AS QUALITY_ACCEPT_PCT,
    ROUND(AVG(ABS(DAYS_EARLY_LATE)), 1)                AS AVG_LEAD_TIME_DAYS,
    ROUND(NORMAL(0.02, 0.03, RANDOM()), 4)             AS COST_VARIANCE_PCT,
    ROUND(
        AVG(IFF(ON_TIME_FLAG, 1.0, 0.0)) * 0.4
        + AVG(IFF(QUALITY_PASS_FLAG, 1.0, 0.0)) * 0.4
        + (1.0 - LEAST(1.0, AVG(ABS(DAYS_EARLY_LATE)) / 10.0)) * 0.2
    , 2)                                               AS COMPOSITE_SCORE
FROM APEX_MFG.GOLD.FACT_SUPPLY_CHAIN sc
JOIN APEX_MFG.GOLD.DIM_DATE d ON sc.DATE_KEY = d.DATE_KEY
GROUP BY SUPPLIER_KEY, TO_CHAR(d.FULL_DATE, 'YYYYMM');
