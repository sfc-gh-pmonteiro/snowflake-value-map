-- ============================================================================
-- LIFE SCIENCES & PHARMA VERTICAL - Synthetic Data Generation
-- Entity: Helix Pharmaceuticals
-- Prerequisites: Run life-sciences-pharma-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- Patterns: S-curve enrollment, logistic Rx growth, power-law AE severity
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE HELIX_PHARMA.GOLD.AGG_SAFETY_SIGNAL;
TRUNCATE TABLE HELIX_PHARMA.GOLD.AGG_TRIAL_PERFORMANCE;
TRUNCATE TABLE HELIX_PHARMA.GOLD.FACT_HCP_ENGAGEMENT;
TRUNCATE TABLE HELIX_PHARMA.GOLD.FACT_MANUFACTURING;
TRUNCATE TABLE HELIX_PHARMA.GOLD.FACT_COMMERCIAL_RX;
TRUNCATE TABLE HELIX_PHARMA.GOLD.FACT_ADVERSE_EVENT;
TRUNCATE TABLE HELIX_PHARMA.GOLD.FACT_ENROLLMENT;
TRUNCATE TABLE HELIX_PHARMA.GOLD.DIM_DATE;
TRUNCATE TABLE HELIX_PHARMA.GOLD.DIM_PRODUCT;
TRUNCATE TABLE HELIX_PHARMA.GOLD.DIM_SITE;
TRUNCATE TABLE HELIX_PHARMA.GOLD.DIM_TRIAL;
TRUNCATE TABLE HELIX_PHARMA.GOLD.DIM_COMPOUND;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span)
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN FALSE ELSE TRUE END AS IS_WORKING_DAY
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_COMPOUND (~10 pipeline compounds)
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.DIM_COMPOUND
    (COMPOUND_KEY, COMPOUND_ID, MOLECULE_NAME, GENERIC_NAME, THERAPEUTIC_AREA,
     INDICATION, MECHANISM_OF_ACTION, CURRENT_PHASE, FIRST_IN_HUMAN_DATE, ROUTE_OF_ADMIN)
SELECT
    seq                                                AS COMPOUND_KEY,
    'HLX-' || LPAD(seq::VARCHAR, 4, '0')              AS COMPOUND_ID,
    GET(ARRAY_CONSTRUCT(
        'Helixumab', 'Neurolidin', 'Oncorix', 'Cardivant', 'Immunexil',
        'Rarelysin', 'Pneumovax-X', 'Arthriqel', 'Metabolyn', 'Dermaflux'
    ), seq - 1)::VARCHAR                               AS MOLECULE_NAME,
    GET(ARRAY_CONSTRUCT(
        'helixumab', 'neurolidin hydrochloride', 'oncorix maleate', 'cardivant sodium',
        'immunexil acetate', 'rarelysin citrate', 'pneumovax-x', 'arthriqel sulfate',
        'metabolyn tartrate', 'dermaflux cream'
    ), seq - 1)::VARCHAR                               AS GENERIC_NAME,
    GET(ARRAY_CONSTRUCT(
        'ONCOLOGY', 'CNS', 'ONCOLOGY', 'CARDIOVASCULAR', 'IMMUNOLOGY',
        'RARE_DISEASE', 'RESPIRATORY', 'IMMUNOLOGY', 'METABOLIC', 'DERMATOLOGY'
    ), seq - 1)::VARCHAR                               AS THERAPEUTIC_AREA,
    GET(ARRAY_CONSTRUCT(
        'Non-small cell lung cancer', 'Alzheimer disease', 'Triple-negative breast cancer',
        'Heart failure with reduced EF', 'Rheumatoid arthritis', 'Fabry disease',
        'Severe asthma', 'Psoriatic arthritis', 'Type 2 diabetes', 'Atopic dermatitis'
    ), seq - 1)::VARCHAR                               AS INDICATION,
    GET(ARRAY_CONSTRUCT(
        'PD-L1 inhibitor', 'BACE inhibitor', 'CDK4/6 inhibitor', 'SGLT2 inhibitor',
        'JAK inhibitor', 'Enzyme replacement', 'IL-5 antagonist', 'TNF-alpha inhibitor',
        'GLP-1 agonist', 'IL-13 inhibitor'
    ), seq - 1)::VARCHAR                               AS MECHANISM_OF_ACTION,
    GET(ARRAY_CONSTRUCT(
        'PHASE_3', 'PHASE_2', 'PHASE_3', 'PHASE_2B', 'PHASE_4',
        'PHASE_3', 'PHASE_2', 'PHASE_4', 'PHASE_3', 'PHASE_1'
    ), seq - 1)::VARCHAR                               AS CURRENT_PHASE,
    DATEADD('day', -UNIFORM(800, 2500, RANDOM()), CURRENT_DATE()) AS FIRST_IN_HUMAN_DATE,
    GET(ARRAY_CONSTRUCT(
        'IV', 'ORAL', 'ORAL', 'ORAL', 'SC',
        'IV', 'SC', 'SC', 'SC', 'TOPICAL'
    ), seq - 1)::VARCHAR                               AS ROUTE_OF_ADMIN
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 10)));

