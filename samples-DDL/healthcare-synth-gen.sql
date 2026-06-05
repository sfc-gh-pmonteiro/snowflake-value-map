-- ============================================================================
-- HEALTHCARE VERTICAL - Synthetic Data Generation
-- Entity: Meridian Health System
-- Prerequisites: Run healthcare-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~3-5 minutes on XS warehouse
-- US calendar: flu season Oct-Mar, Q4 elective surge, summer lull
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.AGG_READMISSION_COHORT;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.AGG_REVENUE_CYCLE;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.AGG_PATIENT_RISK;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.FACT_LAB_RESULT;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.FACT_CLAIM;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.FACT_ENCOUNTER;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.DIM_DATE;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.DIM_PAYER;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.DIM_DIAGNOSIS;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.DIM_PROVIDER;
TRUNCATE TABLE MERIDIAN_HEALTH.GOLD.DIM_PATIENT;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.DIM_DATE
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
-- 2. DIM_PATIENT (2,000 patients)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.DIM_PATIENT
    (PATIENT_KEY, PATIENT_ID, MRN, AGE, AGE_GROUP, GENDER, RACE, ETHNICITY,
     ZIP_CODE, COUNTY_FIPS, INSURANCE_CLASS, PCP_PROVIDER_ID,
     CHRONIC_CONDITION_COUNT, HCC_RISK_SCORE, SDOH_RISK_SCORE, LAST_ENCOUNTER_DATE,
     _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS PATIENT_KEY,
    'PAT-' || LPAD(seq::VARCHAR, 7, '0')               AS PATIENT_ID,
    'MRN' || LPAD((seq + 100000)::VARCHAR, 8, '0')     AS MRN,
    GREATEST(1, LEAST(99, ROUND(
        CASE UNIFORM(0, 9, RANDOM())
            WHEN 0 THEN NORMAL(8, 3, RANDOM())    -- pediatric 10%
            WHEN 1 THEN NORMAL(30, 5, RANDOM())   -- young adult 10%
            WHEN 2 THEN NORMAL(30, 5, RANDOM())
            WHEN 3 THEN NORMAL(45, 8, RANDOM())   -- middle age 30%
            WHEN 4 THEN NORMAL(45, 8, RANDOM())
            WHEN 5 THEN NORMAL(45, 8, RANDOM())
            WHEN 6 THEN NORMAL(65, 8, RANDOM())   -- senior 30%
            WHEN 7 THEN NORMAL(65, 8, RANDOM())
            WHEN 8 THEN NORMAL(65, 8, RANDOM())
            ELSE NORMAL(78, 6, RANDOM())           -- elderly 10%
        END
    )))                                                AS AGE,
    CASE
        WHEN NORMAL(45, 20, RANDOM()) < 18 THEN 'PEDIATRIC'
        WHEN NORMAL(45, 20, RANDOM()) < 40 THEN 'ADULT_18_39'
        WHEN NORMAL(45, 20, RANDOM()) < 65 THEN 'ADULT_40_64'
        ELSE 'SENIOR_65+'
    END                                                AS AGE_GROUP,
    GET(ARRAY_CONSTRUCT('M', 'F', 'F', 'M', 'M', 'F', 'M', 'F', 'F', 'M'), UNIFORM(0, 9, RANDOM()))::VARCHAR AS GENDER,
    GET(ARRAY_CONSTRUCT('White', 'White', 'White', 'Black', 'Black', 'Hispanic', 'Hispanic', 'Asian', 'Other', 'White'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS RACE,
    GET(ARRAY_CONSTRUCT('Non-Hispanic', 'Non-Hispanic', 'Non-Hispanic', 'Non-Hispanic', 'Hispanic', 'Hispanic', 'Non-Hispanic', 'Non-Hispanic', 'Non-Hispanic', 'Non-Hispanic'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ETHNICITY,
    LPAD(UNIFORM(10001, 99999, RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    LPAD(UNIFORM(1001, 9999, RANDOM())::VARCHAR, 5, '0') AS COUNTY_FIPS,
    GET(ARRAY_CONSTRUCT('COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL', 'MEDICARE', 'MEDICARE', 'MEDICAID', 'MEDICAID', 'SELF_PAY'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS INSURANCE_CLASS,
    'PRV-' || LPAD(UNIFORM(1, 80, RANDOM())::VARCHAR, 4, '0') AS PCP_PROVIDER_ID,
    GREATEST(0, ROUND(NORMAL(1.5, 1.5, RANDOM())))::INT AS CHRONIC_CONDITION_COUNT,
    GREATEST(0.5, LEAST(5.0, ROUND(NORMAL(1.2, 0.8, RANDOM()), 3))) AS HCC_RISK_SCORE,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        GREATEST(0, LEAST(10, ROUND(NORMAL(3.5, 2.5, RANDOM()), 2)))) AS SDOH_RISK_SCORE,
    DATEADD('day', -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()) AS LAST_ENCOUNTER_DATE,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 2000)));

-- ============================================================================
-- 3. DIM_PROVIDER (80 providers)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.DIM_PROVIDER
    (PROVIDER_KEY, PROVIDER_ID, NPI, PROVIDER_NAME, SPECIALTY, SPECIALTY_CATEGORY,
     DEPARTMENT_NAME, FACILITY_NAME, PROVIDER_TYPE, _IS_CURRENT)
SELECT
    seq                                                AS PROVIDER_KEY,
    'PRV-' || LPAD(seq::VARCHAR, 4, '0')               AS PROVIDER_ID,
    '1' || LPAD(UNIFORM(100000000, 999999999, RANDOM())::VARCHAR, 9, '0') AS NPI,
    GET(ARRAY_CONSTRUCT('Dr. Sarah Chen', 'Dr. James Wilson', 'Dr. Maria Rodriguez', 'Dr. Robert Kim',
        'Dr. Emily Thompson', 'Dr. David Patel', 'Dr. Lisa Johnson', 'Dr. Michael Brown',
        'Dr. Jennifer Davis', 'Dr. Christopher Lee', 'Dr. Amanda Foster', 'Dr. Steven Park',
        'Dr. Rachel Green', 'Dr. Daniel Martinez', 'Dr. Karen White', 'Dr. Andrew Singh'),
        MOD(seq - 1, 16))::VARCHAR || ' (' || seq::VARCHAR || ')' AS PROVIDER_NAME,
    GET(ARRAY_CONSTRUCT(
        'Internal Medicine', 'Family Medicine', 'Cardiology', 'Orthopedics', 'Neurology',
        'Pulmonology', 'Endocrinology', 'Oncology', 'General Surgery', 'Emergency Medicine',
        'Pediatrics', 'OB/GYN', 'Psychiatry', 'Dermatology', 'Nephrology', 'Gastroenterology'
    ), MOD(seq - 1, 16))::VARCHAR                      AS SPECIALTY,
    GET(ARRAY_CONSTRUCT('Primary Care', 'Primary Care', 'Cardiology', 'Surgery', 'Neurology',
        'Pulmonology', 'Medicine', 'Oncology', 'Surgery', 'Emergency', 'Pediatrics', 'OB/GYN',
        'Behavioral Health', 'Medicine', 'Medicine', 'Medicine'),
        MOD(seq - 1, 16))::VARCHAR                     AS SPECIALTY_CATEGORY,
    GET(ARRAY_CONSTRUCT('Medicine', 'Primary Care', 'Heart Center', 'Orthopedic Institute',
        'Neuroscience', 'Pulmonary', 'Endocrine', 'Cancer Center', 'Surgical Services', 'Emergency Dept',
        'Children Hospital', 'Women Health', 'Behavioral Health', 'Dermatology', 'Renal', 'GI Center'),
        MOD(seq - 1, 16))::VARCHAR                     AS DEPARTMENT_NAME,
    GET(ARRAY_CONSTRUCT('Meridian Main Campus', 'Meridian Main Campus', 'Meridian Heart Institute',
        'Meridian West', 'Meridian Main Campus', 'Meridian Main Campus', 'Meridian Specialty Clinic',
        'Meridian Cancer Center', 'Meridian Main Campus', 'Meridian ED', 'Meridian Children',
        'Meridian Women', 'Meridian Behavioral', 'Meridian Specialty Clinic', 'Meridian Main Campus', 'Meridian GI'),
        MOD(seq - 1, 16))::VARCHAR                     AS FACILITY_NAME,
    GET(ARRAY_CONSTRUCT('PHYSICIAN', 'PHYSICIAN', 'PHYSICIAN', 'PHYSICIAN', 'PHYSICIAN',
        'PHYSICIAN', 'PHYSICIAN', 'PHYSICIAN', 'PHYSICIAN', 'PHYSICIAN',
        'NP', 'NP', 'PA', 'PA', 'PHYSICIAN', 'PHYSICIAN'),
        MOD(seq - 1, 16))::VARCHAR                     AS PROVIDER_TYPE,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 80)));

-- ============================================================================
-- 4. DIM_DIAGNOSIS (200 common ICD-10 codes)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.DIM_DIAGNOSIS
    (DIAGNOSIS_KEY, ICD10_CODE, ICD10_DESC, ICD10_CHAPTER, HCC_CODE, HCC_DESC,
     CHRONIC_FLAG, CCS_CATEGORY, CLINICAL_DOMAIN)
SELECT
    seq                                                AS DIAGNOSIS_KEY,
    GET(ARRAY_CONSTRUCT(
        'I10', 'E11.9', 'J06.9', 'M54.5', 'I25.10', 'E78.5', 'J44.1', 'F32.9',
        'N18.3', 'I50.9', 'J18.9', 'K21.0', 'G47.33', 'M79.3', 'R05.9', 'E03.9',
        'J45.20', 'I48.91', 'E66.9', 'N39.0', 'K57.32', 'M17.11', 'G43.909', 'F41.1',
        'I63.9', 'C50.911', 'D64.9', 'L40.0', 'B34.9', 'J02.9', 'R10.9', 'M25.511',
        'R51.9', 'K59.00', 'E55.9', 'R73.03', 'Z87.891', 'J20.9', 'M62.81', 'N40.0'
    ), MOD(seq - 1, 40))::VARCHAR                      AS ICD10_CODE,
    GET(ARRAY_CONSTRUCT(
        'Essential hypertension', 'Type 2 diabetes without complications', 'Acute upper respiratory infection',
        'Low back pain', 'Atherosclerotic heart disease', 'Hyperlipidemia', 'COPD with acute exacerbation',
        'Major depressive disorder', 'Chronic kidney disease stage 3', 'Heart failure unspecified',
        'Pneumonia organism unspecified', 'GERD', 'Obstructive sleep apnea', 'Soft tissue disorder',
        'Cough', 'Hypothyroidism', 'Mild persistent asthma', 'Atrial fibrillation',
        'Obesity unspecified', 'Urinary tract infection', 'Diverticulosis with hemorrhage',
        'Primary osteoarthritis right knee', 'Migraine unspecified', 'Generalized anxiety disorder',
        'Cerebral infarction', 'Breast cancer female', 'Anemia unspecified', 'Psoriasis vulgaris',
        'Viral infection unspecified', 'Acute pharyngitis', 'Abdominal pain', 'Pain in right shoulder',
        'Headache', 'Constipation', 'Vitamin D deficiency', 'Prediabetes', 'Nicotine dependence history',
        'Acute bronchitis', 'Muscle weakness', 'Benign prostatic hyperplasia'
    ), MOD(seq - 1, 40))::VARCHAR                      AS ICD10_DESC,
    GET(ARRAY_CONSTRUCT(
        'Circulatory', 'Endocrine', 'Respiratory', 'Musculoskeletal', 'Circulatory', 'Endocrine',
        'Respiratory', 'Mental', 'Genitourinary', 'Circulatory', 'Respiratory', 'Digestive',
        'Nervous', 'Musculoskeletal', 'Respiratory', 'Endocrine', 'Respiratory', 'Circulatory',
        'Endocrine', 'Genitourinary', 'Digestive', 'Musculoskeletal', 'Nervous', 'Mental',
        'Circulatory', 'Neoplasm', 'Blood', 'Skin', 'Infectious', 'Respiratory', 'Symptoms',
        'Musculoskeletal', 'Symptoms', 'Digestive', 'Endocrine', 'Endocrine', 'Factors',
        'Respiratory', 'Musculoskeletal', 'Genitourinary'
    ), MOD(seq - 1, 40))::VARCHAR                      AS ICD10_CHAPTER,
    IFF(UNIFORM(0, 100, RANDOM()) < 40, 'HCC' || UNIFORM(1, 86, RANDOM())::VARCHAR, NULL) AS HCC_CODE,
    IFF(UNIFORM(0, 100, RANDOM()) < 40, 'HCC Category ' || UNIFORM(1, 86, RANDOM())::VARCHAR, NULL) AS HCC_DESC,
    IFF(MOD(seq - 1, 40) IN (0,1,4,5,6,7,8,9,16,17,18), TRUE, FALSE) AS CHRONIC_FLAG,
    'CCS-' || LPAD(MOD(seq - 1, 50)::VARCHAR + 100, 3, '0') AS CCS_CATEGORY,
    GET(ARRAY_CONSTRUCT('Cardiovascular', 'Metabolic', 'Respiratory', 'Musculoskeletal', 'Cardiovascular',
        'Metabolic', 'Respiratory', 'Behavioral', 'Renal', 'Cardiovascular', 'Respiratory', 'GI',
        'Neurological', 'Musculoskeletal', 'Respiratory', 'Metabolic', 'Respiratory', 'Cardiovascular',
        'Metabolic', 'Genitourinary', 'GI', 'Musculoskeletal', 'Neurological', 'Behavioral',
        'Cardiovascular', 'Oncology', 'Hematology', 'Dermatology', 'Infectious', 'Respiratory',
        'General', 'Musculoskeletal', 'General', 'GI', 'Metabolic', 'Metabolic', 'General',
        'Respiratory', 'Musculoskeletal', 'Genitourinary'),
        MOD(seq - 1, 40))::VARCHAR                     AS CLINICAL_DOMAIN
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 200)));

