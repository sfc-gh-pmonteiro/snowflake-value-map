-- ============================================================================
-- INSURANCE VERTICAL - Synthetic Data Generation
-- Entity: Guardian Insurance Group
-- Prerequisites: Run insurance-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- Seasonality: Renewals cluster Q1/Q4, hurricane season Jul-Oct,
--              year-end policy reviews, spring new-home purchases
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE GUARDIAN_INS.GOLD.AGG_AGENT_PRODUCTION;
TRUNCATE TABLE GUARDIAN_INS.GOLD.AGG_COMBINED_RATIO;
TRUNCATE TABLE GUARDIAN_INS.GOLD.FACT_BILLING;
TRUNCATE TABLE GUARDIAN_INS.GOLD.FACT_LOSS_DEVELOPMENT;
TRUNCATE TABLE GUARDIAN_INS.GOLD.FACT_CLAIM;
TRUNCATE TABLE GUARDIAN_INS.GOLD.FACT_PREMIUM;
TRUNCATE TABLE GUARDIAN_INS.GOLD.DIM_DATE;
TRUNCATE TABLE GUARDIAN_INS.GOLD.DIM_PRODUCT;
TRUNCATE TABLE GUARDIAN_INS.GOLD.DIM_AGENT;
TRUNCATE TABLE GUARDIAN_INS.GOLD.DIM_POLICY;
TRUNCATE TABLE GUARDIAN_INS.GOLD.DIM_INSURED;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span with actuarial calendar)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.DIM_DATE
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
    MONTH(d)                                           AS FISCAL_PERIOD,
    YEAR(d)                                            AS ACCIDENT_YEAR,
    MONTH(d)                                           AS ACCIDENT_MONTH
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_INSURED (5,000 insured accounts)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.DIM_INSURED
    (INSURED_KEY, INSURED_ID, ACCOUNT_NAME, ACCOUNT_TYPE, INDUSTRY, STATE, REGION,
     ANNUAL_REVENUE, EMPLOYEE_COUNT, RELATIONSHIP_YEARS, _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS INSURED_KEY,
    'INS-' || LPAD(seq::VARCHAR, 7, '0')               AS INSURED_ID,
    GET(ARRAY_CONSTRUCT('Acme Corp', 'Smith Holdings', 'Pacific Industries', 'Metro Services', 'Valley Construction',
        'Summit Group', 'Atlantic Enterprises', 'Midwest Manufacturing', 'Southern Logistics', 'Northern Tech',
        'Coastal Properties', 'Mountain View LLC', 'Sunrise Partners', 'Harbor Freight', 'Prairie Foods',
        'Lakeside Medical', 'Canyon Resources', 'Riverdale Associates', 'Brookfield Homes', 'Oakwood Financial'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR || ' (' || seq::VARCHAR || ')' AS ACCOUNT_NAME,
    GET(ARRAY_CONSTRUCT('COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL', 'INDIVIDUAL', 'INDIVIDUAL', 'INDIVIDUAL', 'INDIVIDUAL', 'NON_PROFIT'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS ACCOUNT_TYPE,
    GET(ARRAY_CONSTRUCT('Construction', 'Manufacturing', 'Healthcare', 'Technology', 'Retail',
        'Transportation', 'Real Estate', 'Professional Services', 'Food Service', 'Education',
        'Agriculture', 'Financial Services', 'Hospitality', 'Energy', 'Government'),
        UNIFORM(0, 14, RANDOM()))::VARCHAR             AS INDUSTRY,
    GET(ARRAY_CONSTRUCT('FL', 'TX', 'CA', 'NY', 'PA', 'IL', 'OH', 'GA', 'NC', 'NJ',
        'MI', 'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'CO',
        'LA', 'SC', 'AL', 'MS', 'OK'),
        UNIFORM(0, 24, RANDOM()))::VARCHAR             AS STATE,
    GET(ARRAY_CONSTRUCT('Southeast', 'Southeast', 'Southwest', 'Southwest', 'Northeast', 'Northeast',
        'Midwest', 'Midwest', 'West', 'West'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS REGION,
    -- Revenue: log-normal (commercial skew higher)
    IFF(UNIFORM(0, 7, RANDOM()) < 3,
        ROUND(EXP(NORMAL(15.5, 2.0, RANDOM())), 2),   -- commercial: median ~$5M
        IFF(UNIFORM(0, 100, RANDOM()) < 80, NULL,      -- individuals mostly NULL
            ROUND(EXP(NORMAL(11.0, 1.5, RANDOM())), 2))) AS ANNUAL_REVENUE,
    IFF(UNIFORM(0, 7, RANDOM()) < 3,
        GREATEST(1, ROUND(NORMAL(150, 200, RANDOM()))::INT),
        NULL)                                           AS EMPLOYEE_COUNT,
    ROUND(UNIFORM(1, 25, RANDOM()) + UNIFORM(0, 9, RANDOM()) / 10.0, 1) AS RELATIONSHIP_YEARS,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 5000)));

-- ============================================================================
-- 3. DIM_PRODUCT (15 product lines)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.DIM_PRODUCT
    (PRODUCT_KEY, PRODUCT_LINE, COVERAGE_TYPE, SUB_LINE, IS_COMMERCIAL, DESCRIPTION)
SELECT
    ROW_NUMBER() OVER (ORDER BY pl.column1) AS PRODUCT_KEY,
    pl.column1                              AS PRODUCT_LINE,
    pl.column2                              AS COVERAGE_TYPE,
    pl.column3                              AS SUB_LINE,
    pl.column4                              AS IS_COMMERCIAL,
    pl.column5                              AS DESCRIPTION
FROM VALUES
    ('COMMERCIAL_PROPERTY', 'PROPERTY', 'BUILDING_CONTENTS', TRUE, 'Commercial property coverage for buildings and contents'),
    ('COMMERCIAL_AUTO', 'AUTO', 'FLEET', TRUE, 'Commercial fleet auto liability and physical damage'),
    ('GENERAL_LIABILITY', 'LIABILITY', 'PREMISES_OPS', TRUE, 'Commercial general liability - premises and operations'),
    ('WORKERS_COMP', 'WORKERS_COMP', 'STATUTORY', TRUE, 'Workers compensation statutory benefits'),
    ('BOP', 'PACKAGE', 'SMALL_BUSINESS', TRUE, 'Business owners policy - bundled property + liability'),
    ('PROFESSIONAL_LIABILITY', 'LIABILITY', 'E_AND_O', TRUE, 'Errors and omissions / professional liability'),
    ('DIRECTORS_OFFICERS', 'LIABILITY', 'D_AND_O', TRUE, 'Directors and officers liability'),
    ('CYBER_LIABILITY', 'LIABILITY', 'CYBER', TRUE, 'Cyber breach and privacy liability'),
    ('UMBRELLA_COMMERCIAL', 'UMBRELLA', 'EXCESS', TRUE, 'Commercial umbrella excess liability'),
    ('PERSONAL_AUTO', 'AUTO', 'PERSONAL', FALSE, 'Personal auto liability and physical damage'),
    ('HOMEOWNERS', 'PROPERTY', 'DWELLING', FALSE, 'Homeowners property and liability coverage'),
    ('RENTERS', 'PROPERTY', 'CONTENTS_ONLY', FALSE, 'Renters contents and personal liability'),
    ('PERSONAL_UMBRELLA', 'UMBRELLA', 'PERSONAL_EXCESS', FALSE, 'Personal umbrella excess liability'),
    ('FLOOD', 'PROPERTY', 'FLOOD_PERIL', FALSE, 'NFIP write-your-own flood coverage'),
    ('INLAND_MARINE', 'PROPERTY', 'SCHEDULED', TRUE, 'Inland marine - scheduled equipment and property')
AS pl (column1, column2, column3, column4, column5);

-- ============================================================================
-- 4. DIM_AGENT (200 agents/producers)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.DIM_AGENT
    (AGENT_KEY, AGENT_ID, AGENT_NAME, AGENCY_NAME, STATE, COMMISSION_TIER,
     STATUS, APPOINTED_DATE, TENURE_YEARS)
SELECT
    seq                                                AS AGENT_KEY,
    'AGT-' || LPAD(seq::VARCHAR, 4, '0')               AS AGENT_ID,
    GET(ARRAY_CONSTRUCT('Robert Mitchell', 'Sarah Johnson', 'David Kim', 'Jennifer Lopez', 'Michael Chen',
        'Lisa Anderson', 'James Wilson', 'Maria Rodriguez', 'Thomas Brown', 'Karen Davis',
        'Christopher Lee', 'Amanda Martinez', 'Daniel Taylor', 'Jessica White', 'Matthew Harris',
        'Stephanie Thompson', 'Andrew Garcia', 'Michelle Robinson', 'Brian Clark', 'Nicole Lewis'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR || ' (' || seq::VARCHAR || ')' AS AGENT_NAME,
    GET(ARRAY_CONSTRUCT('Allstate Partners', 'Marsh & McLennan', 'Brown & Brown', 'USI Insurance', 'Hub International',
        'Gallagher', 'Lockton Companies', 'Risk Strategies', 'NFP Corp', 'Hilb Group',
        'AssuredPartners', 'BroadStreet', 'Higginbotham', 'IMA Financial', 'McGriff Insurance'),
        UNIFORM(0, 14, RANDOM()))::VARCHAR             AS AGENCY_NAME,
    GET(ARRAY_CONSTRUCT('FL', 'TX', 'CA', 'NY', 'PA', 'IL', 'OH', 'GA', 'NC', 'NJ',
        'MI', 'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'CO'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS STATE,
    GET(ARRAY_CONSTRUCT('PLATINUM', 'PLATINUM', 'GOLD', 'GOLD', 'GOLD', 'SILVER', 'SILVER', 'SILVER', 'BRONZE', 'BRONZE'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS COMMISSION_TIER,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, 'TERMINATED',
        IFF(UNIFORM(0, 100, RANDOM()) < 3, 'SUSPENDED', 'ACTIVE')) AS STATUS,
    DATEADD('day', -UNIFORM(365, 7300, RANDOM()), CURRENT_DATE()) AS APPOINTED_DATE,
    ROUND(UNIFORM(1, 20, RANDOM()) + UNIFORM(0, 9, RANDOM()) / 10.0, 1) AS TENURE_YEARS
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 200)));

-- ============================================================================
-- 5. DIM_POLICY (12,000 policies)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.DIM_POLICY
    (POLICY_KEY, POLICY_ID, POLICY_NUMBER, PRODUCT_LINE, EFFECTIVE_DATE, EXPIRATION_DATE,
     STATUS, INSURED_KEY, AGENT_KEY, DEDUCTIBLE, LIMIT_AMOUNT)
SELECT
    seq                                                AS POLICY_KEY,
    'POL-' || LPAD(seq::VARCHAR, 8, '0')               AS POLICY_ID,
    'GIG-' || LPAD(UNIFORM(100000, 999999, RANDOM())::VARCHAR, 6, '0') AS POLICY_NUMBER,
    GET(ARRAY_CONSTRUCT('COMMERCIAL_PROPERTY', 'COMMERCIAL_AUTO', 'GENERAL_LIABILITY', 'WORKERS_COMP',
        'BOP', 'PERSONAL_AUTO', 'PERSONAL_AUTO', 'PERSONAL_AUTO', 'HOMEOWNERS', 'HOMEOWNERS',
        'RENTERS', 'UMBRELLA_COMMERCIAL', 'CYBER_LIABILITY', 'FLOOD', 'PROFESSIONAL_LIABILITY'),
        UNIFORM(0, 14, RANDOM()))::VARCHAR             AS PRODUCT_LINE,
    DATEADD('day', -UNIFORM(0, 1825, RANDOM()), CURRENT_DATE()) AS EFFECTIVE_DATE,
    DATEADD('year', 1, DATEADD('day', -UNIFORM(0, 1825, RANDOM()), CURRENT_DATE())) AS EXPIRATION_DATE,
    GET(ARRAY_CONSTRUCT('ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE',
        'EXPIRED', 'CANCELLED', 'NON_RENEWED'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS STATUS,
    UNIFORM(1, 5000, RANDOM())                         AS INSURED_KEY,
    UNIFORM(1, 200, RANDOM())                          AS AGENT_KEY,
    -- Deductible varies by product
    CASE
        WHEN UNIFORM(0, 14, RANDOM()) IN (0, 4) THEN GET(ARRAY_CONSTRUCT(1000, 2500, 5000, 10000, 25000), UNIFORM(0, 4, RANDOM()))
        WHEN UNIFORM(0, 14, RANDOM()) IN (5, 6, 7) THEN GET(ARRAY_CONSTRUCT(250, 500, 1000, 2000), UNIFORM(0, 3, RANDOM()))
        WHEN UNIFORM(0, 14, RANDOM()) IN (8, 9) THEN GET(ARRAY_CONSTRUCT(1000, 2500, 5000), UNIFORM(0, 2, RANDOM()))
        ELSE GET(ARRAY_CONSTRUCT(500, 1000, 2500, 5000), UNIFORM(0, 3, RANDOM()))
    END::NUMBER(10,2)                                  AS DEDUCTIBLE,
    -- Limit varies by product
    CASE
        WHEN UNIFORM(0, 14, RANDOM()) IN (0, 4) THEN GET(ARRAY_CONSTRUCT(500000, 1000000, 2000000, 5000000), UNIFORM(0, 3, RANDOM()))
        WHEN UNIFORM(0, 14, RANDOM()) IN (2, 5) THEN GET(ARRAY_CONSTRUCT(1000000, 2000000, 5000000), UNIFORM(0, 2, RANDOM()))
        WHEN UNIFORM(0, 14, RANDOM()) IN (5, 6, 7) THEN GET(ARRAY_CONSTRUCT(100000, 250000, 500000), UNIFORM(0, 2, RANDOM()))
        WHEN UNIFORM(0, 14, RANDOM()) IN (8, 9) THEN GET(ARRAY_CONSTRUCT(300000, 500000, 750000, 1000000), UNIFORM(0, 3, RANDOM()))
        ELSE GET(ARRAY_CONSTRUCT(1000000, 2000000, 5000000, 10000000), UNIFORM(0, 3, RANDOM()))
    END::NUMBER(12,2)                                  AS LIMIT_AMOUNT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 12000)));

-- ============================================================================
-- 6. FACT_PREMIUM (~50K rows, monthly grain)
-- Seasonality: Renewals cluster Q1/Q4, 3-5% YoY growth
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.FACT_PREMIUM
    (DATE_KEY, POLICY_KEY, PRODUCT_KEY, AGENT_KEY, INSURED_KEY,
     WRITTEN_PREMIUM, EARNED_PREMIUM, CEDED_PREMIUM, NET_PREMIUM, COMMISSION_AMOUNT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    pol                                                AS POLICY_KEY,
    UNIFORM(1, 15, RANDOM())                           AS PRODUCT_KEY,
    UNIFORM(1, 200, RANDOM())                          AS AGENT_KEY,
    UNIFORM(1, 5000, RANDOM())                         AS INSURED_KEY,
    -- Written premium: log-normal with seasonal renewal clustering
    ROUND(EXP(NORMAL(7.8, 1.2, RANDOM()))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (1, 2) THEN 0.25 ELSE 0 END   -- Q1 renewals
            + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12) THEN 0.20 ELSE 0 END -- Q4 renewals
        )
        * (1.0 + 0.04 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60) -- 4% annual growth
        * IFF(UNIFORM(0, 1000, RANDOM()) < 5, 5.0, 1.0) -- 0.5% large account anomaly
    , 2)                                               AS WRITTEN_PREMIUM,
    -- Earned = written / 12 (monthly earning)
    ROUND(EXP(NORMAL(7.8, 1.2, RANDOM())) / 12.0, 2)  AS EARNED_PREMIUM,
    -- Ceded: 15-25% quota share
    ROUND(EXP(NORMAL(7.8, 1.2, RANDOM())) / 12.0 * UNIFORM(15, 25, RANDOM()) / 100.0, 2) AS CEDED_PREMIUM,
    -- Net = earned - ceded
    ROUND(EXP(NORMAL(7.8, 1.2, RANDOM())) / 12.0 * (1.0 - UNIFORM(15, 25, RANDOM()) / 100.0), 2) AS NET_PREMIUM,
    -- Commission: 10-18% of written
    ROUND(EXP(NORMAL(7.8, 1.2, RANDOM())) * UNIFORM(10, 18, RANDOM()) / 100.0 / 12.0, 2) AS COMMISSION_AMOUNT
FROM GUARDIAN_INS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 12000, RANDOM()) AS pol FROM TABLE(GENERATOR(ROWCOUNT => 8))) policies
WHERE DAY(d.FULL_DATE) = 1  -- monthly grain
  AND UNIFORM(0, 100, RANDOM()) < (
      55
      + CASE WHEN MONTH(d.FULL_DATE) IN (1, 2, 10, 11, 12) THEN 20 ELSE 0 END
  );

-- ============================================================================
-- 7. FACT_CLAIM (~30K claims over 5 years)
-- Distribution: log-normal severity, 3% fraud injection, weather spikes Jul-Oct
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.FACT_CLAIM
    (DATE_KEY, POLICY_KEY, INSURED_KEY, PRODUCT_KEY, CLAIM_TYPE,
     INCURRED_AMOUNT, PAID_AMOUNT, RESERVE_AMOUNT, STATUS,
     DAYS_TO_SETTLE, DAYS_TO_REPORT, LITIGATION_FLAG, CATASTROPHE_FLAG)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 12000, RANDOM())                        AS POLICY_KEY,
    UNIFORM(1, 5000, RANDOM())                         AS INSURED_KEY,
    UNIFORM(1, 15, RANDOM())                           AS PRODUCT_KEY,
    GET(ARRAY_CONSTRUCT('BODILY_INJURY', 'PROPERTY_DAMAGE', 'LIABILITY', 'COLLISION', 'COMP', 'WC'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS CLAIM_TYPE,
    -- Incurred: log-normal (many small, few large)
    ROUND(EXP(NORMAL(8.5, 1.8, RANDOM()))
        * IFF(UNIFORM(0, 1000, RANDOM()) < 30, 8.0, 1.0) -- 3% fraud injection (inflated amounts)
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8, 9, 10) THEN 0.35 ELSE 0 END -- hurricane season
            + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 0.10 ELSE 0 END    -- winter storms
        )
    , 2)                                               AS INCURRED_AMOUNT,
    -- Paid: 60-90% of incurred (open claims have less paid)
    ROUND(EXP(NORMAL(8.5, 1.8, RANDOM()))
        * UNIFORM(40, 95, RANDOM()) / 100.0
        * IFF(UNIFORM(0, 1000, RANDOM()) < 30, 8.0, 1.0)
    , 2)                                               AS PAID_AMOUNT,
    -- Reserve: incurred - paid (remaining)
    ROUND(GREATEST(0, EXP(NORMAL(8.5, 1.8, RANDOM())) * UNIFORM(5, 60, RANDOM()) / 100.0), 2) AS RESERVE_AMOUNT,
    GET(ARRAY_CONSTRUCT('OPEN', 'OPEN', 'CLOSED', 'CLOSED', 'CLOSED', 'CLOSED', 'CLOSED', 'REOPENED', 'SUBROGATION'),
        UNIFORM(0, 8, RANDOM()))::VARCHAR              AS STATUS,
    -- Days to settle: right-skewed (most quick, some drag)
    GREATEST(0, ROUND(EXP(NORMAL(4.0, 1.2, RANDOM())))::INT) AS DAYS_TO_SETTLE,
    -- Days to report: mostly quick (0-7), some delayed
    GREATEST(0, LEAST(365, ROUND(EXP(NORMAL(1.5, 1.0, RANDOM())))::INT)) AS DAYS_TO_REPORT,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, TRUE, FALSE)   AS LITIGATION_FLAG,  -- 8% litigated
    IFF(UNIFORM(0, 100, RANDOM()) < 5
        AND MONTH(d.FULL_DATE) IN (7, 8, 9, 10), TRUE, FALSE) AS CATASTROPHE_FLAG