-- ============================================================================
-- 3. DIM_TRIAL (~25 clinical trials across compounds)
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.DIM_TRIAL
    (TRIAL_KEY, TRIAL_ID, PROTOCOL_NUMBER, TRIAL_PHASE, INDICATION,
     STATUS, TARGET_ENROLLMENT, ACTUAL_ENROLLMENT, START_DATE, SITE_COUNT)
SELECT
    seq                                                AS TRIAL_KEY,
    'HLX-TRL-' || LPAD(seq::VARCHAR, 4, '0')          AS TRIAL_ID,
    'HLX-' || LPAD(UNIFORM(100, 999, RANDOM())::VARCHAR, 3, '0') || '-' ||
        GET(ARRAY_CONSTRUCT('001', '002', '003', '004', '005'), MOD(seq-1, 5))::VARCHAR AS PROTOCOL_NUMBER,
    GET(ARRAY_CONSTRUCT(
        'PHASE_1', 'PHASE_1', 'PHASE_2', 'PHASE_2', 'PHASE_2B',
        'PHASE_2B', 'PHASE_3', 'PHASE_3', 'PHASE_3', 'PHASE_3',
        'PHASE_3', 'PHASE_4', 'PHASE_4', 'PHASE_2', 'PHASE_3',
        'PHASE_1', 'PHASE_2', 'PHASE_2B', 'PHASE_3', 'PHASE_3',
        'PHASE_4', 'PHASE_2', 'PHASE_3', 'PHASE_1', 'PHASE_2'
    ), seq - 1)::VARCHAR                               AS TRIAL_PHASE,
    GET(ARRAY_CONSTRUCT(
        'Non-small cell lung cancer', 'NSCLC dose escalation', 'Alzheimer disease mild',
        'Alzheimer disease moderate', 'Triple-negative breast cancer', 'TNBC adjuvant',
        'Heart failure HFrEF', 'Heart failure NYHA III-IV', 'Rheumatoid arthritis',
        'RA inadequate MTX response', 'Fabry disease', 'Severe asthma eosinophilic',
        'Psoriatic arthritis active', 'Type 2 diabetes inadequate control',
        'GLP-1 cardiovascular outcomes', 'Atopic dermatitis moderate-severe',
        'NSCLC 1st line combo', 'Alzheimer biomarker enriched', 'RA biologic-experienced',
        'Fabry disease pediatric', 'Asthma maintenance', 'PsA TNF-IR',
        'T2D renal outcomes', 'Dermatitis dose-finding', 'NSCLC adjuvant'
    ), seq - 1)::VARCHAR                               AS INDICATION,
    GET(ARRAY_CONSTRUCT(
        'ACTIVE', 'CLOSED', 'RECRUITING', 'ACTIVE', 'RECRUITING',
        'ACTIVE', 'RECRUITING', 'ACTIVE', 'CLOSED', 'RECRUITING',
        'ACTIVE', 'RECRUITING', 'ACTIVE', 'RECRUITING', 'PLANNING',
        'RECRUITING', 'ACTIVE', 'RECRUITING', 'ACTIVE', 'RECRUITING',
        'CLOSED', 'ACTIVE', 'PLANNING', 'RECRUITING', 'ACTIVE'
    ), seq - 1)::VARCHAR                               AS STATUS,
    CASE
        WHEN MOD(seq, 5) = 1 THEN UNIFORM(30, 80, RANDOM())
        WHEN MOD(seq, 5) = 2 THEN UNIFORM(100, 300, RANDOM())
        WHEN MOD(seq, 5) = 3 THEN UNIFORM(200, 500, RANDOM())
        ELSE UNIFORM(500, 2000, RANDOM())
    END                                                AS TARGET_ENROLLMENT,
    CASE
        WHEN MOD(seq, 5) = 1 THEN UNIFORM(20, 75, RANDOM())
        WHEN MOD(seq, 5) = 2 THEN UNIFORM(50, 250, RANDOM())
        WHEN MOD(seq, 5) = 3 THEN UNIFORM(100, 450, RANDOM())
        ELSE UNIFORM(200, 1800, RANDOM())
    END                                                AS ACTUAL_ENROLLMENT,
    DATEADD('day', -UNIFORM(200, 1800, RANDOM()), CURRENT_DATE()) AS START_DATE,
    UNIFORM(5, 60, RANDOM())                           AS SITE_COUNT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 25)));

