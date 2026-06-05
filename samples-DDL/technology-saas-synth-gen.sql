-- ============================================================================
-- TECHNOLOGY / SaaS VERTICAL - Synthetic Data Generation
-- Entity: Nexus Platform Inc (B2B SaaS, developer tools)
-- Prerequisites: Run technology-saas-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~5-8 minutes on XS warehouse
-- Patterns: Exponential MRR growth, power-law usage, cohort decay, B2B weekday bias
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE NEXUS_SAAS.GOLD.AGG_FEATURE_ADOPTION;
TRUNCATE TABLE NEXUS_SAAS.GOLD.AGG_COHORT_METRICS;
TRUNCATE TABLE NEXUS_SAAS.GOLD.AGG_TENANT_HEALTH;
TRUNCATE TABLE NEXUS_SAAS.GOLD.FACT_INFRASTRUCTURE;
TRUNCATE TABLE NEXUS_SAAS.GOLD.FACT_SUPPORT;
TRUNCATE TABLE NEXUS_SAAS.GOLD.FACT_BILLING;
TRUNCATE TABLE NEXUS_SAAS.GOLD.FACT_SUBSCRIPTION;
TRUNCATE TABLE NEXUS_SAAS.GOLD.FACT_PRODUCT_USAGE;
TRUNCATE TABLE NEXUS_SAAS.GOLD.DIM_DATE;
TRUNCATE TABLE NEXUS_SAAS.GOLD.DIM_FEATURE;
TRUNCATE TABLE NEXUS_SAAS.GOLD.DIM_USER;
TRUNCATE TABLE NEXUS_SAAS.GOLD.DIM_TENANT;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN FALSE ELSE TRUE END AS IS_BUSINESS_DAY,
    YEAR(d)                                            AS FISCAL_YEAR,
    MONTH(d)                                           AS FISCAL_PERIOD
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_TENANT (~2000 tenants, cohort-based growth)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.DIM_TENANT
    (TENANT_KEY, TENANT_ID, COMPANY_NAME, INDUSTRY, PLAN_TIER, ARR,
     EMPLOYEE_COUNT, REGION, COHORT_MONTH, CSM_ID, SIGNUP_DATE,
     _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS TENANT_KEY,
    'TNT-' || LPAD(seq::VARCHAR, 6, '0')              AS TENANT_ID,
    'Company ' || seq::VARCHAR                        AS COMPANY_NAME,
    GET(ARRAY_CONSTRUCT(
        'Technology', 'Financial Services', 'Healthcare', 'E-Commerce', 'Media',
        'Education', 'Manufacturing', 'Consulting', 'Retail', 'SaaS',
        'Gaming', 'Logistics', 'Insurance', 'Government', 'Energy'
    ), UNIFORM(0, 14, RANDOM()))::VARCHAR              AS INDUSTRY,
    -- Plan distribution: 40% free, 25% starter, 20% professional, 12% enterprise, 3% custom
    GET(ARRAY_CONSTRUCT(
        'FREE', 'FREE', 'FREE', 'FREE', 'STARTER', 'STARTER', 'STARTER',
        'PROFESSIONAL', 'PROFESSIONAL', 'ENTERPRISE', 'ENTERPRISE', 'CUSTOM'
    ), UNIFORM(0, 11, RANDOM()))::VARCHAR              AS PLAN_TIER,
    -- ARR: power-law; most tenants small, few large
    ROUND(CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 40 THEN 0  -- free tier
        WHEN UNIFORM(0, 100, RANDOM()) < 65 THEN EXP(NORMAL(8.5, 0.5, RANDOM()))  -- $3K-$8K
        WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN EXP(NORMAL(9.5, 0.6, RANDOM()))  -- $8K-$30K
        WHEN UNIFORM(0, 100, RANDOM()) < 97 THEN EXP(NORMAL(10.8, 0.5, RANDOM())) -- $30K-$100K
        ELSE EXP(NORMAL(11.8, 0.4, RANDOM())) -- $100K+ enterprise
    END, 2)                                            AS ARR,
    -- Employee count: correlated with ARR
    GREATEST(5, ROUND(EXP(NORMAL(4.5, 1.2, RANDOM()))))::INT AS EMPLOYEE_COUNT,
    GET(ARRAY_CONSTRUCT('NA', 'NA', 'NA', 'NA', 'EMEA', 'EMEA', 'APAC', 'LATAM'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS REGION,
    -- Cohort month: exponential growth in signups over time
    DATE_TRUNC('month', DATEADD('day',
        -ROUND(GREATEST(1, 1800 * POWER(UNIFORM(0, 100, RANDOM()) / 100.0, 2.0))),
        CURRENT_DATE()))                               AS COHORT_MONTH,
    'CSM-' || LPAD(UNIFORM(1, 25, RANDOM())::VARCHAR, 3, '0') AS CSM_ID,
    DATEADD('day',
        -ROUND(GREATEST(1, 1800 * POWER(UNIFORM(0, 100, RANDOM()) / 100.0, 2.0))),
        CURRENT_DATE())                                AS SIGNUP_DATE,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 2000)));

