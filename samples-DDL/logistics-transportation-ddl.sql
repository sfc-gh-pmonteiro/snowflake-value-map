-- ============================================================================
-- LOGISTICS & TRANSPORTATION VERTICAL - Sample DDL
-- Source Systems: Oracle TMS (transportation management), Samsara (fleet telematics),
--                 FourKites (visibility), Manhattan WMS (warehouse management)
-- Entity: Atlas Logistics Inc (3PL/freight)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ATLAS_LOGISTICS;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS ATLAS_LOGISTICS.SILVER;

-- Source: Oracle TMS (Shipments)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.ORACLE_SHIPMENT (
    SHIPMENT_ID         VARCHAR(30) NOT NULL,
    ORDER_ID            VARCHAR(30),
    ORIGIN_FACILITY     VARCHAR(30),
    DESTINATION         VARCHAR(300),
    CARRIER_ID          VARCHAR(20),
    SERVICE_LEVEL       VARCHAR(20),       -- LTL, FTL, EXPEDITED, PARCEL, INTERMODAL, DRAYAGE
    SHIP_DATE           DATE,
    DELIVERY_DATE_PLANNED DATE,
    DELIVERY_DATE_ACTUAL DATE,
    WEIGHT_LBS          NUMBER(12,2),
    PIECES              NUMBER(10),
    STATUS              VARCHAR(20),       -- PLANNED, TENDERED, IN_TRANSIT, DELIVERED, EXCEPTION, CANCELLED
    BOL_NUMBER          VARCHAR(30),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle TMS shipment records. Source: OTM shipment/order tables.';

-- Source: Oracle TMS (Carriers)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.ORACLE_CARRIER (
    CARRIER_ID          VARCHAR(20) NOT NULL,
    CARRIER_NAME        VARCHAR(200),
    CARRIER_TYPE        VARCHAR(20),       -- ASSET, BROKERAGE, INTERMODAL, PARCEL, DRAYAGE
    SCAC_CODE           VARCHAR(10),
    MC_NUMBER           VARCHAR(10),
    DOT_NUMBER          VARCHAR(10),
    INSURANCE_EXPIRY    DATE,
    SAFETY_RATING       VARCHAR(10),       -- SATISFACTORY, CONDITIONAL, UNSATISFACTORY
    STATUS              VARCHAR(20),       -- ACTIVE, SUSPENDED, INACTIVE
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle TMS carrier master - SCD2. Compliance and safety tracking.';

-- Source: Samsara (Fleet Telematics - Vehicles)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.SAMSARA_VEHICLE (
    VEHICLE_ID          VARCHAR(30) NOT NULL,
    VIN                 VARCHAR(20),
    VEHICLE_TYPE        VARCHAR(20),       -- TRACTOR, STRAIGHT_TRUCK, VAN, REEFER, FLATBED, TANKER
    CARRIER_ID          VARCHAR(20),
    YEAR                NUMBER(4),
    MAKE                VARCHAR(50),
    MODEL               VARCHAR(50),
    FUEL_TYPE           VARCHAR(10),       -- DIESEL, CNG, ELECTRIC, HYBRID
    MAX_PAYLOAD_LBS     NUMBER(10),
    CURRENT_ODOMETER    NUMBER(10),
    STATUS              VARCHAR(20),       -- ACTIVE, MAINTENANCE, DECOMMISSIONED
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Samsara fleet vehicle master. Telematics-connected assets.';

-- Source: Samsara (GPS/Telematics Events)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.SAMSARA_GPS_EVENT (
    EVENT_ID            VARCHAR(50) NOT NULL,
    VEHICLE_ID          VARCHAR(30),
    EVENT_TIMESTAMP     TIMESTAMP_NTZ NOT NULL,
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    SPEED_MPH           NUMBER(5,1),
    HEADING             NUMBER(3),
    EVENT_TYPE          VARCHAR(20),       -- LOCATION, HARD_BRAKE, HARD_ACCEL, SPEEDING, IDLE, GEOFENCE
    FUEL_LEVEL_PCT      NUMBER(5,2),
    ENGINE_HOURS        NUMBER(10,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Samsara GPS and telematics events. High-frequency vehicle tracking.';

-- Source: FourKites (Shipment Visibility)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.FOURKITES_TRACKING (
    TRACKING_ID         VARCHAR(50) NOT NULL,
    SHIPMENT_ID         VARCHAR(30),
    EVENT_TIMESTAMP     TIMESTAMP_NTZ NOT NULL,
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    STATUS              VARCHAR(30),       -- PICKED_UP, IN_TRANSIT, AT_STOP, OUT_FOR_DELIVERY, DELIVERED
    ETA_DESTINATION     TIMESTAMP_NTZ,
    DELAY_MINUTES       NUMBER(10),
    EXCEPTION_TYPE      VARCHAR(30),       -- WEATHER, TRAFFIC, DETENTION, MECHANICAL, DRIVER
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'FourKites real-time visibility tracking. ETA and exception monitoring.';

-- Source: Manhattan WMS (Inventory)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.MANHATTAN_INVENTORY (
    LOCATION_ID         VARCHAR(30) NOT NULL,
    FACILITY_ID         VARCHAR(20),
    SKU                 VARCHAR(30),
    LOT_NUMBER          VARCHAR(20),
    QUANTITY_ON_HAND    NUMBER(12),
    QUANTITY_ALLOCATED  NUMBER(12),
    RECEIPT_DATE        DATE,
    EXPIRY_DATE         DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Manhattan WMS inventory by location/SKU. Source: Manhattan SCALE.';

-- Source: Manhattan WMS (Orders)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.MANHATTAN_ORDER (
    ORDER_ID            VARCHAR(30) NOT NULL,
    CUSTOMER_ID         VARCHAR(30),
    FACILITY_ID         VARCHAR(20),
    ORDER_DATE          DATE,
    SHIP_BY_DATE        DATE,
    PRIORITY            VARCHAR(10),       -- STANDARD, RUSH, SAME_DAY, NEXT_DAY
    LINES               NUMBER(5),
    UNITS               NUMBER(10),
    STATUS              VARCHAR(20),       -- RECEIVED, ALLOCATED, PICKING, PACKED, SHIPPED, CANCELLED
    WAVE_ID             VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Manhattan WMS outbound orders. Source: Manhattan order management.';

-- Source: Oracle TMS (Freight Invoices)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.ORACLE_FREIGHT_INVOICE (
    INVOICE_ID          VARCHAR(30) NOT NULL,
    SHIPMENT_ID         VARCHAR(30),
    CARRIER_ID          VARCHAR(20),
    INVOICE_DATE        DATE,
    LINEHAUL_COST       NUMBER(12,2),
    FUEL_SURCHARGE      NUMBER(12,2),
    ACCESSORIALS        NUMBER(12,2),
    TOTAL_AMOUNT        NUMBER(12,2),
    DISPUTE_FLAG        BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle TMS freight invoices. Carrier billing with cost breakdown.';

-- Source: Samsara (Driver Hours of Service)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.SAMSARA_DRIVER_HOS (
    RECORD_ID           VARCHAR(50) NOT NULL,
    DRIVER_ID           VARCHAR(30),
    VEHICLE_ID          VARCHAR(30),
    HOS_DATE            DATE,
    DRIVE_HOURS         NUMBER(5,2),
    ON_DUTY_HOURS       NUMBER(5,2),
    OFF_DUTY_HOURS      NUMBER(5,2),
    VIOLATIONS          NUMBER(3),
    REMAINING_DRIVE_TIME NUMBER(5,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Samsara ELD/HOS driver compliance data. FMCSA regulation tracking.';

-- Source: Oracle TMS (Lane Rates)
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.SILVER.ORACLE_LANE_RATE (
    LANE_ID             VARCHAR(30) NOT NULL,
    ORIGIN_REGION       VARCHAR(50),
    DESTINATION_REGION  VARCHAR(50),
    CARRIER_ID          VARCHAR(20),
    MODE                VARCHAR(20),       -- FTL, LTL, INTERMODAL, PARCEL
    RATE_PER_MILE       NUMBER(8,4),
    MINIMUM_CHARGE      NUMBER(12,2),
    EFFECTIVE_DATE      DATE,
    EXPIRY_DATE         DATE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Oracle TMS contracted lane rates. Source: OTM rate offering tables.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS ATLAS_LOGISTICS.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.DIM_CARRIER (
    CARRIER_KEY         NUMBER AUTOINCREMENT,
    CARRIER_ID          VARCHAR(20) NOT NULL,
    CARRIER_NAME        VARCHAR(200),
    CARRIER_TYPE        VARCHAR(20),
    SCAC_CODE           VARCHAR(10),
    SAFETY_RATING       VARCHAR(10),
    STATUS              VARCHAR(20),
    INSURANCE_CURRENT   BOOLEAN,
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Carrier dimension - SCD2. Compliance attributes tracked.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.DIM_FACILITY (
    FACILITY_KEY        NUMBER AUTOINCREMENT,
    FACILITY_ID         VARCHAR(20) NOT NULL,
    FACILITY_NAME       VARCHAR(200),
    FACILITY_TYPE       VARCHAR(20),       -- DISTRIBUTION_CENTER, CROSS_DOCK, COLD_STORAGE, YARD
    ADDRESS             VARCHAR(300),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    REGION              VARCHAR(50),
    CAPACITY_SQFT       NUMBER(12),
    DOCK_DOORS          NUMBER(5)
) COMMENT = 'Facility/warehouse dimension. Capacity and location data.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.DIM_LANE (
    LANE_KEY            NUMBER AUTOINCREMENT,
    LANE_ID             VARCHAR(30) NOT NULL,
    ORIGIN_REGION       VARCHAR(50),
    DESTINATION_REGION  VARCHAR(50),
    DISTANCE_MILES      NUMBER(8,1),
    MODE                VARCHAR(20),
    TRANSIT_DAYS_STD    NUMBER(3)
) COMMENT = 'Lane/route dimension. Origin-destination pairs with standard transit.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_BUSINESS_DAY     BOOLEAN,
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2)
) COMMENT = 'Standard date dimension.';

-- Facts
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.FACT_SHIPMENT (
    SHIPMENT_KEY        NUMBER AUTOINCREMENT,
    DATE_KEY            NUMBER,
    LANE_KEY            NUMBER,
    CARRIER_KEY         NUMBER,
    FACILITY_KEY        NUMBER,
    ON_TIME_FLAG        BOOLEAN,
    TRANSIT_DAYS        NUMBER(5,1),
    COST_TOTAL          NUMBER(12,2),
    COST_PER_MILE       NUMBER(8,4),
    WEIGHT_LBS          NUMBER(12,2),
    PIECES              NUMBER(10),
    SERVICE_LEVEL       VARCHAR(20),
    EXCEPTION_FLAG      BOOLEAN
) COMMENT = 'Shipment fact. Delivery performance and cost at shipment grain.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.FACT_FLEET_DAILY (
    DATE_KEY            NUMBER,
    VEHICLE_KEY         NUMBER AUTOINCREMENT,
    VEHICLE_ID          VARCHAR(30),
    MILES_DRIVEN        NUMBER(8,1),
    FUEL_GALLONS        NUMBER(8,2),
    IDLE_HOURS          NUMBER(5,2),
    DRIVE_HOURS         NUMBER(5,2),
    SPEED_AVG           NUMBER(5,1),
    HARD_BRAKES         NUMBER(5),
    MPG                 NUMBER(5,2),
    UTILIZATION_PCT     NUMBER(5,4)
) COMMENT = 'Daily fleet utilization fact. Fuel efficiency and safety events.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.FACT_WAREHOUSE_THROUGHPUT (
    DATE_KEY            NUMBER,
    FACILITY_KEY        NUMBER,
    ORDERS_RECEIVED     NUMBER(10),
    ORDERS_SHIPPED      NUMBER(10),
    UNITS_PICKED        NUMBER(10),
    PICK_ACCURACY_PCT   NUMBER(5,4),
    DOCK_TO_STOCK_HOURS NUMBER(8,2),
    LINES_PER_LABOR_HR  NUMBER(8,2)
) COMMENT = 'Daily warehouse throughput fact. Productivity and accuracy KPIs.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.FACT_DELIVERY_PERFORMANCE (
    DATE_KEY            NUMBER,
    CARRIER_KEY         NUMBER,
    LANE_KEY            NUMBER,
    SHIPMENTS           NUMBER(10),
    ON_TIME_PCT         NUMBER(5,4),
    AVG_TRANSIT_DAYS    NUMBER(5,2),
    AVG_DELAY_HOURS     NUMBER(8,2),
    EXCEPTIONS          NUMBER(5),
    DAMAGE_CLAIMS       NUMBER(5)
) COMMENT = 'Carrier delivery performance by lane. OTD and transit time tracking.';

-- Aggregates
CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.AGG_CARRIER_SCORECARD (
    MONTH_KEY           NUMBER,
    CARRIER_KEY         NUMBER,
    SHIPMENTS           NUMBER(10),
    OTD_PCT             NUMBER(5,4),
    DAMAGE_PCT          NUMBER(5,4),
    INVOICE_ACCURACY_PCT NUMBER(5,4),
    TENDER_ACCEPT_PCT   NUMBER(5,4),
    COMPOSITE_SCORE     NUMBER(5,2)
) COMMENT = 'Monthly carrier scorecard. OTD + damage + billing accuracy composite.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.AGG_LANE_ECONOMICS (
    MONTH_KEY           NUMBER,
    LANE_KEY            NUMBER,
    SHIPMENTS           NUMBER(10),
    AVG_COST_PER_MILE   NUMBER(8,4),
    VOLUME_LBS          NUMBER(15,2),
    UTILIZATION_PCT     NUMBER(5,4),
    RATE_VS_BENCHMARK   NUMBER(7,4),
    CARRIER_DIVERSITY   NUMBER(3)
) COMMENT = 'Monthly lane economics. Cost benchmarking and volume analysis.';

CREATE OR REPLACE TABLE ATLAS_LOGISTICS.GOLD.AGG_FACILITY_KPI (
    MONTH_KEY           NUMBER,
    FACILITY_KEY        NUMBER,
    THROUGHPUT_UNITS    NUMBER(12),
    FILL_RATE_PCT       NUMBER(5,4),
    ORDER_CYCLE_HOURS   NUMBER(8,2),
    LABOR_PRODUCTIVITY  NUMBER(8,2),
    INVENTORY_TURNS     NUMBER(5,2),
    SPACE_UTILIZATION_PCT NUMBER(5,4)
) COMMENT = 'Monthly facility KPIs. Throughput, fill rate, and labor productivity.';