-- ============================================================================
-- 5. DIM_PAYER (15 payers)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.DIM_PAYER
    (PAYER_KEY, PAYER_ID, PAYER_NAME, PAYER_TYPE, PLAN_TYPE, NETWORK_TIER)
SELECT
    seq                                                AS PAYER_KEY,
    'PYR-' || LPAD(seq::VARCHAR, 3, '0')               AS PAYER_ID,
    GET(ARRAY_CONSTRUCT(
        'Aetna Commercial', 'UnitedHealthcare PPO', 'Blue Cross Blue Shield', 'Cigna HealthSpring',
        'Humana Gold Plus', 'Medicare Part A', 'Medicare Part B', 'Medicare Advantage',
        'Medicaid State Plan', 'Medicaid Managed Care', 'Kaiser Permanente', 'Anthem Blue Cross',
        'Molina Healthcare', 'Centene Corp', 'Self Pay'
    ), seq - 1)::VARCHAR                               AS PAYER_NAME,
    GET(ARRAY_CONSTRUCT(
        'COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL', 'COMMERCIAL',
        'MEDICARE', 'MEDICARE', 'MANAGED_CARE', 'MEDICAID', 'MANAGED_CARE',
        'COMMERCIAL', 'COMMERCIAL', 'MEDICAID', 'MANAGED_CARE', 'SELF_PAY'
    ), seq - 1)::VARCHAR                               AS PAYER_TYPE,
    GET(ARRAY_CONSTRUCT(
        'PPO', 'PPO', 'HMO', 'EPO', 'HMO',
        'FFS', 'FFS', 'MA-HMO', 'FFS', 'MCO',
        'HMO', 'PPO', 'MCO', 'MCO', 'NONE'
    ), seq - 1)::VARCHAR                               AS PLAN_TYPE,
    GET(ARRAY_CONSTRUCT('IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK',
        'IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK',
        'OUT_OF_NETWORK', 'IN_NETWORK', 'IN_NETWORK', 'IN_NETWORK', 'NONE'),
        seq - 1)::VARCHAR                              AS NETWORK_TIER
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 15)));

