-- ============================================================================
-- HEALTHCARE VERTICAL - Sample DDL
-- Source Systems: Epic (EHR), Availity (Claims Clearinghouse), Salesforce Health Cloud,
--                 Cerner PathNet (Labs), Custom SDOH Platform
-- Entity: Meridian Health System
-- ============================================================================

CREATE DATABASE IF NOT EXISTS MERIDIAN_HEALTH;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS MERIDIAN_HEALTH.SILVER;

-- Source: Epic (EHR - Patient Demographics)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_PATIENT (
    PATIENT_ID          VARCHAR(20) NOT NULL,
    MRN                 VARCHAR(20),
    FIRST_NAME          VARCHAR(100),
    LAST_NAME           VARCHAR(100),
    DATE_OF_BIRTH       DATE,
    GENDER              VARCHAR(10),
    RACE                VARCHAR(50),
    ETHNICITY           VARCHAR(50),
    LANGUAGE_PREFERRED  VARCHAR(30),
    ADDRESS_LINE_1      VARCHAR(200),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    COUNTY_FIPS         VARCHAR(10),
    PHONE               VARCHAR(20),
    EMAIL               VARCHAR(200),
    PRIMARY_CARE_PROVIDER_ID VARCHAR(20),
    INSURANCE_CLASS     VARCHAR(20),       -- COMMERCIAL, MEDICARE, MEDICAID, SELF_PAY
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic EHR Patient demographics - SCD2. Source: Epic Clarity PAT table.';

-- Source: Epic (EHR - Encounters)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_ENCOUNTER (
    ENCOUNTER_ID        VARCHAR(20) NOT NULL,
    PATIENT_ID          VARCHAR(20),
    ENCOUNTER_TYPE      VARCHAR(30),       -- INPATIENT, OUTPATIENT, ED, TELEHEALTH, OBSERVATION
    DEPARTMENT_ID       VARCHAR(20),
    DEPARTMENT_NAME     VARCHAR(100),
    FACILITY_ID         VARCHAR(20),
    ADMITTING_PROVIDER_ID VARCHAR(20),
    ATTENDING_PROVIDER_ID VARCHAR(20),
    ADMIT_DATETIME      TIMESTAMP_NTZ,
    DISCHARGE_DATETIME  TIMESTAMP_NTZ,
    LOS_DAYS            NUMBER(5,1),
    DISCHARGE_DISPOSITION VARCHAR(50),
    DRG_CODE            VARCHAR(10),
    DRG_WEIGHT          NUMBER(5,3),
    ADMISSION_SOURCE    VARCHAR(50),
    PRIMARY_DIAGNOSIS_ICD VARCHAR(10),
    STATUS              VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic EHR Encounters/Visits. Source: Epic Clarity HSP/PAT_ENC tables.';

-- Source: Epic (EHR - Diagnoses)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_DIAGNOSIS (
    DIAGNOSIS_ID        VARCHAR(30) NOT NULL,
    ENCOUNTER_ID        VARCHAR(20),
    PATIENT_ID          VARCHAR(20),
    ICD10_CODE          VARCHAR(10) NOT NULL,
    ICD10_DESC          VARCHAR(300),
    DIAGNOSIS_TYPE      VARCHAR(20),       -- ADMITTING, PRIMARY, SECONDARY, PROBLEM_LIST
    ONSET_DATE          DATE,
    RESOLVED_DATE       DATE,
    CHRONIC_FLAG        BOOLEAN,
    HCC_CODE            VARCHAR(10),
    PROVIDER_ID         VARCHAR(20),
    RECORDED_DATE       TIMESTAMP_NTZ,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic EHR Diagnosis records. ICD-10 coded. Source: Epic Clarity DX tables.';

-- Source: Epic (EHR - Medications)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_MEDICATION_ORDER (
    ORDER_ID            VARCHAR(30) NOT NULL,
    ENCOUNTER_ID        VARCHAR(20),
    PATIENT_ID          VARCHAR(20),
    MEDICATION_ID       VARCHAR(20),
    MEDICATION_NAME     VARCHAR(200),
    NDC_CODE            VARCHAR(15),
    RXNORM_CODE         VARCHAR(15),
    DOSE                VARCHAR(50),
    ROUTE               VARCHAR(30),
    FREQUENCY           VARCHAR(50),
    ORDER_DATETIME      TIMESTAMP_NTZ,
    START_DATE          DATE,
    END_DATE            DATE,
    PRESCRIBING_PROVIDER_ID VARCHAR(20),
    ORDER_STATUS        VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic EHR Medication orders. Source: Epic Clarity ORDER_MED tables.';

-- Source: Cerner PathNet (Lab Results)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.CERNER_LAB_RESULT (
    RESULT_ID           VARCHAR(30) NOT NULL,
    ORDER_ID            VARCHAR(30),
    PATIENT_ID          VARCHAR(20),
    ENCOUNTER_ID        VARCHAR(20),
    LOINC_CODE          VARCHAR(15),
    TEST_NAME           VARCHAR(200),
    RESULT_VALUE        VARCHAR(100),
    RESULT_NUMERIC      NUMBER(15,4),
    RESULT_UNITS        VARCHAR(20),
    REFERENCE_LOW       NUMBER(15,4),
    REFERENCE_HIGH      NUMBER(15,4),
    ABNORMAL_FLAG       VARCHAR(5),        -- H (high), L (low), C (critical), N (normal)
    SPECIMEN_TYPE       VARCHAR(50),
    COLLECTED_DATETIME  TIMESTAMP_NTZ,
    RESULT_DATETIME     TIMESTAMP_NTZ,
    STATUS              VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Cerner PathNet Lab results. LOINC coded. Source: Cerner Millennium.';

-- Source: Epic (EHR - Vitals)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_VITAL_SIGN (
    VITAL_ID            VARCHAR(30) NOT NULL,
    ENCOUNTER_ID        VARCHAR(20),
    PATIENT_ID          VARCHAR(20),
    RECORDED_DATETIME   TIMESTAMP_NTZ NOT NULL,
    BP_SYSTOLIC         NUMBER(5),
    BP_DIASTOLIC        NUMBER(5),
    HEART_RATE          NUMBER(5),
    RESPIRATORY_RATE    NUMBER(5),
    TEMPERATURE_F       NUMBER(5,1),
    SPO2_PCT            NUMBER(5,1),
    WEIGHT_KG           NUMBER(5,1),
    HEIGHT_CM           NUMBER(5,1),
    BMI                 NUMBER(5,1),
    PAIN_SCORE          NUMBER(2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic EHR Vital signs. Source: Epic Clarity IP_FLWSHT tables.';

-- Source: Epic (EHR - Providers)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_PROVIDER (
    PROVIDER_ID         VARCHAR(20) NOT NULL,
    NPI                 VARCHAR(15),
    FIRST_NAME          VARCHAR(100),
    LAST_NAME           VARCHAR(100),
    SPECIALTY           VARCHAR(100),
    DEPARTMENT_ID       VARCHAR(20),
    FACILITY_ID         VARCHAR(20),
    PROVIDER_TYPE       VARCHAR(30),       -- PHYSICIAN, NP, PA, RN
    IS_ACTIVE           BOOLEAN,
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic EHR Provider directory - SCD2. Source: Epic Clarity SER table.';

-- Source: Availity (Claims Clearinghouse)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.AVAILITY_CLAIM (
    CLAIM_ID            VARCHAR(30) NOT NULL,
    CLAIM_LINE          NUMBER(5) NOT NULL,
    PATIENT_ID          VARCHAR(20),
    ENCOUNTER_ID        VARCHAR(20),
    MEMBER_ID           VARCHAR(30),
    PAYER_ID            VARCHAR(20),
    PAYER_NAME          VARCHAR(200),
    CLAIM_TYPE          VARCHAR(10),       -- I (institutional), P (professional)
    SERVICE_FROM_DATE   DATE,
    SERVICE_TO_DATE     DATE,
    CPT_CODE            VARCHAR(10),
    CPT_MODIFIER        VARCHAR(10),
    ICD10_PRIMARY       VARCHAR(10),
    ICD10_SECONDARY     ARRAY,
    BILLED_AMOUNT       NUMBER(12,2),
    ALLOWED_AMOUNT      NUMBER(12,2),
    PAID_AMOUNT         NUMBER(12,2),
    PATIENT_RESP        NUMBER(12,2),
    CLAIM_STATUS        VARCHAR(20),       -- SUBMITTED, ACCEPTED, DENIED, PAID, ADJUSTED
    DENIAL_CODE         VARCHAR(10),
    DENIAL_REASON       VARCHAR(200),
    SUBMITTED_DATE      DATE,
    ADJUDICATED_DATE    DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Availity claims clearinghouse. 837/835 data. Institutional and professional claims.';

-- Source: Salesforce Health Cloud (CRM / Care Management)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.SFDC_CARE_PLAN (
    CARE_PLAN_ID        VARCHAR(30) NOT NULL,
    PATIENT_ID          VARCHAR(20),
    PLAN_TYPE           VARCHAR(50),       -- CHRONIC_DISEASE, POST_DISCHARGE, WELLNESS
    STATUS              VARCHAR(20),
    ASSIGNED_CARE_MANAGER VARCHAR(50),
    START_DATE          DATE,
    END_DATE            DATE,
    GOALS               VARIANT,           -- JSON array of care goals
    INTERVENTIONS       VARIANT,           -- JSON array of planned interventions
    RISK_SCORE          NUMBER(5,2),
    LAST_CONTACT_DATE   DATE,
    NEXT_CONTACT_DATE   DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce Health Cloud care plans. Source: SFDC CarePlan object.';

-- Source: Salesforce Health Cloud (Patient Interactions)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.SFDC_PATIENT_INTERACTION (
    INTERACTION_ID      VARCHAR(30) NOT NULL,
    PATIENT_ID          VARCHAR(20),
    CARE_PLAN_ID        VARCHAR(30),
    INTERACTION_TYPE    VARCHAR(30),       -- PHONE, EMAIL, SMS, PORTAL, IN_PERSON
    DIRECTION           VARCHAR(10),       -- INBOUND, OUTBOUND
    SUBJECT             VARCHAR(200),
    NOTES               VARCHAR(4000),
    OUTCOME             VARCHAR(50),
    AGENT_ID            VARCHAR(50),
    INTERACTION_DATETIME TIMESTAMP_NTZ,
    DURATION_MINUTES    NUMBER(5),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce Health Cloud interactions/activities. Source: SFDC Task/Activity.';

-- Source: Custom SDOH Platform
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.SDOH_PATIENT_RISK (
    PATIENT_ID          VARCHAR(20) NOT NULL,
    ASSESSMENT_DATE     DATE NOT NULL,
    FOOD_INSECURITY_FLAG BOOLEAN,
    HOUSING_INSTABILITY_FLAG BOOLEAN,
    TRANSPORTATION_BARRIER_FLAG BOOLEAN,
    SOCIAL_ISOLATION_FLAG BOOLEAN,
    FINANCIAL_STRAIN_FLAG BOOLEAN,
    ADI_NATIONAL_RANK   NUMBER(3),         -- Area Deprivation Index (1-100)
    CENSUS_TRACT        VARCHAR(15),
    SDOH_COMPOSITE_SCORE NUMBER(5,2),
    DATA_SOURCE         VARCHAR(30),       -- SCREENING, CENSUS, Z_CODE
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Social Determinants of Health risk factors. Composite from screening + census.';

-- Source: Epic (EHR - FHIR Resources as semi-structured)
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.SILVER.EPIC_FHIR_RESOURCE (
    RESOURCE_ID         VARCHAR(50) NOT NULL,
    RESOURCE_TYPE       VARCHAR(30),       -- Patient, Condition, MedicationRequest, Observation
    PATIENT_ID          VARCHAR(20),
    FHIR_PAYLOAD        VARIANT NOT NULL,  -- Full FHIR R4 JSON resource
    LAST_UPDATED        TIMESTAMP_NTZ,
    VERSION_ID          NUMBER(10),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Epic FHIR R4 resources stored as VARIANT. Supports flexible querying of clinical data.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS MERIDIAN_HEALTH.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.DIM_PATIENT (
    PATIENT_KEY         NUMBER AUTOINCREMENT,
    PATIENT_ID          VARCHAR(20) NOT NULL,
    MRN                 VARCHAR(20),
    AGE                 NUMBER(3),
    AGE_GROUP           VARCHAR(20),
    GENDER              VARCHAR(10),
    RACE                VARCHAR(50),
    ETHNICITY           VARCHAR(50),
    ZIP_CODE            VARCHAR(10),
    COUNTY_FIPS         VARCHAR(10),
    INSURANCE_CLASS     VARCHAR(20),
    PCP_PROVIDER_ID     VARCHAR(20),
    CHRONIC_CONDITION_COUNT NUMBER(3),
    HCC_RISK_SCORE      NUMBER(5,3),
    SDOH_RISK_SCORE     NUMBER(5,2),
    LAST_ENCOUNTER_DATE DATE,
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Patient dimension - SCD2. Enriched with risk scores and chronic conditions.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.DIM_PROVIDER (
    PROVIDER_KEY        NUMBER AUTOINCREMENT,
    PROVIDER_ID         VARCHAR(20) NOT NULL,
    NPI                 VARCHAR(15),
    PROVIDER_NAME       VARCHAR(200),
    SPECIALTY           VARCHAR(100),
    SPECIALTY_CATEGORY  VARCHAR(50),
    DEPARTMENT_NAME     VARCHAR(100),
    FACILITY_NAME       VARCHAR(100),
    PROVIDER_TYPE       VARCHAR(30),
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Provider dimension. Conformed from Epic + credentialing.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.DIM_DIAGNOSIS (
    DIAGNOSIS_KEY       NUMBER AUTOINCREMENT,
    ICD10_CODE          VARCHAR(10) NOT NULL,
    ICD10_DESC          VARCHAR(300),
    ICD10_CHAPTER       VARCHAR(100),
    HCC_CODE            VARCHAR(10),
    HCC_DESC            VARCHAR(200),
    CHRONIC_FLAG        BOOLEAN,
    CCS_CATEGORY        VARCHAR(100),
    CLINICAL_DOMAIN     VARCHAR(50)
) COMMENT = 'Diagnosis dimension. ICD-10 with HCC and CCS groupings.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.DIM_PAYER (
    PAYER_KEY           NUMBER AUTOINCREMENT,
    PAYER_ID            VARCHAR(20) NOT NULL,
    PAYER_NAME          VARCHAR(200),
    PAYER_TYPE          VARCHAR(30),       -- COMMERCIAL, MEDICARE, MEDICAID, MANAGED_CARE
    PLAN_TYPE           VARCHAR(30),
    NETWORK_TIER        VARCHAR(20)
) COMMENT = 'Payer/Insurance dimension.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2),
    IS_WORKING_DAY      BOOLEAN
) COMMENT = 'Standard date dimension.';

-- Facts
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.FACT_ENCOUNTER (
    ENCOUNTER_KEY       NUMBER AUTOINCREMENT,
    ENCOUNTER_ID        VARCHAR(20),
    PATIENT_KEY         NUMBER,
    PROVIDER_KEY        NUMBER,
    PAYER_KEY           NUMBER,
    ADMIT_DATE_KEY      NUMBER,
    DISCHARGE_DATE_KEY  NUMBER,
    ENCOUNTER_TYPE      VARCHAR(30),
    LOS_DAYS            NUMBER(5,1),
    DRG_CODE            VARCHAR(10),
    DRG_WEIGHT          NUMBER(5,3),
    DIAGNOSIS_COUNT     NUMBER(3),
    PROCEDURE_COUNT     NUMBER(3),
    IS_READMISSION_30D  BOOLEAN,
    READMIT_DAYS        NUMBER(5),
    ED_VISIT_FLAG       BOOLEAN,
    ICU_FLAG            BOOLEAN,
    TOTAL_CHARGES       NUMBER(12,2),
    TOTAL_COST          NUMBER(12,2)
) COMMENT = 'Encounter fact. Core clinical activity grain. Readmission flags pre-computed.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.FACT_CLAIM (
    CLAIM_KEY           NUMBER AUTOINCREMENT,
    CLAIM_ID            VARCHAR(30),
    CLAIM_LINE          NUMBER(5),
    PATIENT_KEY         NUMBER,
    PROVIDER_KEY        NUMBER,
    PAYER_KEY           NUMBER,
    SERVICE_DATE_KEY    NUMBER,
    ENCOUNTER_KEY       NUMBER,
    CPT_CODE            VARCHAR(10),
    ICD10_PRIMARY       VARCHAR(10),
    BILLED_AMOUNT       NUMBER(12,2),
    ALLOWED_AMOUNT      NUMBER(12,2),
    PAID_AMOUNT         NUMBER(12,2),
    PATIENT_RESP        NUMBER(12,2),
    DENIAL_FLAG         BOOLEAN,
    DENIAL_CODE         VARCHAR(10),
    DAYS_TO_PAY         NUMBER(5),
    CLAIM_STATUS        VARCHAR(20)
) COMMENT = 'Claims fact at line level. Revenue cycle and denial analytics.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.FACT_LAB_RESULT (
    LAB_KEY             NUMBER AUTOINCREMENT,
    PATIENT_KEY         NUMBER,
    ENCOUNTER_KEY       NUMBER,
    DATE_KEY            NUMBER,
    LOINC_CODE          VARCHAR(15),
    TEST_NAME           VARCHAR(200),
    RESULT_NUMERIC      NUMBER(15,4),
    ABNORMAL_FLAG       VARCHAR(5),
    CRITICAL_FLAG       BOOLEAN,
    RESULT_CATEGORY     VARCHAR(20)
) COMMENT = 'Lab result fact. Supports clinical trending and population analytics.';

-- Aggregates
CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.AGG_PATIENT_RISK (
    PATIENT_KEY         NUMBER,
    ASSESSMENT_MONTH    DATE,
    HCC_RISK_SCORE      NUMBER(5,3),
    READMISSION_RISK    NUMBER(5,4),
    ED_UTILIZATION_RISK NUMBER(5,4),
    CHRONIC_CONDITION_COUNT NUMBER(3),
    MEDICATION_COUNT    NUMBER(3),
    SDOH_COMPOSITE_SCORE NUMBER(5,2),
    CARE_GAP_COUNT      NUMBER(3),
    LAST_PCP_VISIT_DAYS NUMBER(5),
    OVERALL_RISK_TIER   VARCHAR(10)        -- HIGH, MEDIUM, LOW
) COMMENT = 'Monthly patient risk stratification. Powers population health dashboards.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.AGG_REVENUE_CYCLE (
    PAYER_KEY           NUMBER,
    SERVICE_MONTH       DATE,
    CLAIMS_SUBMITTED    NUMBER(10),
    CLAIMS_PAID         NUMBER(10),
    CLAIMS_DENIED       NUMBER(10),
    DENIAL_RATE         NUMBER(5,4),
    TOTAL_BILLED        NUMBER(15,2),
    TOTAL_COLLECTED     NUMBER(15,2),
    COLLECTION_RATE     NUMBER(5,4),
    AVG_DAYS_TO_PAY     NUMBER(5,1),
    TOP_DENIAL_REASON   VARCHAR(200)
) COMMENT = 'Monthly revenue cycle metrics by payer. Denial analytics and A/R trending.';

CREATE OR REPLACE TABLE MERIDIAN_HEALTH.GOLD.AGG_READMISSION_COHORT (
    DISCHARGE_MONTH     DATE,
    DIAGNOSIS_KEY       NUMBER,
    PATIENT_COUNT       NUMBER(10),
    READMIT_30D_COUNT   NUMBER(10),
    READMIT_30D_RATE    NUMBER(5,4),
    AVG_LOS             NUMBER(5,1),
    AVG_HCC_SCORE       NUMBER(5,3),
    AVG_AGE             NUMBER(5,1),
    SDOH_HIGH_RISK_PCT  NUMBER(5,4)
) COMMENT = 'Monthly readmission cohort analysis by diagnosis. For CMS quality reporting.';