-- ============================================================================
-- 3. DIM_USER (~20K users across tenants)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.DIM_USER
    (USER_KEY, USER_ID, TENANT_KEY, ROLE, SIGNUP_DATE, NAME, EMAIL_DOMAIN)
SELECT
    seq                                                AS USER_KEY,
    'USR-' || LPAD(seq::VARCHAR, 7, '0')              AS USER_ID,
    -- Power-law: large tenants have many users, most tenants have few
    GREATEST(1, LEAST(2000, ROUND(EXP(NORMAL(5.5, 1.8, RANDOM())))))::INT AS TENANT_KEY,
    GET(ARRAY_CONSTRUCT('ADMIN', 'DEVELOPER', 'DEVELOPER', 'DEVELOPER', 'DEVELOPER',
        'DEVELOPER', 'VIEWER', 'VIEWER', 'BILLING'),
        UNIFORM(0, 8, RANDOM()))::VARCHAR              AS ROLE,
    DATEADD('day', -UNIFORM(1, 1500, RANDOM()), CURRENT_DATE()) AS SIGNUP_DATE,
    'User ' || seq::VARCHAR                           AS NAME,
    GET(ARRAY_CONSTRUCT('company.com', 'startup.io', 'corp.net', 'tech.dev',
        'global.org', 'acme.co', 'firm.com', 'labs.io', 'inc.com', 'sys.tech'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS EMAIL_DOMAIN
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 20000)));

-- ============================================================================
-- 4. DIM_FEATURE (50 product features)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.DIM_FEATURE
    (FEATURE_KEY, FEATURE_NAME, MODULE, RELEASE_DATE, CATEGORY)