-- ============================================================================
-- 4. DIM_SITE (~200 investigator sites)
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.DIM_SITE
    (SITE_KEY, SITE_ID, INSTITUTION, INVESTIGATOR_NAME, COUNTRY, STATE,
     ACTIVATION_DATE, PERFORMANCE_TIER)
SELECT
    seq                                                AS SITE_KEY,
    'SITE-' || LPAD(seq::VARCHAR, 5, '0')              AS SITE_ID,
    GET(ARRAY_CONSTRUCT(
        'Johns Hopkins University', 'Memorial Sloan Kettering', 'Mayo Clinic Rochester',
        'Massachusetts General Hospital', 'Cleveland Clinic', 'MD Anderson Cancer Center',
        'Stanford University Medical Center', 'Cedars-Sinai Medical Center',
        'Duke University Hospital', 'UCSF Medical Center', 'Mount Sinai Hospital',
        'NYU Langone Health', 'Northwestern Memorial', 'Brigham and Women Hospital',
        'University of Pennsylvania', 'Vanderbilt University MC', 'Emory University Hospital',
        'University of Michigan', 'UCLA Medical Center', 'Columbia University MC'
    ), MOD(seq - 1, 20))::VARCHAR || ' (' || seq::VARCHAR || ')' AS INSTITUTION,
    GET(ARRAY_CONSTRUCT(
        'Dr. A. Patel', 'Dr. B. Chen', 'Dr. C. Rodriguez', 'Dr. D. Kim', 'Dr. E. Johnson',
        'Dr. F. Williams', 'Dr. G. Brown', 'Dr. H. Davis', 'Dr. I. Martinez', 'Dr. J. Wilson',
        'Dr. K. Anderson', 'Dr. L. Thomas', 'Dr. M. Jackson', 'Dr. N. White', 'Dr. O. Harris',
        'Dr. P. Martin', 'Dr. Q. Thompson', 'Dr. R. Garcia', 'Dr. S. Clark', 'Dr. T. Lewis'
    ), MOD(seq - 1, 20))::VARCHAR                      AS INVESTIGATOR_NAME,
    GET(ARRAY_CONSTRUCT('US', 'US', 'US', 'US', 'US', 'US', 'US', 'CA', 'CA', 'GB',
        'GB', 'DE', 'DE', 'FR', 'FR', 'JP', 'JP', 'AU', 'AU', 'US'),
        MOD(seq - 1, 20))::VARCHAR                     AS COUNTRY,
    IFF(MOD(seq - 1, 20) < 7, GET(ARRAY_CONSTRUCT('MD', 'NY', 'MN', 'MA', 'OH', 'TX', 'CA'),
        MOD(seq - 1, 7))::VARCHAR, NULL)               AS STATE,
    DATEADD('day', -UNIFORM(100, 1500, RANDOM()), CURRENT_DATE()) AS ACTIVATION_DATE,
    GET(ARRAY_CONSTRUCT('HIGH', 'HIGH', 'MEDIUM', 'MEDIUM', 'MEDIUM', 'MEDIUM', 'LOW', 'LOW', 'MEDIUM', 'HIGH'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS PERFORMANCE_TIER
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 200)));

-- ============================================================================
-- 5. DIM_PRODUCT (~8 marketed products)
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.DIM_PRODUCT
    (PRODUCT_KEY, PRODUCT_ID, PRODUCT_NAME, NDC, THERAPEUTIC_AREA,
     LAUNCH_DATE, DOSAGE_FORM, STRENGTH, MARKET_STATUS)
