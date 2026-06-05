-- ============================================================================
-- MEDIA & ENTERTAINMENT VERTICAL - Synthetic Data Generation
-- Entity: Nova Media Group
-- Prerequisites: Run media-entertainment-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- Patterns: Evening peak (7-11pm), weekend binge, new content spikes,
--           holiday streaming surges, power-law user engagement
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE NOVA_MEDIA.GOLD.AGG_DAU_MAU;
TRUNCATE TABLE NOVA_MEDIA.GOLD.AGG_COHORT_RETENTION;
TRUNCATE TABLE NOVA_MEDIA.GOLD.AGG_CONTENT_DAILY;
TRUNCATE TABLE NOVA_MEDIA.GOLD.FACT_ENGAGEMENT;
TRUNCATE TABLE NOVA_MEDIA.GOLD.FACT_QOE;
TRUNCATE TABLE NOVA_MEDIA.GOLD.FACT_AD_REVENUE;
TRUNCATE TABLE NOVA_MEDIA.GOLD.FACT_SUBSCRIPTION;
TRUNCATE TABLE NOVA_MEDIA.GOLD.FACT_VIEWING;
TRUNCATE TABLE NOVA_MEDIA.GOLD.DIM_DATE;
TRUNCATE TABLE NOVA_MEDIA.GOLD.DIM_PLAN;
TRUNCATE TABLE NOVA_MEDIA.GOLD.DIM_CONTENT;
TRUNCATE TABLE NOVA_MEDIA.GOLD.DIM_USER;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN TRUE ELSE FALSE END AS IS_WEEKEND,
    -- Release day: Fridays (streaming industry standard)
    CASE WHEN DAYOFWEEK(d) = 5 THEN TRUE ELSE FALSE END AS IS_RELEASE_DAY
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_USER (~100,000 subscriber profiles)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.DIM_USER
    (USER_KEY, USER_ID, EMAIL_DOMAIN, AGE_GROUP, GENDER, COUNTRY, STATE,
     PREFERRED_LANGUAGE, ACQUISITION_CHANNEL, SIGNUP_DATE, COHORT_MONTH,
     TENURE_DAYS, HOUSEHOLD_SIZE, _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS USER_KEY,
    'USR-' || LPAD(seq::VARCHAR, 8, '0')               AS USER_ID,
    GET(ARRAY_CONSTRUCT('gmail.com', 'gmail.com', 'gmail.com', 'yahoo.com', 'yahoo.com',
        'outlook.com', 'icloud.com', 'hotmail.com', 'aol.com', 'protonmail.com'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS EMAIL_DOMAIN,
    GET(ARRAY_CONSTRUCT('18-24', '18-24', '25-34', '25-34', '25-34', '35-44', '35-44',
        '45-54', '55-64', '65+'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS AGE_GROUP,
    GET(ARRAY_CONSTRUCT('M', 'F', 'M', 'F', 'NB', NULL),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS GENDER,
    'US'                                               AS COUNTRY,
    GET(ARRAY_CONSTRUCT('CA', 'TX', 'NY', 'FL', 'IL', 'PA', 'OH', 'GA', 'NC', 'MI',
        'NJ', 'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'CO'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS STATE,
    GET(ARRAY_CONSTRUCT('en', 'en', 'en', 'en', 'es', 'es', NULL),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS PREFERRED_LANGUAGE,
    GET(ARRAY_CONSTRUCT('ORGANIC', 'ORGANIC', 'PAID_SOCIAL', 'PAID_SOCIAL', 'DISPLAY',
        'REFERRAL', 'BUNDLE_PARTNER', 'BUNDLE_PARTNER'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS ACQUISITION_CHANNEL,
    DATEADD('day', -UNIFORM(30, 1800, RANDOM()), CURRENT_DATE()) AS SIGNUP_DATE,
    DATE_TRUNC('month', DATEADD('day', -UNIFORM(30, 1800, RANDOM()), CURRENT_DATE())) AS COHORT_MONTH,
    UNIFORM(30, 1800, RANDOM())                        AS TENURE_DAYS,
    UNIFORM(1, 6, RANDOM())                            AS HOUSEHOLD_SIZE,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100000)));

-- ============================================================================
-- 3. DIM_CONTENT (~5,000 titles)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.DIM_CONTENT
    (CONTENT_KEY, CONTENT_ID, TITLE, SERIES_NAME, SEASON, EPISODE, GENRE,
     CONTENT_TYPE, DURATION_MINUTES, RATING, RELEASE_DATE, LANGUAGE,
     IS_ORIGINAL, PRODUCTION_COST)
SELECT
    seq                                                AS CONTENT_KEY,
    'CNT-' || LPAD(seq::VARCHAR, 6, '0')               AS CONTENT_ID,
    GET(ARRAY_CONSTRUCT('The Last Frontier', 'Digital Dreams', 'Midnight Detective', 'Ocean Secrets',
        'City Lights', 'Wild Kingdom', 'Quantum Shift', 'Hidden Truths', 'Blazing Trail',
        'Infinite Loop', 'Cold Case Files', 'Planet Unknown', 'The Reckoning',
        'Beyond the Wall', 'Starfall', 'Urban Myths', 'Deep Dive', 'Golden Age',
        'Shadow Games', 'Untold Stories'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR || ' (' || seq::VARCHAR || ')' AS TITLE,
    IFF(UNIFORM(0, 100, RANDOM()) < 60,
        GET(ARRAY_CONSTRUCT('The Last Frontier', 'Digital Dreams', 'Midnight Detective',
            'Ocean Secrets', 'City Lights', 'Wild Kingdom', 'Quantum Shift',
            'Hidden Truths', 'Cold Case Files', 'Planet Unknown'),
            UNIFORM(0, 9, RANDOM()))::VARCHAR, NULL)   AS SERIES_NAME,
    IFF(UNIFORM(0, 100, RANDOM()) < 60, UNIFORM(1, 8, RANDOM()), NULL) AS SEASON,
    IFF(UNIFORM(0, 100, RANDOM()) < 60, UNIFORM(1, 13, RANDOM()), NULL) AS EPISODE,
    GET(ARRAY_CONSTRUCT('DRAMA', 'DRAMA', 'COMEDY', 'COMEDY', 'DOCUMENTARY',
        'ACTION', 'HORROR', 'KIDS', 'SCI_FI', 'THRILLER'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS GENRE,
    GET(ARRAY_CONSTRUCT('EPISODE', 'EPISODE', 'EPISODE', 'MOVIE', 'MOVIE', 'SHORT',
        'DOCUMENTARY', 'LIVE_EVENT'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS CONTENT_TYPE,
    CASE
        WHEN UNIFORM(0, 7, RANDOM()) < 3 THEN UNIFORM(22, 65, RANDOM())   -- episodes
        WHEN UNIFORM(0, 7, RANDOM()) < 5 THEN UNIFORM(80, 180, RANDOM())  -- movies
        ELSE UNIFORM(5, 20, RANDOM())                                       -- shorts
    END                                                AS DURATION_MINUTES,
    GET(ARRAY_CONSTRUCT('TV-MA', 'TV-14', 'TV-PG', 'TV-G', 'R', 'PG-13', 'PG'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS RATING,
    DATEADD('day', -UNIFORM(0, 1800, RANDOM()), CURRENT_DATE()) AS RELEASE_DATE,
    GET(ARRAY_CONSTRUCT('en', 'en', 'en', 'en', 'es', 'ko', 'ja'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS LANGUAGE,
    IFF(UNIFORM(0, 100, RANDOM()) < 35, TRUE, FALSE)  AS IS_ORIGINAL,
    -- Production cost: log-normal (episodes cheaper, originals expensive)
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        ROUND(EXP(NORMAL(13.5, 1.8, RANDOM()))
            * IFF(UNIFORM(0, 100, RANDOM()) < 35, 2.0, 1.0), 2)) AS PRODUCTION_COST
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 5000)));

-- ============================================================================
-- 4. DIM_PLAN (6 subscription plans)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.DIM_PLAN
    (PLAN_KEY, PLAN_ID, PLAN_NAME, MONTHLY_PRICE, TIER, AD_SUPPORTED_FLAG,
     MAX_STREAMS, MAX_RESOLUTION, LAUNCH_DATE, RETIRE_DATE)
SELECT column1, column2, column3, column4, column5, column6, column7, column8, column9, column10 FROM VALUES
    (1, 'PLAN_FREE',     'Nova Free Trial',        0.00, 'TRIAL',    TRUE,  1, 'HD',  '2019-01-01'::DATE, NULL),
    (2, 'PLAN_AD_BASIC', 'Nova with Ads',          6.99, 'BASIC',    TRUE,  1, 'HD',  '2020-06-01'::DATE, NULL),
    (3, 'PLAN_STANDARD', 'Nova Standard',         12.99, 'STANDARD', FALSE, 2, 'HD',  '2019-01-01'::DATE, NULL),
    (4, 'PLAN_PREMIUM',  'Nova Premium',          19.99, 'PREMIUM',  FALSE, 4, '4K',  '2019-01-01'::DATE, NULL),
    (5, 'PLAN_FAMILY',   'Nova Family',           24.99, 'PREMIUM',  FALSE, 5, '4K',  '2021-03-01'::DATE, NULL),
    (6, 'PLAN_ANNUAL',   'Nova Annual Premium',  179.99, 'PREMIUM',  FALSE, 4, '4K',  '2022-01-01'::DATE, NULL);

-- ============================================================================
-- 5. FACT_VIEWING (~150,000 rows: user × content × day sample)
-- Evening peak (7-11pm), weekend binge, new content spike then decay
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.FACT_VIEWING
    (DATE_KEY, USER_KEY, CONTENT_KEY, WATCH_TIME_MINUTES, COMPLETION_PCT,
     DEVICE_TYPE, PLATFORM, SESSIONS, BINGE_FLAG)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 100000, RANDOM())                       AS USER_KEY,
    UNIFORM(1, 5000, RANDOM())                         AS CONTENT_KEY,
    -- Watch time: power-law (few heavy users, long tail of light users)
    GREATEST(5, ROUND(EXP(NORMAL(3.5, 1.0, RANDOM()))
        * IFF(d.IS_WEEKEND, 1.5, 1.0)                  -- weekend binge
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12, 1) THEN 0.30 ELSE 0 END) -- holiday season
        * IFF(UNIFORM(0, 100, RANDOM()) < 5, 3.0, 1.0) -- 5% heavy binge sessions
        * IFF(UNIFORM(0, 1000, RANDOM()) < 3, 0.1, 1.0) -- 0.3% bot traffic anomaly
    ))::INT                                            AS WATCH_TIME_MINUTES,
    -- Completion: most finish, some abandon early
    LEAST(100, GREATEST(5, ROUND(
        CASE
            WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN NORMAL(92, 8, RANDOM())   -- completers
            WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN NORMAL(55, 20, RANDOM())  -- partial
            ELSE NORMAL(15, 10, RANDOM())                                        -- samplers
        END, 2)))                                      AS COMPLETION_PCT,
    GET(ARRAY_CONSTRUCT('SMART_TV', 'SMART_TV', 'MOBILE', 'MOBILE', 'DESKTOP', 'TABLET', 'GAME_CONSOLE'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS DEVICE_TYPE,
    GET(ARRAY_CONSTRUCT('IOS', 'ANDROID', 'WEB', 'ROKU', 'FIRE_TV', 'APPLE_TV'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS PLATFORM,
    GREATEST(1, ROUND(NORMAL(2.5, 1.5, RANDOM())))::INT AS SESSIONS,
    -- Binge: 3+ episodes same series in session, higher on weekends
    IFF(UNIFORM(0, 100, RANDOM()) < IFF(d.IS_WEEKEND, 25, 12), TRUE, FALSE) AS BINGE_FLAG
FROM NOVA_MEDIA.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    12
    + CASE WHEN d.IS_WEEKEND THEN 8 ELSE 0 END
    + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12, 1) THEN 5 ELSE 0 END -- holiday binge
    + CASE WHEN d.IS_RELEASE_DAY THEN 3 ELSE 0 END                   -- new content Fridays
);

-- ============================================================================
-- 6. FACT_SUBSCRIPTION (daily snapshots for active users, sampled)
-- Growth 20% YoY, 4-6% monthly churn, seasonal sign-ups (holidays)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.FACT_SUBSCRIPTION
    (DATE_KEY, USER_KEY, PLAN_KEY, MRR, STATUS, TENURE_DAYS,
     TRIAL_FLAG, DOWNGRADE_FLAG, UPGRADE_FLAG)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    usr                                                AS USER_KEY,
    UNIFORM(2, 6, RANDOM())                            AS PLAN_KEY,  -- skip trial for active subs
    -- MRR based on plan mix
    GET(ARRAY_CONSTRUCT(6.99, 12.99, 12.99, 19.99, 24.99, 15.00),
        UNIFORM(0, 5, RANDOM()))                       AS MRR,
    -- Status: mostly active
    GET(ARRAY_CONSTRUCT('ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE',
        'ACTIVE', 'CANCELED', 'PAST_DUE', 'PAUSED'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS STATUS,
    UNIFORM(1, 1500, RANDOM())                         AS TENURE_DAYS,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, TRUE, FALSE)   AS TRIAL_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 3, TRUE, FALSE)   AS DOWNGRADE_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, TRUE, FALSE)   AS UPGRADE_FLAG
FROM NOVA_MEDIA.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 100000, RANDOM()) AS usr FROM TABLE(GENERATOR(ROWCOUNT => 10))) users
WHERE DAY(d.FULL_DATE) = 1  -- monthly snapshot
  AND UNIFORM(0, 100, RANDOM()) < (
      30
      + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12) THEN 10 ELSE 0 END  -- holiday sign-ups
      + CASE WHEN MONTH(d.FULL_DATE) = 1 THEN 8 ELSE 0 END           -- new year resolutions
  );

-- ============================================================================
-- 7. FACT_AD_REVENUE (daily per content, ad-tier users)
-- CPM varies by genre, fill rate ~85%, weekday higher
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.FACT_AD_REVENUE
    (DATE_KEY, USER_KEY, CONTENT_KEY, IMPRESSIONS, CLICKS, COMPLETIONS,
     REVENUE, FILL_RATE, AVG_CPM)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 100000, RANDOM())                       AS USER_KEY,
    UNIFORM(1, 5000, RANDOM())                         AS CONTENT_KEY,
    GREATEST(1, ROUND(NORMAL(8, 4, RANDOM())))::INT    AS IMPRESSIONS,
    GREATEST(0, ROUND(NORMAL(0.5, 0.4, RANDOM())))::INT AS CLICKS,
    GREATEST(0, ROUND(NORMAL(5, 3, RANDOM())))::INT    AS COMPLETIONS,
    -- Revenue: CPM varies, weekdays higher (advertiser demand)
    ROUND(GREATEST(0.01,
        NORMAL(0.08, 0.04, RANDOM())
        * IFF(d.IS_WEEKEND, 0.75, 1.0)                 -- weekday higher CPM
        * (1.0 + 0.05 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 12) -- CPM growth
        * IFF(MONTH(d.FULL_DATE) IN (11, 12), 1.4, 1.0)  -- holiday advertiser spend
    ), 2)                                              AS REVENUE,
    -- Fill rate: ~85% average
    LEAST(1.0, GREATEST(0.50, ROUND(NORMAL(0.85, 0.08, RANDOM()), 4))) AS FILL_RATE,
    -- CPM: varies by content genre (drama/action higher)
    ROUND(GREATEST(2.0, NORMAL(15, 6, RANDOM())
        * IFF(d.IS_WEEKEND, 0.80, 1.0)
        * IFF(MONTH(d.FULL_DATE) IN (11, 12), 1.35, 1.0)
    ), 4)                                              AS AVG_CPM
FROM NOVA_MEDIA.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < 15; -- ~30% of ad-tier users daily

-- ============================================================================
-- 8. FACT_QOE (daily per content/device/CDN)
-- Mostly good, CDN-correlated degradation
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.FACT_QOE
    (DATE_KEY, CONTENT_KEY, DEVICE_TYPE, CDN_PROVIDER, AVG_BITRATE_KBPS,
     BUFFER_RATIO, STARTUP_TIME_P50_MS, STARTUP_TIME_P95_MS,
     ERROR_RATE, SESSIONS, EXITS_BEFORE_START)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 5000, RANDOM())                         AS CONTENT_KEY,
    GET(ARRAY_CONSTRUCT('SMART_TV', 'MOBILE', 'DESKTOP', 'TABLET', 'GAME_CONSOLE'),
        UNIFORM(0, 4, RANDOM()))::VARCHAR              AS DEVICE_TYPE,
    GET(ARRAY_CONSTRUCT('CLOUDFRONT', 'AKAMAI', 'FASTLY'),
        UNIFORM(0, 2, RANDOM()))::VARCHAR              AS CDN_PROVIDER,
    -- Bitrate: mostly high, some degradation events
    GREATEST(500, ROUND(NORMAL(5500, 1200, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 0.4, 1.0) -- 3% CDN degradation
    ))::INT                                            AS AVG_BITRATE_KBPS,
    -- Buffer ratio: mostly near zero, occasional spikes
    LEAST(0.20, GREATEST(0, ROUND(NORMAL(0.008, 0.005, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 8.0, 1.0)
    , 4)))                                             AS BUFFER_RATIO,
    -- Startup time P50: 1-3 seconds
    GREATEST(500, ROUND(NORMAL(1800, 500, RANDOM())))::INT AS STARTUP_TIME_P50_MS,
    -- Startup time P95: 3-8 seconds
    GREATEST(2000, ROUND(NORMAL(4500, 1500, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 2.0, 1.0)
    ))::INT                                            AS STARTUP_TIME_P95_MS,
    -- Error rate: mostly near zero
    LEAST(0.05, GREATEST(0, ROUND(NORMAL(0.003, 0.002, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 1, 10.0, 1.0)
    , 4)))                                             AS ERROR_RATE,
    GREATEST(10, ROUND(NORMAL(500, 250, RANDOM())))::INT AS SESSIONS,
    -- Exits before start: correlated with startup time issues
    GREATEST(0, ROUND(NORMAL(3, 3, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 5.0, 1.0)
    ))::INT                                            AS EXITS_BEFORE_START
FROM NOVA_MEDIA.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < 20;

-- ============================================================================
-- 9. FACT_ENGAGEMENT (daily per user sample)
-- Power-law: few heavy users, long tail of light users
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.FACT_ENGAGEMENT
    (DATE_KEY, USER_KEY, SESSIONS, SEARCH_COUNT, WATCHLIST_ADDS,
     SHARES, RATINGS_GIVEN, PROFILES_SWITCHED, TOTAL_TIME_MINUTES)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 100000, RANDOM())                       AS USER_KEY,
    -- Sessions: power-law distribution
    GREATEST(1, ROUND(EXP(NORMAL(0.8, 0.6, RANDOM()))))::INT AS SESSIONS,
    GREATEST(0, ROUND(NORMAL(1.5, 1.2, RANDOM())))::INT AS SEARCH_COUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 15, UNIFORM(1, 3, RANDOM()), 0) AS WATCHLIST_ADDS,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, UNIFORM(1, 2, RANDOM()), 0) AS SHARES,
    IFF(UNIFORM(0, 100, RANDOM()) < 10, UNIFORM(1, 5, RANDOM()), 0) AS RATINGS_GIVEN,
    IFF(UNIFORM(0, 100, RANDOM()) < 20, UNIFORM(1, 3, RANDOM()), 0) AS PROFILES_SWITCHED,
    -- Total time: power-law, evening/weekend heavy
    GREATEST(5, ROUND(EXP(NORMAL(3.2, 1.0, RANDOM()))
        * IFF(d.IS_WEEKEND, 1.6, 1.0)
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12, 1) THEN 0.25 ELSE 0 END)
    ))::INT                                            AS TOTAL_TIME_MINUTES
FROM NOVA_MEDIA.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < 12;

-- ============================================================================
-- 10. AGG_CONTENT_DAILY (content performance)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.AGG_CONTENT_DAILY
    (DATE_KEY, CONTENT_KEY, UNIQUE_VIEWERS, TOTAL_WATCH_HOURS,
     COMPLETION_RATE, AVG_RATING, SEARCH_IMPRESSIONS, COST_PER_VIEW_HOUR)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    cnt                                                AS CONTENT_KEY,
    -- Unique viewers: power-law, new content spikes
    GREATEST(1, ROUND(EXP(NORMAL(5.5, 1.8, RANDOM()))
        * IFF(d.IS_WEEKEND, 1.3, 1.0)
        * IFF(d.IS_RELEASE_DAY, 2.5, 1.0) -- new release spike
    ))::INT                                            AS UNIQUE_VIEWERS,
    -- Watch hours: proportional to viewers
    ROUND(GREATEST(0.5, EXP(NORMAL(3.5, 1.5, RANDOM()))
        * IFF(d.IS_WEEKEND, 1.4, 1.0)
    ), 2)                                              AS TOTAL_WATCH_HOURS,
    LEAST(1.0, GREATEST(0.20, ROUND(NORMAL(0.72, 0.15, RANDOM()), 4))) AS COMPLETION_RATE,
    IFF(UNIFORM(0, 100, RANDOM()) < 3, NULL,
        LEAST(5.0, GREATEST(1.0, ROUND(NORMAL(3.8, 0.7, RANDOM()), 1)))) AS AVG_RATING,
    GREATEST(0, ROUND(NORMAL(50, 40, RANDOM())))::INT  AS SEARCH_IMPRESSIONS,
    -- Cost per view hour: originals expensive, licensed cheaper
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        ROUND(GREATEST(0.10, NORMAL(2.5, 1.5, RANDOM())), 4)) AS COST_PER_VIEW_HOUR
FROM NOVA_MEDIA.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 5000, RANDOM()) AS cnt FROM TABLE(GENERATOR(ROWCOUNT => 5))) contents
WHERE UNIFORM(0, 100, RANDOM()) < 20;