-- ============================================================================
-- 6. FACT_ENCOUNTER (~100,000 encounters over 5 years)
-- Seasonality: flu Oct-Mar (+30%), summer lull Jun-Aug (-20%), Q4 elective surge
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.FACT_ENCOUNTER
    (ENCOUNTER_ID, PATIENT_KEY, PROVIDER_KEY, PAYER_KEY, ADMIT_DATE_KEY, DISCHARGE_DATE_KEY,
     ENCOUNTER_TYPE, LOS_DAYS, DRG_CODE, DRG_WEIGHT, DIAGNOSIS_COUNT, PROCEDURE_COUNT,
     IS_READMISSION_30D, READMIT_DAYS, ED_VISIT_FLAG, ICU_FLAG, TOTAL_CHARGES, TOTAL_COST)
SELECT
    'ENC-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY, pat)::VARCHAR, 9, '0') AS ENCOUNTER_ID,
    pat                                                AS PATIENT_KEY,
    UNIFORM(1, 80, RANDOM())                           AS PROVIDER_KEY,
    UNIFORM(1, 15, RANDOM())                           AS PAYER_KEY,
    d.DATE_KEY                                         AS ADMIT_DATE_KEY,
    TO_NUMBER(TO_CHAR(DATEADD('day', GREATEST(0, ROUND(
        CASE
            WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 0
            WHEN UNIFORM(0, 100, RANDOM()) < 80 THEN NORMAL(1.5, 0.5, RANDOM())
            ELSE NORMAL(4.5, 2.5, RANDOM())
        END
    )), d.FULL_DATE), 'YYYYMMDD'))                     AS DISCHARGE_DATE_KEY,
    GET(ARRAY_CONSTRUCT('OUTPATIENT', 'OUTPATIENT', 'OUTPATIENT', 'OUTPATIENT', 'OUTPATIENT', 'OUTPATIENT',
        'INPATIENT', 'INPATIENT', 'ED', 'ED', 'TELEHEALTH', 'OBSERVATION'),
        UNIFORM(0, 11, RANDOM()))::VARCHAR             AS ENCOUNTER_TYPE,
    GREATEST(0, ROUND(
        CASE
            WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 0
            WHEN UNIFORM(0, 100, RANDOM()) < 80 THEN NORMAL(1.5, 0.5, RANDOM())
            ELSE NORMAL(4.5, 2.5, RANDOM())
        END, 1))                                       AS LOS_DAYS,
    IFF(UNIFORM(0, 100, RANDOM()) < 30,
        LPAD(UNIFORM(1, 999, RANDOM())::VARCHAR, 3, '0'), NULL) AS DRG_CODE,
    IFF(UNIFORM(0, 100, RANDOM()) < 30,
        GREATEST(0.5, LEAST(15.0, ROUND(NORMAL(1.8, 1.2, RANDOM()), 3))), NULL) AS DRG_WEIGHT,
    GREATEST(1, ROUND(NORMAL(3, 2, RANDOM())))::INT    AS DIAGNOSIS_COUNT,
    GREATEST(0, ROUND(NORMAL(1.5, 1.5, RANDOM())))::INT AS PROCEDURE_COUNT,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, TRUE, FALSE)   AS IS_READMISSION_30D,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, UNIFORM(1, 30, RANDOM()), NULL) AS READMIT_DAYS,
    IFF(UNIFORM(0, 100, RANDOM()) < 18, TRUE, FALSE)  AS ED_VISIT_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 5, TRUE, FALSE)   AS ICU_FLAG,
    ROUND(EXP(NORMAL(8.5, 1.2, RANDOM())), 2)         AS TOTAL_CHARGES,
    ROUND(EXP(NORMAL(8.0, 1.1, RANDOM())), 2)         AS TOTAL_COST