SELECT
    seq                                                AS PRODUCT_KEY,
    'HLX-PRD-' || LPAD(seq::VARCHAR, 3, '0')          AS PRODUCT_ID,
    GET(ARRAY_CONSTRUCT(
        'Helixumab 200mg Vial', 'Immunexil 50mg Prefilled Syringe', 'Cardivant 10mg Tablet',
        'Arthriqel 40mg Autoinjector', 'Metabolyn 1.2mg Pen', 'Pneumovax-X 100mg Syringe',
        'Rarelysin 35mg Vial', 'Oncorix 150mg Capsule'
    ), seq - 1)::VARCHAR                               AS PRODUCT_NAME,
    '12345-' || LPAD(seq::VARCHAR, 3, '0') || '-01'   AS NDC,
    GET(ARRAY_CONSTRUCT(
        'ONCOLOGY', 'IMMUNOLOGY', 'CARDIOVASCULAR', 'IMMUNOLOGY',
        'METABOLIC', 'RESPIRATORY', 'RARE_DISEASE', 'ONCOLOGY'
    ), seq - 1)::VARCHAR                               AS THERAPEUTIC_AREA,
    GET(ARRAY_CONSTRUCT(
        DATEADD('year', -4, CURRENT_DATE()),
        DATEADD('year', -3, CURRENT_DATE()),
        DATEADD('month', -30, CURRENT_DATE()),
        DATEADD('year', -2, CURRENT_DATE()),
        DATEADD('month', -18, CURRENT_DATE()),
        DATEADD('month', -12, CURRENT_DATE()),
        DATEADD('month', -8, CURRENT_DATE()),
        DATEADD('month', -6, CURRENT_DATE())
    ), seq - 1)::DATE                                  AS LAUNCH_DATE,
    GET(ARRAY_CONSTRUCT(
        'INJECTION', 'INJECTION', 'TABLET', 'INJECTION',
        'INJECTION', 'INJECTION', 'INJECTION', 'CAPSULE'
    ), seq - 1)::VARCHAR                               AS DOSAGE_FORM,
    GET(ARRAY_CONSTRUCT(
        '200mg', '50mg', '10mg', '40mg', '1.2mg', '100mg', '35mg', '150mg'
    ), seq - 1)::VARCHAR                               AS STRENGTH,
    GET(ARRAY_CONSTRUCT(
        'MATURE', 'ACTIVE', 'ACTIVE', 'ACTIVE',
        'ACTIVE', 'PRE_LAUNCH', 'PRE_LAUNCH', 'PRE_LAUNCH'
    ), seq - 1)::VARCHAR                               AS MARKET_STATUS
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 8)));

-- ============================================================================
-- 6. FACT_ENROLLMENT (~50K enrollment records, S-curve per trial)
-- Monthly site-level enrollment with slow start, ramp, plateau
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.FACT_ENROLLMENT
    (DATE_KEY, TRIAL_KEY, SITE_KEY, SCREENED, RANDOMIZED, COMPLETED, WITHDRAWN,
     SCREEN_FAIL_COUNT, SCREEN_FAIL_RATE, ENROLLMENT_RATE)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    t.TRIAL_KEY                                        AS TRIAL_KEY,
    UNIFORM(1, 200, RANDOM())                          AS SITE_KEY,
    -- S-curve enrollment: logistic growth based on months since trial start
    GREATEST(0, ROUND(
        (8.0 / (1.0 + EXP(-0.15 * (DATEDIFF('month', t.START_DATE, d.FULL_DATE) - 12))))
        * (1 + NORMAL(0, 0.3, RANDOM()))
        * IFF(UNIFORM(0, 100, RANDOM()) < 2, 0, 1)   -- 2% NULL-like zeros
    ))::INT                                            AS SCREENED,
    GREATEST(0, ROUND(
        (5.0 / (1.0 + EXP(-0.15 * (DATEDIFF('month', t.START_DATE, d.FULL_DATE) - 14))))
        * (1 + NORMAL(0, 0.25, RANDOM()))
    ))::INT                                            AS RANDOMIZED,
    GREATEST(0, ROUND(NORMAL(2, 1.5, RANDOM())
        * IFF(DATEDIFF('month', t.START_DATE, d.FULL_DATE) > 18, 1.5, 0.5)
    ))::INT                                            AS COMPLETED,
    IFF(UNIFORM(0, 100, RANDOM()) < 8,
        GREATEST(0, ROUND(NORMAL(0.5, 0.5, RANDOM())))::INT, 0) AS WITHDRAWN,
    GREATEST(0, ROUND(NORMAL(1.5, 1.0, RANDOM())))::INT AS SCREEN_FAIL_COUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0.0, LEAST(0.5, ROUND(NORMAL(0.18, 0.08, RANDOM()), 4)))) AS SCREEN_FAIL_RATE,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0.0, ROUND(
            (3.0 / (1.0 + EXP(-0.12 * (DATEDIFF('month', t.START_DATE, d.FULL_DATE) - 10))))
            * (1 + NORMAL(0, 0.2, RANDOM())), 2
        )))                                            AS ENROLLMENT_RATE