-- ============================================================================
-- 11. AGG_COHORT_RETENTION (monthly cohort curves)
-- Higher churn months 2-3 after trial, lower for annual plans
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.AGG_COHORT_RETENTION
    (COHORT_MONTH_KEY, MONTHS_SINCE_SIGNUP, PLAN_TIER, ACTIVE_USERS,
     CHURNED_USERS, RETENTION_PCT, AVG_WATCH_HOURS, REVENUE_RETAINED)
SELECT
    cohort_d.DATE_KEY                                   AS COHORT_MONTH_KEY,
    months_since                                        AS MONTHS_SINCE_SIGNUP,
    tier                                                AS PLAN_TIER,
    -- Active users: decay curve (steeper early, flattens)
    GREATEST(10, ROUND(
        5000 * EXP(-0.05 * months_since)               -- exponential decay
        * CASE tier
            WHEN 'PREMIUM' THEN 1.2                     -- premium retains better
            WHEN 'BASIC' THEN 0.8                       -- basic churns more
            ELSE 1.0
          END
        * (1.0 - IFF(months_since BETWEEN 2 AND 3, 0.15, 0)) -- trial cliff
        + NORMAL(0, 50, RANDOM())
    ))::INT                                            AS ACTIVE_USERS,
    -- Churned: inverse of retention
    GREATEST(0, ROUND(
        5000 * 0.05 * EXP(-0.03 * months_since)
        * (1.0 + IFF(months_since BETWEEN 2 AND 3, 0.50, 0))
        + NORMAL(0, 20, RANDOM())
    ))::INT                                            AS CHURNED_USERS,
    -- Retention %: decay curve
    LEAST(1.0, GREATEST(0.10, ROUND(
        EXP(-0.045 * months_since)
        * CASE tier
            WHEN 'PREMIUM' THEN 1.05
            WHEN 'BASIC' THEN 0.92
            ELSE 1.0
          END
        * (1.0 - IFF(months_since BETWEEN 2 AND 3, 0.08, 0))
    , 4)))                                             AS RETENTION_PCT,
    -- Watch hours: engaged users watch more, decliners watch less
    ROUND(GREATEST(2, NORMAL(25, 10, RANDOM())
        * EXP(-0.02 * months_since)
    ), 2)                                              AS AVG_WATCH_HOURS,
    ROUND(GREATEST(100,
        5000 * EXP(-0.05 * months_since) * 14.0       -- ~$14 avg MRR
        + NORMAL(0, 500, RANDOM())
    ), 2)                                              AS REVENUE_RETAINED