SELECT
    seq                                                AS FEATURE_KEY,
    GET(ARRAY_CONSTRUCT(
        'Dashboard', 'API Gateway', 'CI/CD Pipeline', 'Code Review', 'Deployment',
        'Monitoring', 'Alerting', 'Log Search', 'Metrics Explorer', 'Tracing',
        'User Management', 'RBAC Policies', 'SSO Integration', 'API Keys', 'Webhooks',
        'Git Integration', 'PR Automation', 'Build Cache', 'Artifact Registry', 'Secret Vault',
        'Database Migrations', 'Schema Diff', 'Query Editor', 'Dataflow', 'Report Builder',
        'Notification Hub', 'Audit Log', 'Compliance Dashboard', 'Cost Explorer', 'Budget Alerts',
        'Team Workspaces', 'Project Templates', 'Sandbox Environment', 'Preview Deployments', 'Feature Flags',
        'A/B Testing', 'Analytics SDK', 'Custom Events', 'Funnel Builder', 'Cohort Analysis',
        'Slack Integration', 'Jira Integration', 'GitHub Actions', 'Terraform Provider', 'CLI Tool',
        'REST API v2', 'GraphQL API', 'SDK Python', 'SDK JavaScript', 'SDK Go'
    ), seq - 1)::VARCHAR                               AS FEATURE_NAME,
    GET(ARRAY_CONSTRUCT(
        'PLATFORM', 'PLATFORM', 'CI_CD', 'CI_CD', 'CI_CD',
        'OBSERVABILITY', 'OBSERVABILITY', 'OBSERVABILITY', 'OBSERVABILITY', 'OBSERVABILITY',
        'IAM', 'IAM', 'IAM', 'IAM', 'PLATFORM',
        'CI_CD', 'CI_CD', 'CI_CD', 'CI_CD', 'SECURITY',
        'DATA', 'DATA', 'DATA', 'DATA', 'DATA',
        'PLATFORM', 'SECURITY', 'SECURITY', 'PLATFORM', 'PLATFORM',
        'COLLABORATION', 'COLLABORATION', 'PLATFORM', 'CI_CD', 'PLATFORM',
        'ANALYTICS', 'ANALYTICS', 'ANALYTICS', 'ANALYTICS', 'ANALYTICS',
        'INTEGRATIONS', 'INTEGRATIONS', 'INTEGRATIONS', 'INTEGRATIONS', 'INTEGRATIONS',
        'API', 'API', 'SDK', 'SDK', 'SDK'
    ), seq - 1)::VARCHAR                               AS MODULE,
    DATEADD('day', -UNIFORM(60, 1800, RANDOM()), CURRENT_DATE()) AS RELEASE_DATE,
    GET(ARRAY_CONSTRUCT(
        'CORE', 'CORE', 'CORE', 'CORE', 'CORE',
        'CORE', 'CORE', 'ADVANCED', 'ADVANCED', 'ADVANCED',
        'CORE', 'ADVANCED', 'ADVANCED', 'CORE', 'CORE',
        'CORE', 'ADVANCED', 'ADVANCED', 'ADVANCED', 'ADVANCED',
        'ADVANCED', 'ADVANCED', 'CORE', 'ADVANCED', 'ADVANCED',
        'CORE', 'CORE', 'ADVANCED', 'CORE', 'ADVANCED',
        'CORE', 'CORE', 'ADVANCED', 'BETA', 'BETA',
        'BETA', 'CORE', 'CORE', 'ADVANCED', 'ADVANCED',
        'INTEGRATION', 'INTEGRATION', 'INTEGRATION', 'INTEGRATION', 'INTEGRATION',
        'CORE', 'ADVANCED', 'CORE', 'CORE', 'BETA'
    ), seq - 1)::VARCHAR                               AS CATEGORY
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- ============================================================================
-- 5. FACT_PRODUCT_USAGE (~150K, tenant x feature x day sample)
-- Power-law: 20% of tenants drive 80% usage. Weekday bias for B2B.
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.FACT_PRODUCT_USAGE
    (DATE_KEY, TENANT_KEY, USER_KEY, FEATURE_KEY, EVENTS, SESSIONS, ACTIVE_MINUTES)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    -- Power-law tenant distribution: heavy concentration on active tenants
    GREATEST(1, LEAST(2000, ROUND(EXP(NORMAL(5.0, 1.5, RANDOM())))))::INT AS TENANT_KEY,
    UNIFORM(1, 20000, RANDOM())                        AS USER_KEY,
    UNIFORM(1, 50, RANDOM())                           AS FEATURE_KEY,
    -- Events: power-law, most sessions few events, rare heavy usage spikes
    GREATEST(1, ROUND(EXP(NORMAL(2.5, 1.0, RANDOM()))
        * IFF(d.IS_BUSINESS_DAY, 1.0, 0.25)          -- B2B: low weekends
        * IFF(UNIFORM(0, 100, RANDOM()) < 1, 8.0, 1.0) -- 1% integration spikes
    ))::INT                                            AS EVENTS,
    GREATEST(1, ROUND(NORMAL(3, 2, RANDOM())
        * IFF(d.IS_BUSINESS_DAY, 1.0, 0.3)
    ))::INT                                            AS SESSIONS,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(1, ROUND(NORMAL(25, 15, RANDOM())
            * IFF(d.IS_BUSINESS_DAY, 1.0, 0.3), 2
        )))                                            AS ACTIVE_MINUTES