FROM HELIX_PHARMA.GOLD.DIM_DATE d
CROSS JOIN HELIX_PHARMA.GOLD.DIM_TRIAL t
WHERE d.FULL_DATE >= t.START_DATE
  AND DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 45;

-- ============================================================================
-- 7. FACT_ADVERSE_EVENT (~15K events, power-law severity)
-- Most mild, few serious; proportional to enrollment duration
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.FACT_ADVERSE_EVENT
    (DATE_KEY, COMPOUND_KEY, TRIAL_KEY, SOC, TOTAL_EVENTS, SERIOUS_EVENTS,
     RELATED_EVENTS, FATAL_EVENTS, EXPEDITED_REPORTS, SUBJECTS_AFFECTED)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 10, RANDOM())                           AS COMPOUND_KEY,
    t.TRIAL_KEY                                        AS TRIAL_KEY,
    GET(ARRAY_CONSTRUCT(
        'Gastrointestinal disorders', 'General disorders', 'Infections and infestations',
        'Musculoskeletal disorders', 'Nervous system disorders', 'Skin disorders',
        'Respiratory disorders', 'Vascular disorders', 'Hepatobiliary disorders',
        'Blood and lymphatic disorders', 'Cardiac disorders', 'Immune system disorders'
    ), UNIFORM(0, 11, RANDOM()))::VARCHAR              AS SOC,
    -- Power-law: most events are low count; rare spikes
    GREATEST(1, ROUND(EXP(NORMAL(1.5, 0.8, RANDOM()))))::INT AS TOTAL_EVENTS,
    -- Serious: ~8-12% of total, power-law distribution
    GREATEST(0, ROUND(EXP(NORMAL(0.3, 0.7, RANDOM()))
        * IFF(UNIFORM(0, 100, RANDOM()) < 10, 1, 0)))::INT AS SERIOUS_EVENTS,
    -- Related: ~30-50% of total
    GREATEST(0, ROUND(EXP(NORMAL(1.0, 0.6, RANDOM()))
        * 0.4))::INT                                   AS RELATED_EVENTS,
    IFF(UNIFORM(0, 1000, RANDOM()) < 3, 1, 0)         AS FATAL_EVENTS,
    IFF(UNIFORM(0, 100, RANDOM()) < 5,
        GREATEST(1, ROUND(NORMAL(1.5, 0.5, RANDOM())))::INT, 0) AS EXPEDITED_REPORTS,
    GREATEST(1, ROUND(EXP(NORMAL(1.2, 0.7, RANDOM()))))::INT AS SUBJECTS_AFFECTED
FROM HELIX_PHARMA.GOLD.DIM_DATE d
CROSS JOIN HELIX_PHARMA.GOLD.DIM_TRIAL t
WHERE d.FULL_DATE >= t.START_DATE
  AND DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 35;