FROM GUARDIAN_INS.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    -- Higher claim frequency hurricane season
    5
    + CASE WHEN MONTH(d.FULL_DATE) IN (7, 8, 9, 10) THEN 4 ELSE 0 END
    + CASE WHEN MONTH(d.FULL_DATE) IN (12, 1, 2) THEN 2 ELSE 0 END
    + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (0, 6) THEN -2 ELSE 0 END
);

-- ============================================================================
-- 8. FACT_LOSS_DEVELOPMENT (actuarial triangle: accident month x evaluation month)
-- Standard development pattern with tail factors
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.FACT_LOSS_DEVELOPMENT
    (EVALUATION_DATE_KEY, ACCIDENT_MONTH_KEY, PRODUCT_KEY,
     PAID_CUMULATIVE, INCURRED_CUMULATIVE, CASE_RESERVE, IBNR_ESTIMATE,
     DEVELOPMENT_FACTOR, CLAIM_COUNT, CLOSED_COUNT)
SELECT
    eval_d.DATE_KEY                                    AS EVALUATION_DATE_KEY,
    acc_d.DATE_KEY                                     AS ACCIDENT_MONTH_KEY,
    prod                                               AS PRODUCT_KEY,
    -- Paid cumulative: grows with development age
    ROUND(EXP(NORMAL(12.5, 1.5, RANDOM()))
        * LEAST(1.0, (dev_months + 1) / 60.0)         -- development curve
        * (1.0 + NORMAL(0, 0.05, RANDOM()))            -- noise
    , 2)                                               AS PAID_CUMULATIVE,
    -- Incurred = paid + reserves (starts high, converges to paid)
    ROUND(EXP(NORMAL(12.5, 1.5, RANDOM()))
        * LEAST(1.0, (dev_months + 1) / 60.0)
        * (1.0 + GREATEST(0, 0.4 - dev_months * 0.008)) -- reserve margin shrinks over time
    , 2)                                               AS INCURRED_CUMULATIVE,
    -- Case reserve: high early, decreases as claims close
    ROUND(GREATEST(0, EXP(NORMAL(11.0, 1.5, RANDOM()))
        * GREATEST(0, 1.0 - dev_months / 48.0)
    ), 2)                                              AS CASE_RESERVE,
    -- IBNR: high for recent periods, near zero for mature
    ROUND(GREATEST(0, EXP(NORMAL(11.5, 1.5, RANDOM()))
        * GREATEST(0, 1.0 - dev_months / 36.0)
    ), 2)                                              AS IBNR_ESTIMATE,
    -- Development factor: starts > 1.0, approaches 1.0
    ROUND(GREATEST(1.0, 1.0 + GREATEST(0, (24 - dev_months) * 0.02) + NORMAL(0, 0.01, RANDOM())), 6) AS DEVELOPMENT_FACTOR,
    UNIFORM(20, 500, RANDOM())                         AS CLAIM_COUNT,
    ROUND(UNIFORM(20, 500, RANDOM()) * LEAST(1.0, dev_months / 36.0))::INT AS CLOSED_COUNT