FROM MERIDIAN_HEALTH.GOLD.DIM_DATE d
CROSS JOIN (SELECT UNIFORM(1, 2000, RANDOM()) AS pat FROM TABLE(GENERATOR(ROWCOUNT => 8))) patients
WHERE UNIFORM(0, 100, RANDOM()) < (
      35
      + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11, 12, 1, 2, 3) THEN 12 ELSE 0 END
      - CASE WHEN MONTH(d.FULL_DATE) IN (6, 7, 8) THEN 8 ELSE 0 END
      + CASE WHEN MONTH(d.FULL_DATE) IN (10, 11) THEN 5 ELSE 0 END
  );

-- ============================================================================
-- 7. FACT_CLAIM (~300,000 claim lines from encounters)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.FACT_CLAIM
    (CLAIM_ID, CLAIM_LINE, PATIENT_KEY, PROVIDER_KEY, PAYER_KEY, SERVICE_DATE_KEY,
     ENCOUNTER_KEY, CPT_CODE, ICD10_PRIMARY, BILLED_AMOUNT, ALLOWED_AMOUNT,
     PAID_AMOUNT, PATIENT_RESP, DENIAL_FLAG, DENIAL_CODE, DAYS_TO_PAY, CLAIM_STATUS)
SELECT
    'CLM-' || LPAD(ROW_NUMBER() OVER (ORDER BY ENCOUNTER_KEY, line)::VARCHAR, 9, '0') AS CLAIM_ID,
    line                                               AS CLAIM_LINE,
    PATIENT_KEY                                        AS PATIENT_KEY,
    PROVIDER_KEY                                       AS PROVIDER_KEY,
    PAYER_KEY                                          AS PAYER_KEY,
    ADMIT_DATE_KEY                                     AS SERVICE_DATE_KEY,
    ENCOUNTER_KEY                                      AS ENCOUNTER_KEY,
    GET(ARRAY_CONSTRUCT(
        '99213', '99214', '99215', '99232', '99233', '99291', '36415', '71046',
        '80053', '85025', '93000', '99283', '99284', '99285', '43239', '27447',
        '99221', '99222', '99223', '99238'
    ), UNIFORM(0, 19, RANDOM()))::VARCHAR              AS CPT_CODE,
    GET(ARRAY_CONSTRUCT('I10', 'E11.9', 'J06.9', 'M54.5', 'I25.10', 'J44.1', 'F32.9', 'N18.3',
        'I50.9', 'J18.9', 'K21.0', 'J45.20', 'I48.91', 'E66.9', 'N39.0'),
        UNIFORM(0, 14, RANDOM()))::VARCHAR             AS ICD10_PRIMARY,
    -- Billed: log-normal
    ROUND(EXP(NORMAL(5.5, 1.0, RANDOM())), 2)         AS BILLED_AMOUNT,
    -- Allowed: 40-80% of billed
    ROUND(EXP(NORMAL(5.5, 1.0, RANDOM())) * UNIFORM(40, 80, RANDOM()) / 100.0, 2) AS ALLOWED_AMOUNT,
    -- Paid: 80-95% of allowed (unless denied)
    IFF(UNIFORM(0, 100, RANDOM()) < 12, 0,  -- 12% denial rate
        ROUND(EXP(NORMAL(5.5, 1.0, RANDOM())) * UNIFORM(40, 80, RANDOM()) / 100.0 * UNIFORM(80, 95, RANDOM()) / 100.0, 2)
    )                                                  AS PAID_AMOUNT,
    ROUND(EXP(NORMAL(3.5, 0.8, RANDOM())), 2)         AS PATIENT_RESP,
    IFF(UNIFORM(0, 100, RANDOM()) < 12, TRUE, FALSE)  AS DENIAL_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 12,
        GET(ARRAY_CONSTRUCT('CO-4', 'CO-16', 'CO-18', 'CO-29', 'CO-50', 'CO-97', 'PR-1', 'PR-2', 'PR-3', 'OA-23'),
            UNIFORM(0, 9, RANDOM()))::VARCHAR, NULL)   AS DENIAL_CODE,
    -- Days to pay: mostly 15-45, some slow >90
    GREATEST(5, ROUND(NORMAL(30, 15, RANDOM())
        * IFF(UNIFORM(0, 100, RANDOM()) < 5, 3.0, 1.0)))::INT AS DAYS_TO_PAY,
    IFF(UNIFORM(0, 100, RANDOM()) < 12, 'DENIED',
        IFF(UNIFORM(0, 100, RANDOM()) < 85, 'PAID', 'ADJUSTED')) AS CLAIM_STATUS
