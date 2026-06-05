-- ============================================================================
-- PUBLIC SECTOR VERTICAL - Synthetic Data Generation
-- Entity: Civic Municipal Services
-- Prerequisites: Run public-sector-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- Fiscal Year: Jul-Jun (FY offset), Q4 rush spending (use-it-or-lose-it)
-- Seasonality: Potholes spring, snow winter, mosquitos summer, construction
--              spring/summer, crime summer peak, DUI holidays
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE CIVIC_GOV.GOLD.AGG_DEPARTMENT_KPI;
TRUNCATE TABLE CIVIC_GOV.GOLD.AGG_WARD_SCORECARD;
TRUNCATE TABLE CIVIC_GOV.GOLD.FACT_CODE_COMPLIANCE;
TRUNCATE TABLE CIVIC_GOV.GOLD.FACT_BUDGET_EXECUTION;
TRUNCATE TABLE CIVIC_GOV.GOLD.FACT_PERMIT_ACTIVITY;
TRUNCATE TABLE CIVIC_GOV.GOLD.FACT_PUBLIC_SAFETY;
TRUNCATE TABLE CIVIC_GOV.GOLD.FACT_SERVICE_REQUEST;
TRUNCATE TABLE CIVIC_GOV.GOLD.DIM_DATE;
TRUNCATE TABLE CIVIC_GOV.GOLD.DIM_OFFENSE;
TRUNCATE TABLE CIVIC_GOV.GOLD.DIM_LOCATION;
TRUNCATE TABLE CIVIC_GOV.GOLD.DIM_DEPARTMENT;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span with fiscal year Jul-Jun)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN TRUE ELSE FALSE END AS IS_WEEKEND,
    -- Fiscal year: Jul-Jun (Jul 2024 = FY2025)
    CASE WHEN MONTH(d) >= 7 THEN YEAR(d) + 1 ELSE YEAR(d) END AS FISCAL_YEAR,
    CASE WHEN MONTH(d) >= 7 THEN MONTH(d) - 6 ELSE MONTH(d) + 6 END AS FISCAL_PERIOD,
    -- Major US holidays
    CASE WHEN (MONTH(d) = 1 AND DAY(d) = 1)   -- New Year
          OR (MONTH(d) = 7 AND DAY(d) = 4)    -- Independence Day
          OR (MONTH(d) = 12 AND DAY(d) = 25)  -- Christmas
          OR (MONTH(d) = 11 AND DAY(d) BETWEEN 22 AND 28 AND DAYOFWEEK(d) = 4) -- Thanksgiving
         THEN TRUE ELSE FALSE END AS IS_HOLIDAY
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_DEPARTMENT (15 departments)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.DIM_DEPARTMENT
    (DEPT_KEY, DEPT_CODE, DEPT_NAME, DIVISION, FUND, DIRECTOR_NAME, EMPLOYEE_COUNT)
SELECT
    ROW_NUMBER() OVER (ORDER BY d.column1) AS DEPT_KEY,
    d.column1                              AS DEPT_CODE,
    d.column2                              AS DEPT_NAME,
    d.column3                              AS DIVISION,
    d.column4                              AS FUND,
    d.column5                              AS DIRECTOR_NAME,
    d.column6                              AS EMPLOYEE_COUNT
FROM VALUES
    ('PW', 'Public Works', 'Infrastructure', 'GENERAL', 'Robert Martinez', 320),
    ('PD', 'Police Department', 'Public Safety', 'GENERAL', 'Sarah Thompson', 580),
    ('FD', 'Fire Department', 'Public Safety', 'GENERAL', 'James Wilson', 420),
    ('PK', 'Parks & Recreation', 'Community Services', 'GENERAL', 'Lisa Chen', 180),
    ('CD', 'Community Development', 'Development', 'GENERAL', 'Mark Johnson', 95),
    ('UT', 'Utilities', 'Infrastructure', 'ENTERPRISE', 'Karen Davis', 210),
    ('TR', 'Transportation', 'Infrastructure', 'GENERAL', 'David Kim', 150),
    ('IT', 'Information Technology', 'Administration', 'GENERAL', 'Michelle Patel', 65),
    ('FN', 'Finance', 'Administration', 'GENERAL', 'Thomas Brown', 45),
    ('HR', 'Human Resources', 'Administration', 'GENERAL', 'Amanda Garcia', 30),
    ('LB', 'Library', 'Community Services', 'GENERAL', 'Patricia White', 85),
    ('HS', 'Health Services', 'Community Services', 'SPECIAL_REVENUE', 'Richard Lee', 120),
    ('PL', 'Planning & Zoning', 'Development', 'GENERAL', 'Jennifer Clark', 40),
    ('CE', 'Code Enforcement', 'Development', 'GENERAL', 'Steven Moore', 35),
    ('CM', 'City Manager', 'Administration', 'GENERAL', 'Angela Williams', 20)