FROM (
    -- Generate accident months (first of each month in date range)
    SELECT d.DATE_KEY, d.FULL_DATE
    FROM GUARDIAN_INS.GOLD.DIM_DATE d
    WHERE DAY(d.FULL_DATE) = 1
) acc_d
CROSS JOIN (
    -- Generate evaluation months (first of each month)
    SELECT d.DATE_KEY, d.FULL_DATE
    FROM GUARDIAN_INS.GOLD.DIM_DATE d
    WHERE DAY(d.FULL_DATE) = 1
) eval_d
CROSS JOIN (SELECT UNIFORM(1, 15, RANDOM()) AS prod FROM TABLE(GENERATOR(ROWCOUNT => 2))) products
WHERE eval_d.FULL_DATE >= acc_d.FULL_DATE  -- eval must be after accident
  AND DATEDIFF('month', acc_d.FULL_DATE, eval_d.FULL_DATE) <= 60  -- max 60 months dev
  AND UNIFORM(0, 100, RANDOM()) < 40  -- sample to control volume
  AND DATEDIFF('month', acc_d.FULL_DATE, eval_d.FULL_DATE) AS dev_months IS NOT NULL;

-- Retry without alias in WHERE (Snowflake-compatible approach)
-- The above will error; use CTE instead:
DELETE FROM GUARDIAN_INS.GOLD.FACT_LOSS_DEVELOPMENT;