FROM (
    SELECT DATE_KEY, FULL_DATE
    FROM NOVA_MEDIA.GOLD.DIM_DATE
    WHERE DAY(FULL_DATE) = 1
) cohort_d
CROSS JOIN (SELECT SEQ4() AS months_since FROM TABLE(GENERATOR(ROWCOUNT => 24))) months
CROSS JOIN (SELECT column1 AS tier FROM VALUES ('BASIC'), ('STANDARD'), ('PREMIUM')) tiers
WHERE DATEADD('month', months_since, cohort_d.FULL_DATE) < CURRENT_DATE()
  AND UNIFORM(0, 100, RANDOM()) < 50;

-- ============================================================================
-- 12. AGG_DAU_MAU (daily platform metrics)
-- ============================================================================
INSERT INTO NOVA_MEDIA.GOLD.AGG_DAU_MAU
    (DATE_KEY, PLAN_TIER, DAU, WAU, MAU, DAU_MAU_RATIO,
     AVG_SESSION_MINUTES, SESSIONS_PER_USER)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    tier                                               AS PLAN_TIER,
    -- DAU: seasonal, weekend spikes, 20% YoY growth
    GREATEST(100, ROUND(NORMAL(15000, 3000, RANDOM())
        * IFF(d.IS_WEEKEND, 1.25, 1.0)
        * (1.0 + 0.20 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60)
        * (1.0 + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12, 1) THEN 0.20 ELSE 0 END)
        * CASE tier WHEN 'PREMIUM' THEN 0.25 WHEN 'STANDARD' THEN 0.45 ELSE 0.30 END
    ))::INT                                            AS DAU,
    -- WAU: ~3x DAU
    GREATEST(500, ROUND(NORMAL(45000, 8000, RANDOM())
        * (1.0 + 0.20 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60)
        * CASE tier WHEN 'PREMIUM' THEN 0.25 WHEN 'STANDARD' THEN 0.45 ELSE 0.30 END
    ))::INT                                            AS WAU,
    -- MAU: ~5x DAU
    GREATEST(1000, ROUND(NORMAL(75000, 12000, RANDOM())
        * (1.0 + 0.20 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60)
        * CASE tier WHEN 'PREMIUM' THEN 0.25 WHEN 'STANDARD' THEN 0.45 ELSE 0.30 END
    ))::INT                                            AS MAU,
    -- DAU/MAU ratio: 0.15-0.30 (stickiness)
    LEAST(0.45, GREATEST(0.10, ROUND(NORMAL(0.22, 0.05, RANDOM())
        * IFF(d.IS_WEEKEND, 1.15, 1.0)
    , 4)))                                             AS DAU_MAU_RATIO,
    -- Avg session: 25-50 min
    ROUND(GREATEST(10, NORMAL(38, 12, RANDOM())
        * IFF(d.IS_WEEKEND, 1.3, 1.0)
    ), 2)                                              AS AVG_SESSION_MINUTES,
    -- Sessions per user: 1.5-3
    ROUND(GREATEST(1.0, NORMAL(2.2, 0.6, RANDOM())
        * IFF(d.IS_WEEKEND, 1.2, 1.0)
    ), 2)                                              AS SESSIONS_PER_USER
FROM NOVA_MEDIA.GOLD.DIM_DATE d
CROSS JOIN (SELECT column1 AS tier FROM VALUES ('BASIC'), ('STANDARD'), ('PREMIUM')) tiers
WHERE UNIFORM(0, 100, RANDOM()) < 50;