FROM MERIDIAN_HEALTH.GOLD.FACT_ENCOUNTER
CROSS JOIN (SELECT SEQ4() + 1 AS line FROM TABLE(GENERATOR(ROWCOUNT => 3))) lines -- avg 3 lines per encounter
WHERE UNIFORM(0, 100, RANDOM()) < 90; -- 90% of encounters generate claims

-- ============================================================================
-- 8. FACT_LAB_RESULT (~200,000 lab results)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.FACT_LAB_RESULT
    (PATIENT_KEY, ENCOUNTER_KEY, DATE_KEY, LOINC_CODE, TEST_NAME,
     RESULT_NUMERIC, ABNORMAL_FLAG, CRITICAL_FLAG, RESULT_CATEGORY)
SELECT
    PATIENT_KEY                                        AS PATIENT_KEY,
    ENCOUNTER_KEY                                      AS ENCOUNTER_KEY,
    ADMIT_DATE_KEY                                     AS DATE_KEY,
    GET(ARRAY_CONSTRUCT(
        '2345-7', '2160-0', '2951-2', '6690-2', '789-8', '4544-3',
        '718-7', '2093-3', '2085-9', '2571-8', '1742-6', '1920-8',
        '33914-3', '30313-1', '49765-1', '14749-6'
    ), UNIFORM(0, 15, RANDOM()))::VARCHAR              AS LOINC_CODE,
    GET(ARRAY_CONSTRUCT(
        'Glucose', 'Creatinine', 'Sodium', 'WBC Count', 'RBC Count', 'Hematocrit',
        'Hemoglobin', 'Total Cholesterol', 'HDL Cholesterol', 'Triglycerides',
        'ALT', 'AST', 'Troponin I', 'HbA1c', 'HbA1c (NGSP)', 'Glucose (fasting)'
    ), UNIFORM(0, 15, RANDOM()))::VARCHAR              AS TEST_NAME,
    -- Numeric results with realistic ranges and occasional abnormals
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        ROUND(NORMAL(100, 30, RANDOM())
            * IFF(UNIFORM(0, 100, RANDOM()) < 10, UNIFORM(150, 250, RANDOM()) / 100.0, 1.0), 4)
    )                                                  AS RESULT_NUMERIC,
    GET(ARRAY_CONSTRUCT('N', 'N', 'N', 'N', 'N', 'N', 'N', 'H', 'L', 'H'),
        UNIFORM(0, 9, RANDOM()))::VARCHAR              AS ABNORMAL_FLAG, -- ~20% abnormal
    IFF(UNIFORM(0, 100, RANDOM()) < 2, TRUE, FALSE)   AS CRITICAL_FLAG,
    GET(ARRAY_CONSTRUCT('CHEMISTRY', 'CHEMISTRY', 'CHEMISTRY', 'HEMATOLOGY', 'HEMATOLOGY',
        'HEMATOLOGY', 'HEMATOLOGY', 'LIPID', 'LIPID', 'LIPID', 'HEPATIC', 'HEPATIC',
        'CARDIAC', 'DIABETES', 'DIABETES', 'CHEMISTRY'),
        UNIFORM(0, 15, RANDOM()))::VARCHAR             AS RESULT_CATEGORY