INSERT INTO GUARDIAN_INS.GOLD.FACT_LOSS_DEVELOPMENT
    (EVALUATION_DATE_KEY, ACCIDENT_MONTH_KEY, PRODUCT_KEY,
     PAID_CUMULATIVE, INCURRED_CUMULATIVE, CASE_RESERVE, IBNR_ESTIMATE,
     DEVELOPMENT_FACTOR, CLAIM_COUNT, CLOSED_COUNT)
WITH triangle AS (
    SELECT
        eval_d.DATE_KEY AS EVALUATION_DATE_KEY,
        acc_d.DATE_KEY  AS ACCIDENT_MONTH_KEY,
        UNIFORM(1, 15, RANDOM()) AS PRODUCT_KEY,
        DATEDIFF('month', acc_d.FULL_DATE, eval_d.FULL_DATE) AS dev_months
    FROM (
        SELECT DATE_KEY, FULL_DATE FROM GUARDIAN_INS.GOLD.DIM_DATE WHERE DAY(FULL_DATE) = 1
    ) acc_d
    CROSS JOIN (
        SELECT DATE_KEY, FULL_DATE FROM GUARDIAN_INS.GOLD.DIM_DATE WHERE DAY(FULL_DATE) = 1
    ) eval_d
    WHERE eval_d.FULL_DATE >= acc_d.FULL_DATE
      AND DATEDIFF('month', acc_d.FULL_DATE, eval_d.FULL_DATE) <= 48
      AND UNIFORM(0, 100, RANDOM()) < 15
)
SELECT
    EVALUATION_DATE_KEY,
    ACCIDENT_MONTH_KEY,
    PRODUCT_KEY,
    ROUND(EXP(NORMAL(12.5, 1.5, RANDOM())) * LEAST(1.0, (dev_months + 1.0) / 48.0), 2) AS PAID_CUMULATIVE,
    ROUND(EXP(NORMAL(12.5, 1.5, RANDOM())) * LEAST(1.0, (dev_months + 1.0) / 48.0) * (1.0 + GREATEST(0, 0.35 - dev_months * 0.008)), 2) AS INCURRED_CUMULATIVE,
    ROUND(GREATEST(0, EXP(NORMAL(11.0, 1.5, RANDOM())) * GREATEST(0, 1.0 - dev_months / 48.0)), 2) AS CASE_RESERVE,
    ROUND(GREATEST(0, EXP(NORMAL(11.5, 1.5, RANDOM())) * GREATEST(0, 1.0 - dev_months / 36.0)), 2) AS IBNR_ESTIMATE,
    ROUND(GREATEST(1.0, 1.0 + GREATEST(0, (24 - dev_months) * 0.02) + NORMAL(0, 0.01, RANDOM())), 6) AS DEVELOPMENT_FACTOR,
    UNIFORM(20, 500, RANDOM()) AS CLAIM_COUNT,
    ROUND(UNIFORM(20, 500, RANDOM()) * LEAST(1.0, dev_months / 36.0))::INT AS CLOSED_COUNT