-- ============================================================================
-- 8. FACT_COMMERCIAL_RX (~100K, logistic growth post-launch)
-- Territory x product x month with seasonal dips and competitive dynamics
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.FACT_COMMERCIAL_RX
    (DATE_KEY, PRODUCT_KEY, TERRITORY_ID, TOTAL_RX, NEW_RX, REFILL_RX,
     TOTAL_UNITS, MARKET_SHARE_PCT, NBR_PRESCRIBERS, PAYER_MIX_COMMERCIAL_PCT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    p.PRODUCT_KEY                                      AS PRODUCT_KEY,
    'TER-' || LPAD(UNIFORM(1, 120, RANDOM())::VARCHAR, 4, '0') AS TERRITORY_ID,
    -- Logistic growth from launch: saturates at ~80 Rx/territory/month
    GREATEST(0, ROUND(
        (80.0 / (1.0 + EXP(-0.08 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))))
        * (1 + NORMAL(0, 0.15, RANDOM()))
        -- Summer dip (Jun-Aug): -15%
        * IFF(MONTH(d.FULL_DATE) IN (6, 7, 8), 0.85, 1.0)
        -- Competitive pressure on mature products
        * IFF(p.MARKET_STATUS = 'MATURE', 0.92, 1.0)
    ))::INT                                            AS TOTAL_RX,
    -- New Rx: decreasing share over time (early = mostly new, mature = mostly refill)
    GREATEST(0, ROUND(
        (80.0 / (1.0 + EXP(-0.08 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))))
        * GREATEST(0.15, 0.6 - 0.01 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))
        * (1 + NORMAL(0, 0.2, RANDOM()))
    ))::INT                                            AS NEW_RX,
    GREATEST(0, ROUND(
        (80.0 / (1.0 + EXP(-0.08 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))))
        * LEAST(0.85, 0.4 + 0.01 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))
        * (1 + NORMAL(0, 0.15, RANDOM()))
    ))::INT                                            AS REFILL_RX,
    GREATEST(0, ROUND(
        (80.0 / (1.0 + EXP(-0.08 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))))
        * UNIFORM(28, 90, RANDOM())
    ))::INT                                            AS TOTAL_UNITS,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0.0, LEAST(0.35, ROUND(
            (0.25 / (1.0 + EXP(-0.06 * DATEDIFF('month', p.LAUNCH_DATE, d.FULL_DATE))))
            * (1 + NORMAL(0, 0.1, RANDOM())), 4
        ))))                                           AS MARKET_SHARE_PCT,
    GREATEST(1, ROUND(NORMAL(15, 5, RANDOM())))::INT   AS NBR_PRESCRIBERS,
    IFF(UNIFORM(0, 100, RANDOM()) < 1, NULL,
        GREATEST(0.2, LEAST(0.85, ROUND(NORMAL(0.55, 0.12, RANDOM()), 4)))) AS PAYER_MIX_COMMERCIAL_PCT
FROM HELIX_PHARMA.GOLD.DIM_DATE d
CROSS JOIN HELIX_PHARMA.GOLD.DIM_PRODUCT p
WHERE d.FULL_DATE >= p.LAUNCH_DATE
  AND DAY(d.FULL_DATE) = 1
  AND p.MARKET_STATUS IN ('ACTIVE', 'MATURE')
  AND UNIFORM(0, 100, RANDOM()) < 70;

-- ============================================================================
-- 9. FACT_MANUFACTURING (~5K batch records)
-- High yield (95-99%), rare deviations (2-5%), batch size variation
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.FACT_MANUFACTURING
    (DATE_KEY, PRODUCT_KEY, MANUFACTURING_SITE, BATCHES_PRODUCED, BATCHES_RELEASED,
     BATCHES_REJECTED, YIELD_AVG, DEVIATIONS, CRITICAL_DEVIATIONS, RIGHT_FIRST_TIME_PCT)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    p.PRODUCT_KEY                                      AS PRODUCT_KEY,
    GET(ARRAY_CONSTRUCT(
        'Durham NC', 'Basel CH', 'Cork IE', 'Singapore SG', 'Osaka JP'
    ), UNIFORM(0, 4, RANDOM()))::VARCHAR               AS MANUFACTURING_SITE,
    GREATEST(1, ROUND(NORMAL(8, 3, RANDOM())))::INT    AS BATCHES_PRODUCED,
    GREATEST(1, ROUND(NORMAL(7.5, 2.8, RANDOM())))::INT AS BATCHES_RELEASED,
    -- Rare rejections: 2-5% of batches
    IFF(UNIFORM(0, 100, RANDOM()) < 4,
        GREATEST(1, ROUND(NORMAL(1, 0.5, RANDOM())))::INT, 0) AS BATCHES_REJECTED,
    -- Yield: normally 96-99%, occasional excursions
    GREATEST(85.0, LEAST(99.9, ROUND(
        NORMAL(97.5, 1.2, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 0.95, 1.0), 2
    )))                                                AS YIELD_AVG,
    -- Deviations: mostly 0, sometimes 1-3
    IFF(UNIFORM(0, 100, RANDOM()) < 15,
        GREATEST(1, ROUND(NORMAL(1.5, 0.8, RANDOM())))::INT, 0) AS DEVIATIONS,
    IFF(UNIFORM(0, 1000, RANDOM()) < 8, 1, 0)         AS CRITICAL_DEVIATIONS,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0.80, LEAST(1.0, ROUND(NORMAL(0.95, 0.03, RANDOM()), 4)))) AS RIGHT_FIRST_TIME_PCT