FROM NEXUS_SAAS.GOLD.DIM_DATE d
CROSS JOIN (SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 12))) reps
WHERE UNIFORM(0, 100, RANDOM()) < 8;

-- ============================================================================
-- 6. FACT_SUBSCRIPTION (~100K monthly snapshots)
-- Exponential MRR growth: 40% YoY early, tapering to 25%
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.FACT_SUBSCRIPTION
    (DATE_KEY, TENANT_KEY, MRR, ARR, PLAN_KEY, STATUS,
     EXPANSION_FLAG, CONTRACTION_FLAG, SEATS)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 2000, RANDOM())                         AS TENANT_KEY,
    -- MRR: exponential company growth applied per tenant
    ROUND(GREATEST(0, NORMAL(800, 600, RANDOM())
        * POWER(1.0 + (0.40 - 0.015 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)),
                 DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE))
    ), 2)                                              AS MRR,
    ROUND(GREATEST(0, NORMAL(800, 600, RANDOM())
        * POWER(1.0 + (0.40 - 0.015 * DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE)),
                 DATEDIFF('year', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE))
        * 12
    ), 2)                                              AS ARR,
    UNIFORM(1, 5, RANDOM())                            AS PLAN_KEY,
    GET(ARRAY_CONSTRUCT('ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE',
        'ACTIVE', 'ACTIVE', 'ACTIVE', 'TRIALING', 'PAST_DUE', 'CANCELED'),
        UNIFORM(0, 10, RANDOM()))::VARCHAR             AS STATUS,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, TRUE, FALSE)   AS EXPANSION_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 3, TRUE, FALSE)   AS CONTRACTION_FLAG,
    GREATEST(1, ROUND(EXP(NORMAL(1.8, 0.9, RANDOM()))))::INT AS SEATS
FROM NEXUS_SAAS.GOLD.DIM_DATE d
WHERE DAY(d.FULL_DATE) = 1  -- monthly snapshots
  AND UNIFORM(0, 100, RANDOM()) < 60;

-- ============================================================================
-- 7. FACT_BILLING (monthly per tenant)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.FACT_BILLING
    (DATE_KEY, TENANT_KEY, INVOICED_AMOUNT, COLLECTED_AMOUNT,
     USAGE_CHARGES, OVERAGE_AMOUNT, DISCOUNT_AMOUNT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 2000, RANDOM())                         AS TENANT_KEY,
    -- Invoiced: log-normal with growth
    ROUND(EXP(NORMAL(6.5, 1.2, RANDOM()))
        * POWER(1.03, DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12.0), 2) AS INVOICED_AMOUNT,
    -- Collected: 92-98% of invoiced, occasionally disputed
    ROUND(EXP(NORMAL(6.5, 1.2, RANDOM()))
        * POWER(1.03, DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12.0)
        * IFF(UNIFORM(0, 100, RANDOM()) < 5, UNIFORM(60, 85, RANDOM()) / 100.0, UNIFORM(92, 100, RANDOM()) / 100.0), 2) AS COLLECTED_AMOUNT,
    -- Usage charges: metered overage
    IFF(UNIFORM(0, 100, RANDOM()) < 35,
        ROUND(EXP(NORMAL(4.5, 1.0, RANDOM())), 2), 0) AS USAGE_CHARGES,
    IFF(UNIFORM(0, 100, RANDOM()) < 15,
        ROUND(EXP(NORMAL(4.0, 0.8, RANDOM())), 2), 0) AS OVERAGE_AMOUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 20,
        ROUND(EXP(NORMAL(4.0, 1.0, RANDOM())), 2), 0) AS DISCOUNT_AMOUNT
FROM NEXUS_SAAS.GOLD.DIM_DATE d
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 55;