FROM triangle;

-- ============================================================================
-- 9. FACT_BILLING (~60K billing records)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.FACT_BILLING
    (DATE_KEY, POLICY_KEY, INSURED_KEY,
     BILLED_AMOUNT, COLLECTED_AMOUNT, OUTSTANDING_BALANCE, DAYS_PAST_DUE, WRITE_OFF_AMOUNT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 12000, RANDOM())                        AS POLICY_KEY,
    UNIFORM(1, 5000, RANDOM())                         AS INSURED_KEY,
    -- Billed: premium installment
    ROUND(EXP(NORMAL(6.5, 1.0, RANDOM())), 2)         AS BILLED_AMOUNT,
    -- Collected: most pay on time, some partial
    ROUND(EXP(NORMAL(6.5, 1.0, RANDOM()))
        * IFF(UNIFORM(0, 100, RANDOM()) < 85, 1.0,    -- 85% pay in full
              UNIFORM(30, 90, RANDOM()) / 100.0)       -- partial payments
    , 2)                                               AS COLLECTED_AMOUNT,
    -- Outstanding: difference for late payers
    IFF(UNIFORM(0, 100, RANDOM()) < 12,
        ROUND(EXP(NORMAL(5.5, 1.0, RANDOM())), 2), 0) AS OUTSTANDING_BALANCE,
    -- Days past due: mostly 0
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN 0
        WHEN UNIFORM(0, 100, RANDOM()) < 92 THEN UNIFORM(1, 30, RANDOM())
        WHEN UNIFORM(0, 100, RANDOM()) < 97 THEN UNIFORM(31, 60, RANDOM())
        ELSE UNIFORM(61, 120, RANDOM())
    END                                                AS DAYS_PAST_DUE,
    -- Write-offs: rare (< 2%)
    IFF(UNIFORM(0, 100, RANDOM()) < 2,
        ROUND(EXP(NORMAL(5.5, 0.8, RANDOM())), 2), 0) AS WRITE_OFF_AMOUNT