FROM MERIDIAN_HEALTH.GOLD.FACT_ENCOUNTER
CROSS JOIN (SELECT SEQ4() + 1 AS lab_num FROM TABLE(GENERATOR(ROWCOUNT => 3))) labs
WHERE UNIFORM(0, 100, RANDOM()) < 70; -- 70% of encounters have lab work

-- ============================================================================
-- 9. AGG_PATIENT_RISK (monthly risk stratification)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.AGG_PATIENT_RISK
    (PATIENT_KEY, ASSESSMENT_MONTH, HCC_RISK_SCORE, READMISSION_RISK, ED_UTILIZATION_RISK,
     CHRONIC_CONDITION_COUNT, MEDICATION_COUNT, SDOH_COMPOSITE_SCORE, CARE_GAP_COUNT,
     LAST_PCP_VISIT_DAYS, OVERALL_RISK_TIER)
SELECT
    p.PATIENT_KEY                                      AS PATIENT_KEY,
    DATE_TRUNC('month', d.FULL_DATE)                   AS ASSESSMENT_MONTH,
    GREATEST(0.5, LEAST(6.0, ROUND(p.HCC_RISK_SCORE + NORMAL(0, 0.1, RANDOM()), 3))) AS HCC_RISK_SCORE,
    GREATEST(0.01, LEAST(0.85, ROUND(NORMAL(0.08, 0.06, RANDOM())
        * IFF(p.CHRONIC_CONDITION_COUNT > 3, 2.0, 1.0), 4))) AS READMISSION_RISK,
    GREATEST(0.01, LEAST(0.90, ROUND(NORMAL(0.12, 0.08, RANDOM())
        * IFF(p.SDOH_RISK_SCORE > 6, 1.5, 1.0), 4))) AS ED_UTILIZATION_RISK,
    p.CHRONIC_CONDITION_COUNT                          AS CHRONIC_CONDITION_COUNT,
    GREATEST(0, ROUND(NORMAL(3, 2.5, RANDOM())))::INT  AS MEDICATION_COUNT,
    p.SDOH_RISK_SCORE                                  AS SDOH_COMPOSITE_SCORE,
    GREATEST(0, ROUND(NORMAL(1.5, 1.5, RANDOM())))::INT AS CARE_GAP_COUNT,
    UNIFORM(1, 365, RANDOM())                          AS LAST_PCP_VISIT_DAYS,
    CASE
        WHEN NORMAL(0.08, 0.06, RANDOM()) > 0.15 THEN 'HIGH'
        WHEN NORMAL(0.08, 0.06, RANDOM()) > 0.06 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                AS OVERALL_RISK_TIER