FROM HELIX_PHARMA.GOLD.DIM_DATE d
CROSS JOIN HELIX_PHARMA.GOLD.DIM_PRODUCT p
WHERE DAY(d.FULL_DATE) BETWEEN 1 AND 7
  AND DAYOFWEEK(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 65;

-- ============================================================================
-- 10. FACT_HCP_ENGAGEMENT (~40K call records)
-- Territory-based frequency, diminishing returns on high-call HCPs
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.FACT_HCP_ENGAGEMENT
    (DATE_KEY, PRODUCT_KEY, REP_ID, TERRITORY_ID, CALLS, SAMPLES_DELIVERED,
     REACH_PCT, FREQUENCY, POSITIVE_SENTIMENT_PCT, UNIQUE_HCPS_SEEN)
SELECT
    d.DATE_KEY                                         AS DATE_KEY,
    UNIFORM(1, 5, RANDOM())                            AS PRODUCT_KEY,
    'REP-' || LPAD(UNIFORM(1, 200, RANDOM())::VARCHAR, 4, '0') AS REP_ID,
    'TER-' || LPAD(UNIFORM(1, 120, RANDOM())::VARCHAR, 4, '0') AS TERRITORY_ID,
    -- Weekly calls per rep: target 8-12
    GREATEST(1, ROUND(NORMAL(10, 3, RANDOM())))::INT   AS CALLS,
    GREATEST(0, ROUND(NORMAL(4, 2, RANDOM())))::INT    AS SAMPLES_DELIVERED,
    -- Reach: what % of target HCPs seen
    IFF(UNIFORM(0, 100, RANDOM()) < 1, NULL,
        GREATEST(0.3, LEAST(1.0, ROUND(NORMAL(0.72, 0.12, RANDOM()), 4)))) AS REACH_PCT,
    -- Frequency: avg calls per HCP this period
    GREATEST(0.5, LEAST(8.0, ROUND(NORMAL(2.5, 1.0, RANDOM()), 2))) AS FREQUENCY,
    -- Diminishing returns: high-frequency calls have lower positive sentiment
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0.2, LEAST(0.95, ROUND(
            NORMAL(0.65, 0.12, RANDOM())
            * IFF(NORMAL(2.5, 1.0, RANDOM()) > 4.0, 0.85, 1.0), 4
        ))))                                           AS POSITIVE_SENTIMENT_PCT,
    GREATEST(1, ROUND(NORMAL(7, 2.5, RANDOM())))::INT  AS UNIQUE_HCPS_SEEN
FROM HELIX_PHARMA.GOLD.DIM_DATE d
WHERE d.IS_WORKING_DAY = TRUE
  AND UNIFORM(0, 100, RANDOM()) < 6;

-- ============================================================================
-- 11. AGG_TRIAL_PERFORMANCE (monthly per trial x site)
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.AGG_TRIAL_PERFORMANCE
    (TRIAL_KEY, SITE_KEY, MONTH_KEY, ENROLLMENT_RATE, SCREEN_FAIL_PCT,
     QUERY_RATE, PROTOCOL_DEVIATION_RATE, DATA_ENTRY_CYCLE_DAYS, SITE_RANK)
SELECT
    t.TRIAL_KEY                                        AS TRIAL_KEY,
    UNIFORM(1, 200, RANDOM())                          AS SITE_KEY,
    d.DATE_KEY                                         AS MONTH_KEY,
    -- Enrollment rate (subjects per site per month): 0.5 - 4.0 typical
    GREATEST(0.0, ROUND(NORMAL(1.8, 0.9, RANDOM()), 2)) AS ENROLLMENT_RATE,
    -- Screen fail: 15-30% typical
    GREATEST(0.05, LEAST(0.55, ROUND(NORMAL(0.22, 0.08, RANDOM()), 4))) AS SCREEN_FAIL_PCT,
    -- Query rate: queries per subject, lower is better
    GREATEST(0.5, ROUND(NORMAL(3.5, 1.8, RANDOM()), 2)) AS QUERY_RATE,
    -- Protocol deviation: 0.5-5% of subjects
    IFF(UNIFORM(0, 100, RANDOM()) < 3, NULL,
        GREATEST(0.001, LEAST(0.08, ROUND(NORMAL(0.025, 0.015, RANDOM()), 4)))) AS PROTOCOL_DEVIATION_RATE,
    -- Data entry cycle: days from visit to data entry
    GREATEST(0.5, ROUND(NORMAL(3.5, 2.0, RANDOM()), 1)) AS DATA_ENTRY_CYCLE_DAYS,
    -- Site rank within trial
    UNIFORM(1, 60, RANDOM())                           AS SITE_RANK