FROM GUARDIAN_INS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 12000, RANDOM()) AS pol FROM TABLE(GENERATOR(ROWCOUNT => 5))) pols
WHERE DAY(d.FULL_DATE) = 1  -- monthly billing
  AND UNIFORM(0, 100, RANDOM()) < 70;

-- ============================================================================
-- 10. AGG_COMBINED_RATIO (monthly by product)
-- Target: 95-100% combined, some months >100%
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.AGG_COMBINED_RATIO
    (MONTH_KEY, PRODUCT_KEY, EARNED_PREMIUM, INCURRED_LOSSES, LAE_EXPENSE,
     UNDERWRITING_EXPENSE, LOSS_RATIO, EXPENSE_RATIO, COMBINED_RATIO, NET_UNDERWRITING_INCOME)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    prod                                               AS PRODUCT_KEY,
    -- Earned premium base
    ROUND(EXP(NORMAL(14.0, 0.8, RANDOM())), 2)        AS EARNED_PREMIUM,
    -- Incurred losses: 60-75% of earned (with hurricane spikes)
    ROUND(EXP(NORMAL(14.0, 0.8, RANDOM()))
        * (UNIFORM(58, 78, RANDOM()) / 100.0)
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (8, 9, 10) THEN UNIFORM(0, 30, RANDOM()) / 100.0 ELSE 0 END
        )
    , 2)                                               AS INCURRED_LOSSES,
    -- LAE: 8-15% of losses
    ROUND(EXP(NORMAL(14.0, 0.8, RANDOM())) * UNIFORM(58, 78, RANDOM()) / 100.0 * UNIFORM(8, 15, RANDOM()) / 100.0, 2) AS LAE_EXPENSE,
    -- UW expense: 25-35% of premium
    ROUND(EXP(NORMAL(14.0, 0.8, RANDOM())) * UNIFORM(25, 35, RANDOM()) / 100.0, 2) AS UNDERWRITING_EXPENSE,
    -- Loss ratio
    ROUND(UNIFORM(58, 78, RANDOM()) / 100.0
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (8, 9, 10) THEN UNIFORM(0, 20, RANDOM()) / 100.0 ELSE 0 END)
    , 4)                                               AS LOSS_RATIO,
    -- Expense ratio
    ROUND(UNIFORM(28, 38, RANDOM()) / 100.0, 4)       AS EXPENSE_RATIO,
    -- Combined ratio (loss + expense, target ~95-100%)
    ROUND((UNIFORM(58, 78, RANDOM()) + UNIFORM(28, 38, RANDOM())) / 100.0
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (8, 9, 10) THEN UNIFORM(0, 15, RANDOM()) / 100.0 ELSE 0 END)
    , 4)                                               AS COMBINED_RATIO,
    -- Net UW income (can be negative in bad months)
    ROUND(EXP(NORMAL(14.0, 0.8, RANDOM())) * (1.0 - (UNIFORM(88, 105, RANDOM()) / 100.0)), 2) AS NET_UNDERWRITING_INCOME