AS d (column1, column2, column3, column4, column5, column6);

-- ============================================================================
-- 3. DIM_LOCATION (10,000 parcels/addresses)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.DIM_LOCATION
    (LOCATION_KEY, ADDRESS, WARD, DISTRICT, BEAT, PARCEL_ID,
     LATITUDE, LONGITUDE, CENSUS_TRACT, LAND_USE_CODE, ZONING)
SELECT
    seq                                                AS LOCATION_KEY,
    UNIFORM(100, 9999, RANDOM())::VARCHAR || ' ' ||
        GET(ARRAY_CONSTRUCT('Main St', 'Oak Ave', 'Elm St', 'First Ave', 'Washington Blvd',
            'Park Dr', 'Cedar Ln', 'Maple St', 'Pine Rd', 'Lincoln Ave',
            'Jefferson St', 'State St', 'Church Rd', 'Highland Ave', 'Center St'),
            UNIFORM(0, 14, RANDOM()))::VARCHAR         AS ADDRESS,
    LPAD(UNIFORM(1, 12, RANDOM())::VARCHAR, 2, '0')   AS WARD,
    'D-' || LPAD(UNIFORM(1, 6, RANDOM())::VARCHAR, 2, '0') AS DISTRICT,
    'B-' || LPAD(UNIFORM(1, 24, RANDOM())::VARCHAR, 3, '0') AS BEAT,
    'P-' || LPAD(seq::VARCHAR, 6, '0')                 AS PARCEL_ID,
    ROUND(39.75 + NORMAL(0, 0.03, RANDOM()), 6)       AS LATITUDE,
    ROUND(-86.15 + NORMAL(0, 0.04, RANDOM()), 6)      AS LONGITUDE,
    LPAD(UNIFORM(1, 80, RANDOM())::VARCHAR, 6, '0') || '.' || LPAD(UNIFORM(1, 4, RANDOM())::VARCHAR, 2, '0') AS CENSUS_TRACT,
    GET(ARRAY_CONSTRUCT('R1', 'R1', 'R1', 'R2', 'R2', 'C1', 'C2', 'I1', 'PU', 'VA'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS LAND_USE_CODE,
    GET(ARRAY_CONSTRUCT('R-1', 'R-2', 'R-3', 'R-4', 'C-1', 'C-2', 'C-3', 'I-1', 'I-2', 'PD'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ZONING
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 10000)));

-- ============================================================================
-- 4. DIM_OFFENSE (100 offense codes)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.DIM_OFFENSE
    (OFFENSE_KEY, OFFENSE_CODE, OFFENSE_DESC, CATEGORY, SEVERITY, NIBRS_GROUP)
SELECT
    seq                                                AS OFFENSE_KEY,
    LPAD(seq::VARCHAR, 4, '0')                         AS OFFENSE_CODE,
    GET(ARRAY_CONSTRUCT('Simple Assault', 'Aggravated Assault', 'Robbery', 'Burglary - Residential',
        'Burglary - Commercial', 'Motor Vehicle Theft', 'Larceny - Shoplifting', 'Larceny - From Vehicle',
        'Vandalism', 'Drug Possession', 'Drug Distribution', 'DUI', 'Domestic Violence',
        'Fraud - Identity Theft', 'Fraud - Credit Card', 'Trespass', 'Disorderly Conduct',
        'Weapons Violation', 'Homicide', 'Sexual Assault', 'Arson', 'Traffic Violation',
        'Noise Complaint', 'Public Intoxication', 'Warrant Service'),
        MOD(seq - 1, 25))::VARCHAR || IFF(seq > 25, ' (' || seq::VARCHAR || ')', '') AS OFFENSE_DESC,
    GET(ARRAY_CONSTRUCT('VIOLENT', 'VIOLENT', 'VIOLENT', 'PROPERTY', 'PROPERTY',
        'PROPERTY', 'PROPERTY', 'PROPERTY', 'PROPERTY', 'DRUG',
        'DRUG', 'TRAFFIC', 'VIOLENT', 'PROPERTY', 'PROPERTY',
        'OTHER', 'OTHER', 'VIOLENT', 'VIOLENT', 'VIOLENT',
        'PROPERTY', 'TRAFFIC', 'OTHER', 'OTHER', 'OTHER'),
        MOD(seq - 1, 25))::VARCHAR                     AS CATEGORY,
    GET(ARRAY_CONSTRUCT('MISDEMEANOR', 'FELONY', 'FELONY', 'FELONY', 'FELONY',
        'FELONY', 'MISDEMEANOR', 'MISDEMEANOR', 'MISDEMEANOR', 'MISDEMEANOR',
        'FELONY', 'MISDEMEANOR', 'MISDEMEANOR', 'FELONY', 'FELONY',
        'MISDEMEANOR', 'INFRACTION', 'FELONY', 'FELONY', 'FELONY',
        'FELONY', 'INFRACTION', 'INFRACTION', 'MISDEMEANOR', 'MISDEMEANOR'),
        MOD(seq - 1, 25))::VARCHAR                     AS SEVERITY,
    GET(ARRAY_CONSTRUCT('A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'A',
        'A', 'B', 'A', 'B', 'B', 'B', 'B', 'A', 'A', 'A',
        'A', 'B', 'B', 'B', 'B'),
        MOD(seq - 1, 25))::VARCHAR                     AS NIBRS_GROUP
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100)));