FROM HELIX_PHARMA.GOLD.DIM_DATE d
CROSS JOIN HELIX_PHARMA.GOLD.DIM_TRIAL t
WHERE d.FULL_DATE >= t.START_DATE
  AND DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 25;

-- ============================================================================
-- 12. AGG_SAFETY_SIGNAL (monthly per compound x event term)
-- Mostly noise (PRR ~1.0), rare true signals (PRR > 2.0) for 2-3 terms
-- ============================================================================
INSERT INTO HELIX_PHARMA.GOLD.AGG_SAFETY_SIGNAL
    (COMPOUND_KEY, MONTH_KEY, EVENT_TERM, SOC, OBSERVED_COUNT, EXPECTED_COUNT,
     PRO_SCORE, SIGNAL_FLAG, SERIOUSNESS_RATIO, CASE_TREND)
SELECT
    UNIFORM(1, 10, RANDOM())                           AS COMPOUND_KEY,
    d.DATE_KEY                                         AS MONTH_KEY,
    GET(ARRAY_CONSTRUCT(
        'Nausea', 'Headache', 'Fatigue', 'Diarrhea', 'Arthralgia',
        'Rash', 'Pyrexia', 'Cough', 'Injection site reaction', 'Dizziness',
        'Neutropenia', 'Elevated ALT', 'Hypertension', 'Peripheral neuropathy',
        'Thrombocytopenia', 'Pneumonitis', 'Colitis', 'Hepatotoxicity',
        'QT prolongation', 'Anaphylaxis'
    ), UNIFORM(0, 19, RANDOM()))::VARCHAR              AS EVENT_TERM,
    GET(ARRAY_CONSTRUCT(
        'Gastrointestinal disorders', 'Nervous system disorders', 'General disorders',
        'Gastrointestinal disorders', 'Musculoskeletal disorders', 'Skin disorders',
        'General disorders', 'Respiratory disorders', 'General disorders', 'Nervous system disorders',
        'Blood disorders', 'Hepatobiliary disorders', 'Vascular disorders', 'Nervous system disorders',
        'Blood disorders', 'Respiratory disorders', 'Gastrointestinal disorders',
        'Hepatobiliary disorders', 'Cardiac disorders', 'Immune system disorders'
    ), UNIFORM(0, 19, RANDOM()))::VARCHAR              AS SOC,
    -- Observed counts: Poisson-like via rounded exponential
    GREATEST(1, ROUND(EXP(NORMAL(1.8, 0.8, RANDOM()))))::INT AS OBSERVED_COUNT,
    -- Expected: similar to observed for most (noise), lower for true signals
    GREATEST(0.5, ROUND(
        EXP(NORMAL(1.8, 0.8, RANDOM()))
        * IFF(UNIFORM(0, 100, RANDOM()) < 5, 0.4, 1.0), 2  -- 5% are true signals
    ))                                                 AS EXPECTED_COUNT,
    -- PRR: mostly ~1.0 (noise), rare >2.0 (true signal)
    GREATEST(0.3, ROUND(
        IFF(UNIFORM(0, 100, RANDOM()) < 5,
            NORMAL(2.8, 0.8, RANDOM()),   -- True signal: PRR > 2
            NORMAL(1.0, 0.25, RANDOM())   -- Noise: PRR ~1.0
        ), 4
    ))                                                 AS PRO_SCORE,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, TRUE, FALSE)   AS SIGNAL_FLAG,
    -- Seriousness ratio: fraction of serious among reported
    GREATEST(0.0, LEAST(1.0, ROUND(NORMAL(0.12, 0.08, RANDOM()), 4))) AS SERIOUSNESS_RATIO,
    GET(ARRAY_CONSTRUCT('STABLE', 'STABLE', 'STABLE', 'STABLE', 'STABLE',
        'INCREASING', 'INCREASING', 'DECREASING', 'STABLE', 'STABLE'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS CASE_TREND
FROM HELIX_PHARMA.GOLD.DIM_DATE d
WHERE DAY(d.FULL_DATE) = 1
  AND UNIFORM(0, 100, RANDOM()) < 12;