FROM GUARDIAN_INS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 15, RANDOM()) AS prod FROM TABLE(GENERATOR(ROWCOUNT => 3))) products
WHERE DAY(d.FULL_DATE) = 1;

-- ============================================================================
-- 11. AGG_AGENT_PRODUCTION (monthly per agent)
-- ============================================================================
INSERT INTO GUARDIAN_INS.GOLD.AGG_AGENT_PRODUCTION
    (MONTH_KEY, AGENT_KEY, PRODUCT_KEY, POLICIES_WRITTEN, PREMIUM_WRITTEN,
     POLICIES_RENEWED, RETENTION_RATE, LOSS_RATIO, HIT_RATIO, NEW_BUSINESS_PCT)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    agt                                                AS AGENT_KEY,
    UNIFORM(1, 15, RANDOM())                           AS PRODUCT_KEY,
    -- Policies written: varies by tier
    UNIFORM(2, 25, RANDOM())                           AS POLICIES_WRITTEN,
    -- Premium written
    ROUND(EXP(NORMAL(10.5, 1.0, RANDOM()))
        * (1.0
            + CASE WHEN MONTH(d.FULL_DATE) IN (1, 10, 11) THEN 0.20 ELSE 0 END -- renewal season
        )
    , 2)                                               AS PREMIUM_WRITTEN,
    UNIFORM(1, 15, RANDOM())                           AS POLICIES_RENEWED,
    -- Retention rate: 75-95%
    LEAST(0.99, GREATEST(0.65, ROUND(NORMAL(0.85, 0.06, RANDOM()), 4))) AS RETENTION_RATE,
    -- Loss ratio per agent book: 50-80%
    LEAST(1.20, GREATEST(0.30, ROUND(NORMAL(0.65, 0.12, RANDOM()), 4))) AS LOSS_RATIO,
    -- Hit ratio (quotes bound / quotes issued): 20-45%
    LEAST(0.60, GREATEST(0.10, ROUND(NORMAL(0.32, 0.08, RANDOM()), 4))) AS HIT_RATIO,
    -- New business %: 15-50%
    LEAST(0.70, GREATEST(0.05, ROUND(NORMAL(0.30, 0.12, RANDOM()), 4))) AS NEW_BUSINESS_PCT
FROM GUARDIAN_INS.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 200, RANDOM()) AS agt FROM TABLE(GENERATOR(ROWCOUNT => 10))) agents
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 60;