FROM MERIDIAN_HEALTH.GOLD.DIM_PATIENT p
CROSS JOIN (
    SELECT DISTINCT DATE_TRUNC('month', FULL_DATE) AS FULL_DATE, DATE_KEY
    FROM MERIDIAN_HEALTH.GOLD.DIM_DATE
    WHERE DAY(FULL_DATE) = 1
) d
WHERE UNIFORM(0, 100, RANDOM()) < 50; -- sample 50% of patient-months

-- ============================================================================
-- 10. AGG_REVENUE_CYCLE (monthly by payer)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.AGG_REVENUE_CYCLE
    (PAYER_KEY, SERVICE_MONTH, CLAIMS_SUBMITTED, CLAIMS_PAID, CLAIMS_DENIED,
     DENIAL_RATE, TOTAL_BILLED, TOTAL_COLLECTED, COLLECTION_RATE, AVG_DAYS_TO_PAY,
     TOP_DENIAL_REASON)
SELECT
    PAYER_KEY,
    DATE_TRUNC('month', d.FULL_DATE)                   AS SERVICE_MONTH,
    COUNT(*)                                           AS CLAIMS_SUBMITTED,
    SUM(IFF(DENIAL_FLAG = FALSE, 1, 0))                AS CLAIMS_PAID,
    SUM(IFF(DENIAL_FLAG = TRUE, 1, 0))                 AS CLAIMS_DENIED,
    ROUND(AVG(IFF(DENIAL_FLAG, 1.0, 0.0)), 4)         AS DENIAL_RATE,
    ROUND(SUM(BILLED_AMOUNT), 2)                       AS TOTAL_BILLED,
    ROUND(SUM(PAID_AMOUNT), 2)                         AS TOTAL_COLLECTED,
    ROUND(SUM(PAID_AMOUNT) / NULLIF(SUM(BILLED_AMOUNT), 0), 4) AS COLLECTION_RATE,
    ROUND(AVG(DAYS_TO_PAY), 1)                         AS AVG_DAYS_TO_PAY,
    GET(ARRAY_CONSTRUCT('Missing prior auth', 'Duplicate claim', 'Non-covered service',
        'Timely filing', 'Invalid diagnosis code', 'Benefit maximum reached'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS TOP_DENIAL_REASON
FROM MERIDIAN_HEALTH.GOLD.FACT_CLAIM c
JOIN MERIDIAN_HEALTH.GOLD.DIM_DATE d ON c.SERVICE_DATE_KEY = d.DATE_KEY
GROUP BY PAYER_KEY, DATE_TRUNC('month', d.FULL_DATE);

-- ============================================================================
-- 11. AGG_READMISSION_COHORT (monthly by diagnosis)
-- ============================================================================
INSERT INTO MERIDIAN_HEALTH.GOLD.AGG_READMISSION_COHORT
    (DISCHARGE_MONTH, DIAGNOSIS_KEY, PATIENT_COUNT, READMIT_30D_COUNT, READMIT_30D_RATE,
     AVG_LOS, AVG_HCC_SCORE, AVG_AGE, SDOH_HIGH_RISK_PCT)
SELECT
    DATE_TRUNC('month', d.FULL_DATE)                   AS DISCHARGE_MONTH,
    UNIFORM(1, 200, RANDOM())                          AS DIAGNOSIS_KEY,
    COUNT(*)                                           AS PATIENT_COUNT,
    SUM(IFF(IS_READMISSION_30D, 1, 0))                AS READMIT_30D_COUNT,
    ROUND(AVG(IFF(IS_READMISSION_30D, 1.0, 0.0)), 4)  AS READMIT_30D_RATE,
    ROUND(AVG(LOS_DAYS), 1)                            AS AVG_LOS,
    ROUND(AVG(NORMAL(1.2, 0.5, RANDOM())), 3)          AS AVG_HCC_SCORE,
    ROUND(AVG(UNIFORM(25, 85, RANDOM())), 1)           AS AVG_AGE,
    ROUND(AVG(IFF(UNIFORM(0, 100, RANDOM()) < 25, 1.0, 0.0)), 4) AS SDOH_HIGH_RISK_PCT
FROM MERIDIAN_HEALTH.GOLD.FACT_ENCOUNTER e
JOIN MERIDIAN_HEALTH.GOLD.DIM_DATE d ON e.ADMIT_DATE_KEY = d.DATE_KEY
WHERE ENCOUNTER_TYPE = 'INPATIENT'
GROUP BY DATE_TRUNC('month', d.FULL_DATE), UNIFORM(1, 200, RANDOM());
