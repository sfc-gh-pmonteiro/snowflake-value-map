-- ============================================================================
-- PUBLIC SECTOR VERTICAL - Sample DDL
-- Source Systems: Tyler Technologies (Munis ERP, EnerGov Permitting),
--                 Motorola PremierOne (CAD/RMS), Salesforce 311 (Constituent Services),
--                 Esri ArcGIS (GIS/Parcels)
-- Entity: Civic Municipal Services
-- ============================================================================

CREATE DATABASE IF NOT EXISTS CIVIC_GOV;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS CIVIC_GOV.SILVER;

-- Source: Tyler Technologies EnerGov (Permitting)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.TYLER_PERMIT (
    PERMIT_ID           VARCHAR(20) NOT NULL,
    PERMIT_TYPE         VARCHAR(30),           -- BUILDING, ELECTRICAL, PLUMBING, MECHANICAL, DEMOLITION
    PARCEL_ID           VARCHAR(20),
    APPLICANT_NAME      VARCHAR(200),
    APPLICATION_DATE    DATE,
    ISSUED_DATE         DATE,
    EXPIRATION_DATE     DATE,
    VALUATION           NUMBER(12,2),
    STATUS              VARCHAR(20),           -- SUBMITTED, UNDER_REVIEW, APPROVED, ISSUED, EXPIRED, DENIED
    INSPECTOR_ID        VARCHAR(20),
    DEPARTMENT          VARCHAR(50),
    FEE_AMOUNT          NUMBER(10,2),
    PROJECT_DESC        VARCHAR(500),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Tyler EnerGov permits. Building and development permit lifecycle tracking.';

-- Source: Tyler Technologies EnerGov (Inspections)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.TYLER_INSPECTION (
    INSPECTION_ID       VARCHAR(20) NOT NULL,
    PERMIT_ID           VARCHAR(20),
    INSPECTION_TYPE     VARCHAR(30),           -- FOUNDATION, FRAMING, ELECTRICAL, PLUMBING, FINAL
    SCHEDULED_DATE      DATE,
    COMPLETED_DATE      DATE,
    INSPECTOR_ID        VARCHAR(20),
    RESULT              VARCHAR(20),           -- PASSED, FAILED, PARTIAL, CANCELLED, NO_ACCESS
    DEFICIENCY_COUNT    NUMBER(3),
    NOTES               VARCHAR(2000),
    REINSPECTION_REQUIRED BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Tyler EnerGov inspections. Permit inspection results and deficiencies.';

-- Source: Motorola PremierOne CAD (Computer-Aided Dispatch)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.MOTOROLA_CAD_INCIDENT (
    INCIDENT_ID         VARCHAR(20) NOT NULL,
    CALL_TYPE           VARCHAR(30),           -- THEFT, ASSAULT, BURGLARY, TRAFFIC_STOP, DOMESTIC, MEDICAL
    PRIORITY            VARCHAR(5),            -- P1 (life-threatening) through P5
    RECEIVED_TIME       TIMESTAMP_NTZ NOT NULL,
    DISPATCH_TIME       TIMESTAMP_NTZ,
    ARRIVAL_TIME        TIMESTAMP_NTZ,
    CLEAR_TIME          TIMESTAMP_NTZ,
    LOCATION_ADDRESS    VARCHAR(300),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    BEAT                VARCHAR(10),
    DISTRICT            VARCHAR(20),
    UNITS_ASSIGNED      NUMBER(3),
    DISPOSITION_CODE    VARCHAR(10),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Motorola PremierOne CAD incidents. 911/dispatch response tracking.';

-- Source: Motorola PremierOne RMS (Records Management)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.MOTOROLA_RMS_REPORT (
    REPORT_ID           VARCHAR(20) NOT NULL,
    INCIDENT_ID         VARCHAR(20),
    OFFENSE_CODE        VARCHAR(10),           -- UCR/NIBRS codes
    OFFENSE_DESC        VARCHAR(200),
    REPORT_DATE         DATE,
    VICTIM_COUNT        NUMBER(3),
    SUSPECT_COUNT       NUMBER(3),
    ARREST_FLAG         BOOLEAN,
    LOCATION_TYPE       VARCHAR(30),           -- RESIDENCE, COMMERCIAL, STREET, PARK, SCHOOL
    DISPOSITION         VARCHAR(20),           -- OPEN, CLEARED_ARREST, CLEARED_EXCEPTIONAL, UNFOUNDED
    WEAPON_INVOLVED     BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Motorola PremierOne RMS offense reports. Crime records for NIBRS/UCR reporting.';

-- Source: Salesforce 311 (Constituent Service Requests)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.SFDC_SERVICE_REQUEST (
    REQUEST_ID          VARCHAR(20) NOT NULL,
    CATEGORY            VARCHAR(30),           -- POTHOLE, STREETLIGHT, TRASH, NOISE, GRAFFITI, WATER
    SUBCATEGORY         VARCHAR(50),
    CHANNEL             VARCHAR(20),           -- PHONE, WEB, APP, WALK_IN, EMAIL, SOCIAL
    OPEN_DATE           TIMESTAMP_NTZ NOT NULL,
    CLOSE_DATE          TIMESTAMP_NTZ,
    STATUS              VARCHAR(20),           -- OPEN, IN_PROGRESS, PENDING, RESOLVED, CLOSED
    PRIORITY            VARCHAR(10),
    DEPARTMENT          VARCHAR(50),
    WARD                VARCHAR(5),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    RESOLUTION_CODE     VARCHAR(20),
    SATISFACTION_SCORE  NUMBER(2),             -- 1-10
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce 311 service requests. Constituent-reported issues and resolution tracking.';

-- Source: Tyler Munis (Budget)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.TYLER_BUDGET_LINE (
    BUDGET_ID           VARCHAR(20) NOT NULL,
    FISCAL_YEAR         NUMBER(4),
    FUND                VARCHAR(30),           -- GENERAL, ENTERPRISE, SPECIAL_REVENUE, CAPITAL
    DEPARTMENT          VARCHAR(50),
    PROGRAM             VARCHAR(50),
    ACCOUNT             VARCHAR(20),
    ACCOUNT_DESC        VARCHAR(100),
    BUDGETED_AMOUNT     NUMBER(12,2),
    ENCUMBERED_AMOUNT   NUMBER(12,2),
    ACTUAL_AMOUNT       NUMBER(12,2),
    PERIOD              NUMBER(2),             -- 1-12 fiscal period
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Tyler Munis budget lines. Appropriation vs actual by fund/dept/program.';

-- Source: Esri ArcGIS (Parcel Data)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.ESRI_PARCEL (
    PARCEL_ID           VARCHAR(20) NOT NULL,
    APN                 VARCHAR(20),           -- Assessor Parcel Number
    OWNER_NAME          VARCHAR(200),
    ADDRESS             VARCHAR(300),
    LAND_USE_CODE       VARCHAR(10),
    LAND_USE_DESC       VARCHAR(50),           -- RESIDENTIAL, COMMERCIAL, INDUSTRIAL, VACANT, PUBLIC
    ZONING              VARCHAR(10),
    ASSESSED_VALUE      NUMBER(12,2),
    LOT_SIZE_SQFT       NUMBER(10),
    YEAR_BUILT          NUMBER(4),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    CENSUS_TRACT        VARCHAR(15),
    WARD                VARCHAR(5),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Esri ArcGIS parcel records. Property and land use from county assessor.';

-- Source: Tyler EnerGov (Code Violations)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.TYLER_CODE_VIOLATION (
    VIOLATION_ID        VARCHAR(20) NOT NULL,
    PARCEL_ID           VARCHAR(20),
    VIOLATION_TYPE      VARCHAR(30),           -- OVERGROWN, JUNK_VEHICLE, STRUCTURAL, SIGNAGE, ZONING
    REPORTED_DATE       DATE,
    INSPECTION_DATE     DATE,
    COMPLIANCE_DATE     DATE,
    STATUS              VARCHAR(20),           -- OPEN, NOTICE_SENT, HEARING, COMPLIANT, LIEN_FILED
    FINE_AMOUNT         NUMBER(10,2),
    INSPECTOR_ID        VARCHAR(20),
    REPORTER_TYPE       VARCHAR(20),           -- CITIZEN, INSPECTOR, ELECTED_OFFICIAL
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Tyler EnerGov code enforcement violations. Property maintenance compliance.';

-- Source: Salesforce 311 (Constituent Profiles)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.SFDC_CONSTITUENT (
    CONSTITUENT_ID      VARCHAR(20) NOT NULL,
    NAME                VARCHAR(200),
    ADDRESS             VARCHAR(300),
    WARD                VARCHAR(5),
    EMAIL               VARCHAR(200),
    PHONE               VARCHAR(20),
    PREFERRED_CHANNEL   VARCHAR(20),
    INTERACTION_COUNT   NUMBER(5),
    FIRST_CONTACT_DATE  DATE,
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce 311 constituent profiles - SCD2. Citizen engagement history.';

-- Source: Tyler Munis (Revenue)
CREATE OR REPLACE TABLE CIVIC_GOV.SILVER.TYLER_REVENUE (
    REVENUE_ID          VARCHAR(20) NOT NULL,
    SOURCE_TYPE         VARCHAR(30),           -- PROPERTY_TAX, SALES_TAX, FEES, FINES, INTERGOVERNMENTAL
    AMOUNT              NUMBER(12,2),
    TRANSACTION_DATE    DATE,
    PAYER               VARCHAR(200),
    DEPARTMENT          VARCHAR(50),
    FUND                VARCHAR(30),
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Tyler Munis revenue transactions. Tax, fee, and fine collections.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS CIVIC_GOV.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.DIM_DEPARTMENT (
    DEPT_KEY            NUMBER AUTOINCREMENT,
    DEPT_CODE           VARCHAR(20) NOT NULL,
    DEPT_NAME           VARCHAR(100),
    DIVISION            VARCHAR(100),
    FUND                VARCHAR(30),
    DIRECTOR_NAME       VARCHAR(100),
    EMPLOYEE_COUNT      NUMBER(5)
) COMMENT = 'Department dimension. Organizational structure and fund allocation.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.DIM_LOCATION (
    LOCATION_KEY        NUMBER AUTOINCREMENT,
    ADDRESS             VARCHAR(300),
    WARD                VARCHAR(5),
    DISTRICT            VARCHAR(20),
    BEAT                VARCHAR(10),
    PARCEL_ID           VARCHAR(20),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    CENSUS_TRACT        VARCHAR(15),
    LAND_USE_CODE       VARCHAR(10),
    ZONING              VARCHAR(10)
) COMMENT = 'Location dimension. Unified geography across services, safety, and parcels.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_WEEKEND          BOOLEAN,
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2),
    IS_HOLIDAY          BOOLEAN
) COMMENT = 'Date dimension with fiscal year alignment for government accounting.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.DIM_OFFENSE (
    OFFENSE_KEY         NUMBER AUTOINCREMENT,
    OFFENSE_CODE        VARCHAR(10) NOT NULL,
    OFFENSE_DESC        VARCHAR(200),
    CATEGORY            VARCHAR(50),           -- VIOLENT, PROPERTY, DRUG, TRAFFIC, OTHER
    SEVERITY            VARCHAR(20),           -- FELONY, MISDEMEANOR, INFRACTION
    NIBRS_GROUP         VARCHAR(5)
) COMMENT = 'Offense/crime type dimension. UCR/NIBRS classification hierarchy.';

-- Facts
CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.FACT_SERVICE_REQUEST (
    DATE_KEY            NUMBER,
    LOCATION_KEY        NUMBER,
    DEPT_KEY            NUMBER,
    CATEGORY            VARCHAR(30),
    REQUESTS_OPENED     NUMBER(5),
    REQUESTS_CLOSED     NUMBER(5),
    AVG_RESOLUTION_DAYS NUMBER(7,2),
    SATISFACTION_AVG    NUMBER(4,2),
    OVERDUE_COUNT       NUMBER(5),
    CHANNEL             VARCHAR(20)
) COMMENT = 'Service request fact. 311/constituent service volume and responsiveness.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.FACT_PUBLIC_SAFETY (
    DATE_KEY            NUMBER,
    LOCATION_KEY        NUMBER,
    OFFENSE_KEY         NUMBER,
    INCIDENTS           NUMBER(5),
    RESPONSE_TIME_MINUTES NUMBER(7,2),
    ARRESTS             NUMBER(5),
    CLEARANCE_FLAG      BOOLEAN,
    UNITS_DEPLOYED      NUMBER(3),
    PRIORITY            VARCHAR(5)
) COMMENT = 'Public safety incident fact. Response times, clearance, and deployment.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.FACT_PERMIT_ACTIVITY (
    DATE_KEY            NUMBER,
    LOCATION_KEY        NUMBER,
    DEPT_KEY            NUMBER,
    PERMIT_TYPE         VARCHAR(30),
    PERMITS_APPLIED     NUMBER(5),
    PERMITS_ISSUED      NUMBER(5),
    PERMITS_DENIED      NUMBER(5),
    AVG_REVIEW_DAYS     NUMBER(7,2),
    TOTAL_VALUATION     NUMBER(12,2),
    INSPECTIONS_COMPLETED NUMBER(5),
    INSPECTION_PASS_RATE NUMBER(5,4)
) COMMENT = 'Permit activity fact. Development velocity and review efficiency.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.FACT_BUDGET_EXECUTION (
    DATE_KEY            NUMBER,
    DEPT_KEY            NUMBER,
    FUND                VARCHAR(30),
    PROGRAM             VARCHAR(50),
    BUDGETED            NUMBER(12,2),
    ENCUMBERED          NUMBER(12,2),
    ACTUAL              NUMBER(12,2),
    VARIANCE_PCT        NUMBER(7,4),
    AVAILABLE_BALANCE   NUMBER(12,2)
) COMMENT = 'Budget execution fact. Appropriation vs expenditure by period.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.FACT_CODE_COMPLIANCE (
    DATE_KEY            NUMBER,
    LOCATION_KEY        NUMBER,
    VIOLATION_TYPE      VARCHAR(30),
    VIOLATIONS_OPENED   NUMBER(5),
    VIOLATIONS_CLOSED   NUMBER(5),
    FINES_ISSUED        NUMBER(10,2),
    FINES_COLLECTED     NUMBER(10,2),
    COMPLIANCE_RATE_PCT NUMBER(5,4),
    AVG_DAYS_TO_COMPLY  NUMBER(7,2)
) COMMENT = 'Code compliance fact. Violation lifecycle and fine recovery metrics.';

-- Aggregates
CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.AGG_WARD_SCORECARD (
    MONTH_KEY           NUMBER,
    WARD                VARCHAR(5),
    SERVICE_REQUESTS    NUMBER(10),
    AVG_RESOLUTION_DAYS NUMBER(7,2),
    SAFETY_INCIDENTS    NUMBER(10),
    RESPONSE_TIME_AVG   NUMBER(7,2),
    PERMITS_ISSUED      NUMBER(5),
    CODE_VIOLATIONS     NUMBER(5),
    SATISFACTION_AVG    NUMBER(4,2),
    PROPERTY_VALUE_AVG  NUMBER(12,2)
) COMMENT = 'Monthly ward-level scorecard. Holistic neighborhood health composite.';

CREATE OR REPLACE TABLE CIVIC_GOV.GOLD.AGG_DEPARTMENT_KPI (
    MONTH_KEY           NUMBER,
    DEPT_KEY            NUMBER,
    BUDGET_UTILIZATION_PCT NUMBER(5,4),
    SERVICE_LEVEL_PCT   NUMBER(5,4),
    BACKLOG_COUNT       NUMBER(10),
    AVG_CYCLE_TIME_DAYS NUMBER(7,2),
    CITIZEN_SATISFACTION_AVG NUMBER(4,2),
    YEAR_OVER_YEAR_TREND VARCHAR(10)           -- IMPROVING, STABLE, DECLINING
) COMMENT = 'Monthly department KPI aggregate. Performance management and accountability.';

