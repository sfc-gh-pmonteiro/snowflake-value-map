-- ============================================================================
-- ENERGY & UTILITIES VERTICAL - Sample DDL
-- Source Systems: Oracle Utilities CC&B (Billing/CIS), GE ADMS (Grid Management),
--                 Itron AMI (Smart Meters), GE Grid Solutions (SCADA),
--                 SAP PM (Asset Management)
-- Entity: Meridian Energy Corp
-- ============================================================================

CREATE DATABASE IF NOT EXISTS MERIDIAN_ENERGY;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS MERIDIAN_ENERGY.SILVER;

-- Source: Itron AMI (Advanced Metering Infrastructure)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.ITRON_METER_READING (
    METER_ID            VARCHAR(20) NOT NULL,
    ACCOUNT_ID          VARCHAR(20),
    READING_TIMESTAMP   TIMESTAMP_NTZ NOT NULL,
    KWH_DELIVERED       NUMBER(12,3),
    KWH_RECEIVED        NUMBER(12,3),        -- Net metering / solar buyback
    DEMAND_KW           NUMBER(10,3),
    VOLTAGE             NUMBER(7,2),
    POWER_FACTOR        NUMBER(5,4),
    INTERVAL_MINUTES    NUMBER(3),            -- 15 or 60
    QUALITY_FLAG        VARCHAR(10),          -- ACTUAL, ESTIMATED, SUBSTITUTED
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Itron AMI meter readings. 15-min interval data from smart meters via headend system.';

-- Source: Oracle Utilities CC&B (Customer Information System)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.ORACLE_CUSTOMER_ACCOUNT (
    ACCOUNT_ID          VARCHAR(20) NOT NULL,
    CUSTOMER_NAME       VARCHAR(200),
    SERVICE_ADDRESS     VARCHAR(300),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    METER_ID            VARCHAR(20),
    RATE_CLASS          VARCHAR(20),           -- RESIDENTIAL, COMMERCIAL, INDUSTRIAL, AGRICULTURAL
    SERVICE_TYPE        VARCHAR(20),           -- ELECTRIC, GAS, COMBO
    ACCOUNT_STATUS      VARCHAR(20),           -- ACTIVE, INACTIVE, FINAL_BILLED
    BUDGET_BILLING_FLAG BOOLEAN,
    MEDICAL_BASELINE_FLAG BOOLEAN,
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle CC&B Customer accounts - SCD2. Source: CC&B CI_ACCT/CI_PREM tables.';

-- Source: GE ADMS (Advanced Distribution Management System)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.GE_ADMS_OUTAGE_EVENT (
    OUTAGE_ID           VARCHAR(30) NOT NULL,
    FEEDER_ID           VARCHAR(20),
    SUBSTATION_ID       VARCHAR(20),
    START_TIME          TIMESTAMP_NTZ NOT NULL,
    END_TIME            TIMESTAMP_NTZ,
    CUSTOMERS_AFFECTED  NUMBER(10),
    CAUSE_CODE          VARCHAR(20),           -- WEATHER, EQUIPMENT, ANIMAL, VEGETATION, UNKNOWN
    CAUSE_DESC          VARCHAR(200),
    CREW_ID             VARCHAR(20),
    RESTORATION_PRIORITY VARCHAR(10),          -- P1, P2, P3
    OUTAGE_TYPE         VARCHAR(20),           -- SUSTAINED, MOMENTARY, PLANNED
    MAJOR_EVENT_FLAG    BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'GE ADMS outage events. OMS (Outage Management System) data for reliability metrics.';

-- Source: GE Grid Solutions (SCADA)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.GE_SCADA_MEASUREMENT (
    MEASUREMENT_ID      VARCHAR(50) NOT NULL,
    DEVICE_ID           VARCHAR(30),
    MEASUREMENT_TYPE    VARCHAR(30),           -- VOLTAGE, CURRENT, POWER_MW, REACTIVE_MVAR, FREQUENCY
    TIMESTAMP           TIMESTAMP_NTZ NOT NULL,
    VALUE               FLOAT,
    QUALITY             VARCHAR(10),           -- GOOD, BAD, QUESTIONABLE
    SUBSTATION_ID       VARCHAR(20),
    FEEDER_ID           VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'GE SCADA real-time grid measurements. Sub-second telemetry from RTUs and IEDs.';

-- Source: SAP PM (Asset Management)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.SAP_ASSET_MASTER (
    ASSET_ID            VARCHAR(30) NOT NULL,
    ASSET_TYPE          VARCHAR(30),           -- TRANSFORMER, POLE, SWITCH, RECLOSER, CAPACITOR_BANK
    MANUFACTURER        VARCHAR(100),
    MODEL               VARCHAR(50),
    SERIAL_NUMBER       VARCHAR(50),
    INSTALLATION_DATE   DATE,
    EXPECTED_LIFE_YEARS NUMBER(3),
    LOCATION            VARCHAR(200),
    FEEDER_ID           VARCHAR(20),
    SUBSTATION_ID       VARCHAR(20),
    CONDITION_SCORE     NUMBER(3),             -- 1-100 (100=new condition)
    LAST_INSPECTION_DATE DATE,
    REPLACEMENT_COST    NUMBER(12,2),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP PM Asset master - SCD2. Distribution equipment inventory and condition data.';

-- Source: Oracle Utilities CC&B (Billing)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.ORACLE_BILLING_DETAIL (
    BILL_ID             VARCHAR(20) NOT NULL,
    ACCOUNT_ID          VARCHAR(20),
    BILLING_PERIOD_START DATE,
    BILLING_PERIOD_END  DATE,
    KWH_USAGE           NUMBER(12,3),
    DEMAND_KW           NUMBER(10,3),
    BASE_CHARGE         NUMBER(10,2),
    ENERGY_CHARGE       NUMBER(10,2),
    DEMAND_CHARGE       NUMBER(10,2),
    FUEL_ADJUSTMENT     NUMBER(10,2),
    TAXES_FEES          NUMBER(10,2),
    TOTAL_AMOUNT        NUMBER(12,2),
    PAYMENT_STATUS      VARCHAR(20),           -- PAID, PARTIAL, OVERDUE, WRITTEN_OFF
    PAYMENT_DATE        DATE,
    DUE_DATE            DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle CC&B billing details. Monthly utility bills with rate component breakdown.';

-- Source: GE ADMS (Grid Topology)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.GE_GRID_TOPOLOGY (
    NODE_ID             VARCHAR(30) NOT NULL,
    NODE_TYPE           VARCHAR(30),           -- SUBSTATION, FEEDER_HEAD, SWITCH, TRANSFORMER, SERVICE_POINT
    PARENT_NODE_ID      VARCHAR(30),
    FEEDER_ID           VARCHAR(20),
    SUBSTATION_ID       VARCHAR(20),
    CIRCUIT_ID          VARCHAR(20),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    VOLTAGE_LEVEL       VARCHAR(10),           -- TRANSMISSION, SUB_TRANSMISSION, PRIMARY, SECONDARY
    CONNECTIVITY_STATUS VARCHAR(10),           -- ENERGIZED, DE_ENERGIZED, ISOLATED
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'GE ADMS grid topology model. Network connectivity and spatial data.';

-- Source: SAP PM (Work Orders)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.SAP_WORK_ORDER (
    WORK_ORDER_ID       VARCHAR(20) NOT NULL,
    ASSET_ID            VARCHAR(30),
    ORDER_TYPE          VARCHAR(20),           -- CORRECTIVE, PREVENTIVE, CONDITION_BASED, EMERGENCY
    PRIORITY            VARCHAR(5),            -- P1 (emergency) through P4
    PLANNED_DATE        DATE,
    ACTUAL_DATE         DATE,
    COMPLETION_DATE     DATE,
    COST                NUMBER(12,2),
    CREW_SIZE           NUMBER(3),
    STATUS              VARCHAR(20),           -- CREATED, SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
    FAILURE_CODE        VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP PM work orders. Maintenance activities against distribution assets.';

-- Source: Weather Integration
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.WEATHER_STATION_READING (
    STATION_ID          VARCHAR(20) NOT NULL,
    READING_TIMESTAMP   TIMESTAMP_NTZ NOT NULL,
    TEMPERATURE_F       NUMBER(5,1),
    HUMIDITY_PCT        NUMBER(5,1),
    WIND_SPEED_MPH      NUMBER(5,1),
    WIND_GUST_MPH       NUMBER(5,1),
    PRECIPITATION_IN    NUMBER(5,2),
    SOLAR_IRRADIANCE_WM2 NUMBER(7,1),
    WEATHER_CONDITION   VARCHAR(30),           -- CLEAR, CLOUDY, RAIN, STORM, SNOW, ICE
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'External weather station data. Correlated with load and outage analysis.';

-- Source: Oracle Utilities CC&B (Demand Response)
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.SILVER.ORACLE_DEMAND_RESPONSE_EVENT (
    EVENT_ID            VARCHAR(20) NOT NULL,
    PROGRAM_NAME        VARCHAR(50),           -- SMART_THERMOSTAT, DIRECT_LOAD_CONTROL, TIME_OF_USE
    EVENT_DATE          DATE NOT NULL,
    START_HOUR          NUMBER(2),
    END_HOUR            NUMBER(2),
    TARGET_REDUCTION_MW NUMBER(10,3),
    ACTUAL_REDUCTION_MW NUMBER(10,3),
    PARTICIPANTS        NUMBER(10),
    ELIGIBLE_CUSTOMERS  NUMBER(10),
    TRIGGER_REASON      VARCHAR(30),           -- SYSTEM_PEAK, EMERGENCY, ECONOMIC, ENVIRONMENTAL
    STATUS              VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle CC&B demand response events. Load curtailment program performance.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS MERIDIAN_ENERGY.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.DIM_METER (
    METER_KEY           NUMBER AUTOINCREMENT,
    METER_ID            VARCHAR(20) NOT NULL,
    ACCOUNT_ID          VARCHAR(20),
    CUSTOMER_NAME       VARCHAR(200),
    RATE_CLASS          VARCHAR(20),
    SERVICE_TYPE        VARCHAR(20),
    SERVICE_ADDRESS     VARCHAR(300),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    BUDGET_BILLING_FLAG BOOLEAN,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Meter/customer dimension. Conformed from Oracle CC&B + Itron.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.DIM_ASSET (
    ASSET_KEY           NUMBER AUTOINCREMENT,
    ASSET_ID            VARCHAR(30) NOT NULL,
    ASSET_TYPE          VARCHAR(30),
    MANUFACTURER        VARCHAR(100),
    MODEL               VARCHAR(50),
    INSTALLATION_DATE   DATE,
    AGE_YEARS           NUMBER(5,1),
    EXPECTED_LIFE_YEARS NUMBER(3),
    CONDITION_SCORE     NUMBER(3),
    FEEDER_ID           VARCHAR(20),
    SUBSTATION_ID       VARCHAR(20),
    REPLACEMENT_COST    NUMBER(12,2),
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Asset dimension - SCD2. Distribution equipment with condition and age metrics.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.DIM_FEEDER (
    FEEDER_KEY          NUMBER AUTOINCREMENT,
    FEEDER_ID           VARCHAR(20) NOT NULL,
    SUBSTATION_ID       VARCHAR(20),
    SUBSTATION_NAME     VARCHAR(100),
    VOLTAGE_LEVEL       VARCHAR(10),
    TOTAL_CUSTOMERS     NUMBER(10),
    CIRCUIT_MILES       NUMBER(7,2),
    OVERHEAD_PCT        NUMBER(5,2),
    UNDERGROUND_PCT     NUMBER(5,2),
    REGION              VARCHAR(50)
) COMMENT = 'Feeder/circuit dimension. Topology and service territory attributes.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_WEEKEND          BOOLEAN,
    IS_HOLIDAY          BOOLEAN,
    SEASON              VARCHAR(10),           -- SUMMER, WINTER, SPRING, FALL
    HEATING_DEGREE_DAYS NUMBER(5,1),
    COOLING_DEGREE_DAYS NUMBER(5,1)
) COMMENT = 'Date dimension with utility-specific attributes (HDD/CDD, season).';

-- Facts
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.FACT_METER_DAILY (
    DATE_KEY            NUMBER,
    METER_KEY           NUMBER,
    TOTAL_KWH_DELIVERED NUMBER(12,3),
    TOTAL_KWH_RECEIVED  NUMBER(12,3),
    PEAK_DEMAND_KW      NUMBER(10,3),
    AVG_VOLTAGE         NUMBER(7,2),
    AVG_POWER_FACTOR    NUMBER(5,4),
    READ_COUNT          NUMBER(5),
    ESTIMATED_READ_COUNT NUMBER(5),
    ON_PEAK_KWH         NUMBER(12,3),
    OFF_PEAK_KWH        NUMBER(12,3)
) COMMENT = 'Daily meter consumption fact. Aggregated from 15-min interval data.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.FACT_OUTAGE (
    DATE_KEY            NUMBER,
    FEEDER_KEY          NUMBER,
    OUTAGE_ID           VARCHAR(30),
    DURATION_MINUTES    NUMBER(10),
    CUSTOMERS_AFFECTED  NUMBER(10),
    CAUSE_CODE          VARCHAR(20),
    OUTAGE_TYPE         VARCHAR(20),
    SAIDI_CONTRIBUTION  NUMBER(10,4),          -- System Avg Interruption Duration Index
    SAIFI_CONTRIBUTION  NUMBER(10,6),          -- System Avg Interruption Frequency Index
    RESTORATION_PRIORITY VARCHAR(10),
    CREW_RESPONSE_MINUTES NUMBER(10)
) COMMENT = 'Outage fact. IEEE 1366 reliability metric contributions per event.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.FACT_BILLING (
    DATE_KEY            NUMBER,
    METER_KEY           NUMBER,
    KWH_BILLED          NUMBER(12,3),
    DEMAND_KW_BILLED    NUMBER(10,3),
    AMOUNT_BILLED       NUMBER(12,2),
    AMOUNT_COLLECTED    NUMBER(12,2),
    REVENUE_CLASS       VARCHAR(20),
    DAYS_IN_PERIOD      NUMBER(3),
    AVG_RATE_PER_KWH    NUMBER(8,5)
) COMMENT = 'Billing fact. Revenue by customer and rate class.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.FACT_ASSET_CONDITION (
    DATE_KEY            NUMBER,
    ASSET_KEY           NUMBER,
    CONDITION_SCORE     NUMBER(3),
    FAILURE_PROBABILITY NUMBER(5,4),           -- Health Index derived
    MAINTENANCE_COST_YTD NUMBER(12,2),
    WORK_ORDERS_YTD     NUMBER(5),
    DAYS_SINCE_INSPECTION NUMBER(5),
    REMAINING_LIFE_YEARS NUMBER(5,1),
    RISK_PRIORITY_NUMBER NUMBER(5,2)           -- Condition x Consequence
) COMMENT = 'Asset health fact. Condition-based maintenance and risk prioritization.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.FACT_LOAD_PROFILE (
    DATE_KEY            NUMBER,
    FEEDER_KEY          NUMBER,
    HOUR                NUMBER(2),
    LOAD_MW             NUMBER(10,3),
    CAPACITY_MW         NUMBER(10,3),
    UTILIZATION_PCT     NUMBER(5,2),
    TEMPERATURE_F       NUMBER(5,1),
    IS_PEAK_HOUR        BOOLEAN,
    FORECAST_LOAD_MW    NUMBER(10,3),
    FORECAST_ERROR_PCT  NUMBER(5,2)
) COMMENT = 'Hourly load profile by feeder. Capacity planning and peak management.';

-- Aggregates
CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.AGG_RELIABILITY_MONTHLY (
    MONTH_KEY           NUMBER,
    FEEDER_KEY          NUMBER,
    SAIDI_MINUTES       NUMBER(10,4),
    SAIFI_EVENTS        NUMBER(10,6),
    CAIDI_MINUTES       NUMBER(10,4),
    MAIFI_EVENTS        NUMBER(10,6),          -- Momentary Average Interruption Frequency
    CUSTOMERS_SERVED    NUMBER(10),
    OUTAGE_COUNT        NUMBER(5),
    MAJOR_EVENT_COUNT   NUMBER(3),
    WORST_CAUSE         VARCHAR(20)
) COMMENT = 'Monthly reliability KPIs per feeder. IEEE 1366 standard metrics for PUC reporting.';

CREATE OR REPLACE TABLE MERIDIAN_ENERGY.GOLD.AGG_REVENUE_BY_CLASS (
    MONTH_KEY           NUMBER,
    RATE_CLASS          VARCHAR(20),
    KWH_SOLD            NUMBER(15,3),
    REVENUE             NUMBER(15,2),
    CUSTOMER_COUNT      NUMBER(10),
    AVG_RATE_PER_KWH    NUMBER(8,5),
    DEMAND_MW_PEAK      NUMBER(10,3),
    LOAD_FACTOR         NUMBER(5,4),
    REVENUE_PER_CUSTOMER NUMBER(10,2)
) COMMENT = 'Monthly revenue and load by rate class. Regulatory rate case support.';