-- ============================================================================
-- 5. FACT_SERVICE_REQUEST (~60K over 5 years)
-- Seasonality: Potholes spring, snow winter, mosquitos summer, 5% YoY growth
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.FACT_SERVICE_REQUEST
    (DATE_KEY, LOCATION_KEY, DEPT_KEY, CATEGORY, REQUESTS_OPENED, REQUESTS_CLOSED,
     AVG_RESOLUTION_DAYS, SATISFACTION_AVG, OVERDUE_COUNT, CHANNEL)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 10000, RANDOM())                        AS LOCATION_KEY,
    GET(ARRAY_CONSTRUCT(1, 1, 1, 4, 6, 6, 7, 7), UNIFORM(0, 7, RANDOM())) AS DEPT_KEY,
    GET(ARRAY_CONSTRUCT('POTHOLE', 'POTHOLE', 'STREETLIGHT', 'TRASH', 'NOISE', 'GRAFFITI', 'WATER', 'SIDEWALK', 'TREE', 'MOSQUITO'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS CATEGORY,
    UNIFORM(1, 5, RANDOM())                            AS REQUESTS_OPENED,
    UNIFORM(0, 5, RANDOM())                            AS REQUESTS_CLOSED,
    -- Resolution days: log-normal (most fast, some very slow for low-priority)
    GREATEST(0.5, ROUND(EXP(NORMAL(1.8, 0.8, RANDOM())), 2)) AS AVG_RESOLUTION_DAYS,
    -- Satisfaction: left-skewed (mostly satisfied)
    IFF(UNIFORM(0, 100, RANDOM()) < 3, NULL,
        LEAST(10, GREATEST(1, ROUND(NORMAL(7.2, 1.5, RANDOM()), 2)))) AS SATISFACTION_AVG,
    IFF(UNIFORM(0, 100, RANDOM()) < 15, UNIFORM(1, 5, RANDOM()), 0) AS OVERDUE_COUNT,
    GET(ARRAY_CONSTRUCT('PHONE', 'PHONE', 'WEB', 'WEB', 'APP', 'APP', 'APP', 'EMAIL', 'WALK_IN', 'SOCIAL'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS CHANNEL
FROM CIVIC_GOV.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    10
    + CASE WHEN MONTH(d.FULL_DATE) IN (3, 4, 5) THEN 5 ELSE 0 END    -- spring potholes
    + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 4 ELSE 0 END   -- winter snow
    + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8) THEN 3 ELSE 0 END    -- summer mosquitos
    + CASE WHEN DAYOFWEEK(d.FULL_DATE) NOT IN (0, 6) THEN 2 ELSE 0 END
)
AND UNIFORM(0, 100, RANDOM()) < (50 + 5 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)); -- 5% YoY growth

-- ============================================================================
-- 6. FACT_PUBLIC_SAFETY (~80K incidents)
-- Patterns: Weekend/night peaks, summer crime spike, holiday DUI, 2% YoY decline
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.FACT_PUBLIC_SAFETY
    (DATE_KEY, LOCATION_KEY, OFFENSE_KEY, INCIDENTS, RESPONSE_TIME_MINUTES,
     ARRESTS, CLEARANCE_FLAG, UNITS_DEPLOYED, PRIORITY)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 10000, RANDOM())                        AS LOCATION_KEY,
    UNIFORM(1, 100, RANDOM())                          AS OFFENSE_KEY,
    UNIFORM(1, 4, RANDOM())                            AS INCIDENTS,
    -- Response time: log-normal (most quick, some slow)
    GREATEST(1, ROUND(EXP(NORMAL(2.0, 0.7, RANDOM())), 2)) AS RESPONSE_TIME_MINUTES,
    IFF(UNIFORM(0, 100, RANDOM()) < 25, UNIFORM(1, 3, RANDOM()), 0) AS ARRESTS,
    IFF(UNIFORM(0, 100, RANDOM()) < 35, TRUE, FALSE)  AS CLEARANCE_FLAG,
    UNIFORM(1, 6, RANDOM())                            AS UNITS_DEPLOYED,
    GET(ARRAY_CONSTRUCT('P1', 'P2', 'P2', 'P3', 'P3', 'P3', 'P4', 'P4', 'P5'),
        UNIFORM(0, 8, RANDOM()))::VARCHAR              AS PRIORITY