-- ============================================================================
-- 8. FACT_SUPPORT (monthly per tenant)
-- Tickets correlate with growth + new feature releases
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.FACT_SUPPORT
    (DATE_KEY, TENANT_KEY, CASES_OPENED, CASES_CLOSED, AVG_RESOLUTION_HOURS,
     CSAT_AVG, ESCALATIONS, P1_INCIDENTS)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 2000, RANDOM())                         AS TENANT_KEY,
    -- Cases: grow with company size, spike after releases
    GREATEST(0, ROUND(NORMAL(3, 2.5, RANDOM())
        * POWER(1.02, DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12.0)
        * IFF(UNIFORM(0, 100, RANDOM()) < 10, 2.5, 1.0) -- post-release spikes
    ))::INT                                            AS CASES_OPENED,
    GREATEST(0, ROUND(NORMAL(2.8, 2.3, RANDOM())
        * POWER(1.02, DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12.0)
    ))::INT                                            AS CASES_CLOSED,
    -- Resolution hours: log-normal, P1s fast, P4s slow
    IFF(UNIFORM(0, 100, RANDOM()) < 1, NULL,
        GREATEST(0.5, ROUND(EXP(NORMAL(3.0, 0.8, RANDOM())), 2))) AS AVG_RESOLUTION_HOURS,
    -- CSAT: centered at 4.2/5.0
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(1.0, LEAST(5.0, ROUND(NORMAL(4.2, 0.5, RANDOM()), 1)))) AS CSAT_AVG,
    IFF(UNIFORM(0, 100, RANDOM()) < 12,
        GREATEST(1, ROUND(NORMAL(1.2, 0.5, RANDOM())))::INT, 0) AS ESCALATIONS,
    IFF(UNIFORM(0, 100, RANDOM()) < 5,
        GREATEST(1, ROUND(NORMAL(1, 0.5, RANDOM())))::INT, 0) AS P1_INCIDENTS
FROM NEXUS_SAAS.GOLD.DIM_DATE d
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 50;

-- ============================================================================
-- 9. FACT_INFRASTRUCTURE (daily per tenant sample)
-- Cost grows sub-linearly with usage (economies of scale)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.FACT_INFRASTRUCTURE
    (DATE_KEY, TENANT_KEY, COMPUTE_CREDITS, STORAGE_TB, QUERIES,
     AVG_LATENCY_MS, ERROR_RATE_PCT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    GREATEST(1, LEAST(2000, ROUND(EXP(NORMAL(5.0, 1.5, RANDOM())))))::INT AS TENANT_KEY,
    -- Compute: sub-linear growth with usage (economies of scale)
    GREATEST(0.01, ROUND(EXP(NORMAL(1.5, 1.2, RANDOM()))
        * POWER(1.02, DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12.0)
        * IFF(d.IS_BUSINESS_DAY, 1.0, 0.4), 4
    ))                                                 AS COMPUTE_CREDITS,
    -- Storage: steadily grows (data accumulates)
    GREATEST(0.001, ROUND(EXP(NORMAL(-1.0, 1.5, RANDOM()))
        * POWER(1.04, DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12.0), 4
    ))                                                 AS STORAGE_TB,
    GREATEST(1, ROUND(EXP(NORMAL(4.5, 1.3, RANDOM()))
        * IFF(d.IS_BUSINESS_DAY, 1.0, 0.3)
    ))::INT                                            AS QUERIES,
    -- Latency: mostly low, occasional degradation
    GREATEST(5, ROUND(NORMAL(45, 20, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 3.0, 1.0), 2)) AS AVG_LATENCY_MS,
    -- Error rate: mostly <1%, rare spikes
    IFF(UNIFORM(0, 100, RANDOM()) < 1, NULL,
        LEAST(5.0, GREATEST(0.0, ROUND(NORMAL(0.3, 0.2, RANDOM())
            * IFF(UNIFORM(0, 100, RANDOM()) < 2, 5.0, 1.0), 4
        ))))                                           AS ERROR_RATE_PCT
FROM NEXUS_SAAS.GOLD.DIM_DATE d
CROSS JOIN (SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 3))) reps
WHERE UNIFORM(0, 100, RANDOM()) < 5;