FROM CIVIC_GOV.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    12
    + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8) THEN 6 ELSE 0 END       -- summer spike
    + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (0, 5, 6) THEN 4 ELSE 0 END   -- weekend peak
    + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1) THEN 2 ELSE 0 END          -- holiday DUI
    - ROUND(2 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE))::INT -- 2% YoY decline
);

-- ============================================================================
-- 7. FACT_PERMIT_ACTIVITY (~30K permits)
-- Patterns: Construction seasonal spring/summer peak, economic growth
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.FACT_PERMIT_ACTIVITY
    (DATE_KEY, LOCATION_KEY, DEPT_KEY, PERMIT_TYPE, PERMITS_APPLIED, PERMITS_ISSUED,
     PERMITS_DENIED, AVG_REVIEW_DAYS, TOTAL_VALUATION, INSPECTIONS_COMPLETED, INSPECTION_PASS_RATE)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 10000, RANDOM())                        AS LOCATION_KEY,
    GET(ARRAY_CONSTRUCT(5, 5, 13, 13, 14), UNIFORM(0, 4, RANDOM())) AS DEPT_KEY,
    GET(ARRAY_CONSTRUCT('BUILDING', 'BUILDING', 'BUILDING', 'ELECTRICAL', 'PLUMBING', 'MECHANICAL', 'DEMOLITION'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS PERMIT_TYPE,
    UNIFORM(1, 8, RANDOM())                            AS PERMITS_APPLIED,
    UNIFORM(0, 7, RANDOM())                            AS PERMITS_ISSUED,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, UNIFORM(1, 2, RANDOM()), 0) AS PERMITS_DENIED,
    -- Review days: varies by complexity
    GREATEST(1, ROUND(EXP(NORMAL(2.5, 0.6, RANDOM())), 2)) AS AVG_REVIEW_DAYS,
    -- Valuation: log-normal (small repairs to large projects)
    ROUND(EXP(NORMAL(10.5, 2.0, RANDOM())), 2)        AS TOTAL_VALUATION,
    UNIFORM(0, 10, RANDOM())                           AS INSPECTIONS_COMPLETED,
    LEAST(1.0, GREATEST(0.50, ROUND(NORMAL(0.82, 0.10, RANDOM()), 4))) AS INSPECTION_PASS_RATE
FROM CIVIC_GOV.GOLD.DIM_DATE d
WHERE d.IS_WEEKEND = FALSE
  AND UNIFORM(0, 100, RANDOM()) < (
      8
      + CASE WHEN MONTH(d.FULL_DATE) IN (3, 4, 5, 6, 7, 8) THEN 6 ELSE 0 END -- construction season
      + CASE WHEN MONTH(d.FULL_DATE) IN (9, 10) THEN 3 ELSE 0 END
  );

-- ============================================================================
-- 8. FACT_BUDGET_EXECUTION (monthly × department)
-- Pattern: Linear spend, Q4 fiscal rush (Apr-Jun)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.FACT_BUDGET_EXECUTION
    (DATE_KEY, DEPT_KEY, FUND, PROGRAM, BUDGETED, ENCUMBERED, ACTUAL,
     VARIANCE_PCT, AVAILABLE_BALANCE)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    dept                                               AS DEPT_KEY,
    GET(ARRAY_CONSTRUCT('GENERAL', 'GENERAL', 'GENERAL', 'ENTERPRISE', 'SPECIAL_REVENUE', 'CAPITAL'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS FUND,
    GET(ARRAY_CONSTRUCT('Operations', 'Personnel', 'Capital Projects', 'Maintenance', 'Programs', 'Administration'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS PROGRAM,
    -- Budgeted: annual / 12 (consistent monthly allocation)
    ROUND(EXP(NORMAL(11.5, 1.2, RANDOM())) / 12.0, 2) AS BUDGETED,
    -- Encumbered: committed but not spent
    ROUND(EXP(NORMAL(11.5, 1.2, RANDOM())) / 12.0 * UNIFORM(5, 20, RANDOM()) / 100.0, 2) AS ENCUMBERED,
    -- Actual: Q4 rush (fiscal months 10-12 = Apr-Jun)
    ROUND(EXP(NORMAL(11.5, 1.2, RANDOM())) / 12.0
        * (UNIFORM(75, 110, RANDOM()) / 100.0)
        * (1.0 + CASE
            WHEN MONTH(d.FULL_DATE) IN (4, 5, 6) THEN 0.30  -- Q4 fiscal rush
            WHEN MONTH(d.FULL_DATE) IN (7) THEN -0.20         -- new FY start slow
            ELSE 0 END)
    , 2)                                               AS ACTUAL,
    -- Variance %: actual vs budgeted
    ROUND(NORMAL(0.0, 0.08, RANDOM())
        + CASE WHEN MONTH(d.FULL_DATE) IN (4, 5, 6) THEN 0.15 ELSE 0 END
    , 4)                                               AS VARIANCE_PCT,
    -- Available: decreasing through fiscal year
    ROUND(GREATEST(0, EXP(NORMAL(11.5, 1.2, RANDOM()))
        * GREATEST(0, (12 - (CASE WHEN MONTH(d.FULL_DATE) >= 7 THEN MONTH(d.FULL_DATE) - 6 ELSE MONTH(d.FULL_DATE) + 6 END)) / 12.0)
    ), 2)                                              AS AVAILABLE_BALANCE
FROM CIVIC_GOV.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 15, RANDOM()) AS dept FROM TABLE(GENERATOR(ROWCOUNT => 3))) depts
WHERE DAY(d.FULL_DATE) = 1;

-- ============================================================================
-- 9. FACT_CODE_COMPLIANCE (~20K violations)
-- Pattern: Summer peak (visible property issues), complaint-driven
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.FACT_CODE_COMPLIANCE
    (DATE_KEY, LOCATION_KEY, VIOLATION_TYPE, VIOLATIONS_OPENED, VIOLATIONS_CLOSED,
     FINES_ISSUED, FINES_COLLECTED, COMPLIANCE_RATE_PCT, AVG_DAYS_TO_COMPLY)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 10000, RANDOM())                        AS LOCATION_KEY,
    GET(ARRAY_CONSTRUCT('OVERGROWN', 'OVERGROWN', 'JUNK_VEHICLE', 'STRUCTURAL', 'SIGNAGE', 'ZONING'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS VIOLATION_TYPE,
    UNIFORM(1, 4, RANDOM())                            AS VIOLATIONS_OPENED,
    UNIFORM(0, 3, RANDOM())                            AS VIOLATIONS_CLOSED,
    IFF(UNIFORM(0, 100, RANDOM()) < 40,
        ROUND(UNIFORM(50, 1000, RANDOM()), 2), 0)     AS FINES_ISSUED,
    IFF(UNIFORM(0, 100, RANDOM()) < 30,
        ROUND(UNIFORM(50, 800, RANDOM()), 2), 0)      AS FINES_COLLECTED,
    LEAST(1.0, GREATEST(0.30, ROUND(NORMAL(0.72, 0.12, RANDOM()), 4))) AS COMPLIANCE_RATE_PCT,
    GREATEST(1, ROUND(EXP(NORMAL(2.8, 0.7, RANDOM())), 2)) AS AVG_DAYS_TO_COMPLY
FROM CIVIC_GOV.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    5
    + CASE WHEN MONTH(d.FULL_DATE) IN (5, 6, 7, 8, 9) THEN 6 ELSE 0 END  -- summer visible issues
    + CASE WHEN DAYOFWEEK(d.FULL_DATE) NOT IN (0, 6) THEN 2 ELSE 0 END
);

-- ============================================================================
-- 10. AGG_WARD_SCORECARD (monthly × 12 wards)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.AGG_WARD_SCORECARD
    (MONTH_KEY, WARD, SERVICE_REQUESTS, AVG_RESOLUTION_DAYS, SAFETY_INCIDENTS,
     RESPONSE_TIME_AVG, PERMITS_ISSUED, CODE_VIOLATIONS, SATISFACTION_AVG, PROPERTY_VALUE_AVG)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    LPAD(ward_num::VARCHAR, 2, '0')                    AS WARD,
    UNIFORM(30, 200, RANDOM())                         AS SERVICE_REQUESTS,
    GREATEST(1, ROUND(NORMAL(8, 4, RANDOM()), 2))     AS AVG_RESOLUTION_DAYS,
    UNIFORM(10, 150, RANDOM())                         AS SAFETY_INCIDENTS,
    GREATEST(2, ROUND(NORMAL(7.5, 2.5, RANDOM()), 2)) AS RESPONSE_TIME_AVG,
    UNIFORM(5, 50, RANDOM())                           AS PERMITS_ISSUED,
    UNIFORM(3, 40, RANDOM())                           AS CODE_VIOLATIONS,
    LEAST(10, GREATEST(3, ROUND(NORMAL(7.0, 1.2, RANDOM()), 2))) AS SATISFACTION_AVG,
    ROUND(EXP(NORMAL(11.8, 0.5, RANDOM())), 2)        AS PROPERTY_VALUE_AVG
FROM CIVIC_GOV.GOLD.DIM_DATE d
CROSS JOIN (SELECT SEQ4() + 1 AS ward_num FROM TABLE(GENERATOR(ROWCOUNT => 12))) wards
WHERE DAY(d.FULL_DATE) = 1;

-- ============================================================================
-- 11. AGG_DEPARTMENT_KPI (monthly)
-- ============================================================================
INSERT INTO CIVIC_GOV.GOLD.AGG_DEPARTMENT_KPI
    (MONTH_KEY, DEPT_KEY, BUDGET_UTILIZATION_PCT, SERVICE_LEVEL_PCT,
     BACKLOG_COUNT, AVG_CYCLE_TIME_DAYS, CITIZEN_SATISFACTION_AVG, YEAR_OVER_YEAR_TREND)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    dept                                               AS DEPT_KEY,
    -- Budget utilization: increases through fiscal year
    LEAST(1.0, GREATEST(0.30, ROUND(
        (CASE WHEN MONTH(d.FULL_DATE) >= 7 THEN MONTH(d.FULL_DATE) - 6 ELSE MONTH(d.FULL_DATE) + 6 END) / 12.0
        + NORMAL(0, 0.05, RANDOM())
    , 4)))                                             AS BUDGET_UTILIZATION_PCT,
    LEAST(1.0, GREATEST(0.50, ROUND(NORMAL(0.85, 0.08, RANDOM()), 4))) AS SERVICE_LEVEL_PCT,
    GREATEST(0, ROUND(NORMAL(45, 30, RANDOM()))::INT)  AS BACKLOG_COUNT,
    GREATEST(0.5, ROUND(EXP(NORMAL(1.5, 0.6, RANDOM())), 2)) AS AVG_CYCLE_TIME_DAYS,
    LEAST(10, GREATEST(3, ROUND(NORMAL(7.1, 1.0, RANDOM()), 2))) AS CITIZEN_SATISFACTION_AVG,
    GET(ARRAY_CONSTRUCT('IMPROVING', 'IMPROVING', 'STABLE', 'STABLE', 'STABLE', 'DECLINING'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS YEAR_OVER_YEAR_TREND
FROM CIVIC_GOV.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 15, RANDOM()) AS dept FROM TABLE(GENERATOR(ROWCOUNT => 3))) depts
WHERE DAY(d.FULL_DATE) = 1;