-- ============================================================================
-- 10. AGG_TENANT_HEALTH (monthly composite score)
-- Multi-signal: usage + payment + support. Predicts churn 60 days out.
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.AGG_TENANT_HEALTH
    (MONTH_KEY, TENANT_KEY, PRODUCT_USAGE_SCORE, SUPPORT_SCORE, PAYMENT_SCORE,
     EXPANSION_SIGNAL, CHURN_RISK_SCORE, HEALTH_TIER, RECOMMENDED_ACTION)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    UNIFORM(1, 2000, RANDOM())                         AS TENANT_KEY,
    -- Usage score: 0-10 scale
    GREATEST(1, LEAST(10, ROUND(NORMAL(6.5, 2.0, RANDOM()), 2))) AS PRODUCT_USAGE_SCORE,
    -- Support score: higher is better (fewer issues)
    GREATEST(1, LEAST(10, ROUND(NORMAL(7.5, 1.5, RANDOM()), 2))) AS SUPPORT_SCORE,
    -- Payment score: mostly healthy
    GREATEST(1, LEAST(10, ROUND(NORMAL(8.5, 1.5, RANDOM()), 2))) AS PAYMENT_SCORE,
    -- Expansion signal: likelihood of upsell
    LEAST(1.0, GREATEST(0.0, ROUND(NORMAL(0.25, 0.15, RANDOM()), 4))) AS EXPANSION_SIGNAL,
    -- Churn risk: 3-5% logo churn monthly
    LEAST(1.0, GREATEST(0.01, ROUND(
        IFF(UNIFORM(0, 100, RANDOM()) < 5,
            NORMAL(0.7, 0.15, RANDOM()),  -- at-risk tenants
            NORMAL(0.08, 0.06, RANDOM())  -- healthy tenants
        ), 4
    )))                                                AS CHURN_RISK_SCORE,
    CASE
        WHEN NORMAL(0.08, 0.06, RANDOM()) > 0.30 THEN 'RED'
        WHEN NORMAL(0.08, 0.06, RANDOM()) > 0.12 THEN 'YELLOW'
        ELSE 'GREEN'
    END                                                AS HEALTH_TIER,
    GET(ARRAY_CONSTRUCT('NO_ACTION', 'NO_ACTION', 'NO_ACTION', 'EXECUTIVE_REVIEW',
        'CSM_OUTREACH', 'UPSELL_CAMPAIGN', 'RENEWAL_PREP', 'USAGE_TRAINING',
        'ONBOARDING_FOLLOWUP'),
        UNIFORM(0, 8, RANDOM()))::VARCHAR              AS RECOMMENDED_ACTION
FROM NEXUS_SAAS.GOLD.DIM_DATE d
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 55;

-- ============================================================================
-- 11. AGG_COHORT_METRICS (monthly cohort retention)
-- Net retention 110-120% (expansion offsets logo churn)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.AGG_COHORT_METRICS
    (COHORT_MONTH_KEY, MONTHS_SINCE_SIGNUP, ACTIVE_TENANTS, CHURNED_TENANTS,
     NET_RETENTION_PCT, EXPANSION_PCT, GROSS_RETENTION_PCT, AVG_ARR)
SELECT
    d.DATE_KEY                                         AS COHORT_MONTH_KEY,
    months_elapsed                                     AS MONTHS_SINCE_SIGNUP,
    -- Active: cohort decay curve (3-5% monthly logo churn)
    GREATEST(1, ROUND(
        UNIFORM(50, 200, RANDOM())
        * POWER(0.96, months_elapsed)                  -- 4% monthly logo churn
    ))::INT                                            AS ACTIVE_TENANTS,
    GREATEST(0, ROUND(
        UNIFORM(50, 200, RANDOM())
        * (1 - POWER(0.96, months_elapsed))
        * 0.8
    ))::INT                                            AS CHURNED_TENANTS,
    -- Net retention: >100% because expansion exceeds contraction
    GREATEST(0.85, LEAST(1.50, ROUND(
        NORMAL(1.15, 0.05, RANDOM())
        * IFF(months_elapsed < 6, 1.05, 1.0)          -- early cohorts expand faster
    , 4)))                                             AS NET_RETENTION_PCT,
    -- Expansion: 8-15% of ARR monthly from upsells
    GREATEST(0.02, LEAST(0.25, ROUND(NORMAL(0.10, 0.03, RANDOM()), 4))) AS EXPANSION_PCT,
    -- Gross retention: 95-97% (logo churn only)
    GREATEST(0.88, LEAST(1.0, ROUND(NORMAL(0.96, 0.02, RANDOM()), 4))) AS GROSS_RETENTION_PCT,
    -- Avg ARR: grows over time per cohort (expansion)
    ROUND(GREATEST(1000, EXP(NORMAL(9.5, 0.8, RANDOM()))
        * POWER(1.08, months_elapsed / 12.0)), 2)     AS AVG_ARR
FROM NEXUS_SAAS.GOLD.DIM_DATE d
CROSS JOIN (SELECT SEQ4() AS months_elapsed FROM TABLE(GENERATOR(ROWCOUNT => 36))) months
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 8;

-- ============================================================================
-- 12. AGG_FEATURE_ADOPTION (monthly per feature)
-- ============================================================================
INSERT INTO NEXUS_SAAS.GOLD.AGG_FEATURE_ADOPTION
    (MONTH_KEY, FEATURE_KEY, TENANTS_USING, USERS_USING, ADOPTION_PCT,
     STICKINESS_PCT, AVG_EVENTS_PER_USER)
SELECT
    d.DATE_KEY                                         AS MONTH_KEY,
    f.FEATURE_KEY                                      AS FEATURE_KEY,
    -- Tenants using: S-curve adoption from release date
    GREATEST(1, ROUND(
        (1200.0 / (1.0 + EXP(-0.08 * DATEDIFF('month', f.RELEASE_DATE, d.FULL_DATE))))
        * IFF(f.CATEGORY = 'CORE', 1.2, IFF(f.CATEGORY = 'BETA', 0.4, 0.8))
        * (1 + NORMAL(0, 0.1, RANDOM()))
    ))::INT                                            AS TENANTS_USING,
    GREATEST(1, ROUND(
        (8000.0 / (1.0 + EXP(-0.06 * DATEDIFF('month', f.RELEASE_DATE, d.FULL_DATE))))
        * IFF(f.CATEGORY = 'CORE', 1.3, IFF(f.CATEGORY = 'BETA', 0.3, 0.7))
        * (1 + NORMAL(0, 0.15, RANDOM()))
    ))::INT                                            AS USERS_USING,
    -- Adoption %: of total tenants
    IFF(UNIFORM(0, 100, RANDOM()) < 1, NULL,
        GREATEST(0.01, LEAST(0.95, ROUND(
            (0.6 / (1.0 + EXP(-0.1 * DATEDIFF('month', f.RELEASE_DATE, d.FULL_DATE))))
            * IFF(f.CATEGORY = 'CORE', 1.4, IFF(f.CATEGORY = 'BETA', 0.4, 0.8)), 4
        ))))                                           AS ADOPTION_PCT,
    -- Stickiness (DAU/MAU): higher for core features
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0.05, LEAST(0.70, ROUND(
            NORMAL(0.30, 0.12, RANDOM())
            * IFF(f.CATEGORY = 'CORE', 1.3, 0.8), 4
        ))))                                           AS STICKINESS_PCT,
    -- Avg events per user
    GREATEST(1, ROUND(EXP(NORMAL(2.5, 0.8, RANDOM()))
        * IFF(f.CATEGORY = 'CORE', 1.2, 0.7), 2
    ))                                                 AS AVG_EVENTS_PER_USER
FROM NEXUS_SAAS.GOLD.DIM_DATE d
CROSS JOIN NEXUS_SAAS.GOLD.DIM_FEATURE f
WHERE DAY(d.FULL_DATE) = 1
  AND d.FULL_DATE >= f.RELEASE_DATE
  AND UNIFORM(0, 100, RANDOM()) < 60;
