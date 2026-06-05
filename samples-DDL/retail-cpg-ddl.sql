-- ============================================================================
-- RETAIL & CPG VERTICAL - Sample DDL
-- Source Systems: SAP S/4HANA (MM/SD), Shopify (Ecommerce), Salesforce Commerce Cloud,
--                 Genesys Cloud (Contact Center), Custom POS, Loyalty Platform
-- Entity: Summit Retail Group
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SUMMIT_RETAIL;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS SUMMIT_RETAIL.SILVER;

-- Source: SAP S/4HANA SD (Sales & Distribution)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SAP_SALES_ORDER (
    ORDER_NUMBER        VARCHAR(20) NOT NULL,
    ORDER_ITEM          NUMBER(5) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    MATERIAL_NUMBER     VARCHAR(40),
    PLANT_CODE          VARCHAR(10),
    STORE_ID            VARCHAR(10),
    ORDER_DATE          DATE,
    REQUESTED_DELIVERY  DATE,
    ACTUAL_DELIVERY     DATE,
    QUANTITY            NUMBER(15,3),
    NET_AMOUNT          NUMBER(15,2),
    CURRENCY            VARCHAR(5),
    DISCOUNT_AMOUNT     NUMBER(15,2),
    SALES_ORG           VARCHAR(10),
    CHANNEL             VARCHAR(10),       -- 10 (Retail), 20 (Wholesale), 30 (Ecommerce)
    ORDER_REASON        VARCHAR(10),
    STATUS              VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP S/4HANA Sales Orders. Source: VBAK/VBAP tables.';

-- Source: SAP S/4HANA MM (Inventory/Stock)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SAP_INVENTORY (
    SNAPSHOT_DATE       DATE NOT NULL,
    PLANT_CODE          VARCHAR(10) NOT NULL,
    STORAGE_LOCATION    VARCHAR(10) NOT NULL,
    MATERIAL_NUMBER     VARCHAR(40) NOT NULL,
    QUANTITY_ON_HAND    NUMBER(15,3),
    QUANTITY_IN_TRANSIT NUMBER(15,3),
    QUANTITY_RESERVED   NUMBER(15,3),
    QUANTITY_AVAILABLE  NUMBER(15,3),
    UOM                 VARCHAR(5),
    VALUATION_PRICE     NUMBER(15,4),
    STOCK_VALUE         NUMBER(15,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP S/4HANA daily inventory snapshots. Source: MARD/MARC tables.';

-- Source: SAP S/4HANA MM (Product Master)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SAP_PRODUCT_MASTER (
    MATERIAL_NUMBER     VARCHAR(40) NOT NULL,
    MATERIAL_DESC       VARCHAR(200),
    CATEGORY_ID         VARCHAR(20),
    CATEGORY_NAME       VARCHAR(100),
    SUBCATEGORY_ID      VARCHAR(20),
    SUBCATEGORY_NAME    VARCHAR(100),
    BRAND               VARCHAR(100),
    SUPPLIER_ID         VARCHAR(20),
    BASE_UOM            VARCHAR(5),
    WEIGHT_NET_KG       NUMBER(10,3),
    SHELF_LIFE_DAYS     NUMBER(5),
    PRICE_REGULAR       NUMBER(10,2),
    PRICE_COST          NUMBER(10,2),
    IS_PRIVATE_LABEL    BOOLEAN,
    SEASON_CODE         VARCHAR(10),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP S/4HANA Material/Product master - SCD2. Source: MARA/MAKT tables.';

-- Source: Shopify (Ecommerce Orders)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SHOPIFY_ORDER (
    ORDER_ID            VARCHAR(30) NOT NULL,
    ORDER_NUMBER        VARCHAR(20),
    CUSTOMER_ID         VARCHAR(30),
    EMAIL               VARCHAR(200),
    ORDER_DATETIME      TIMESTAMP_NTZ,
    FINANCIAL_STATUS    VARCHAR(20),       -- PAID, PENDING, REFUNDED, PARTIALLY_REFUNDED
    FULFILLMENT_STATUS  VARCHAR(20),       -- FULFILLED, PARTIAL, UNFULFILLED
    SUBTOTAL            NUMBER(12,2),
    TOTAL_DISCOUNT      NUMBER(12,2),
    TOTAL_TAX           NUMBER(12,2),
    TOTAL_PRICE         NUMBER(12,2),
    CURRENCY            VARCHAR(5),
    DISCOUNT_CODES      VARIANT,           -- JSON array of applied discount codes
    LINE_ITEMS          VARIANT,           -- JSON array of items [{sku, title, qty, price}]
    SHIPPING_ADDRESS    VARIANT,           -- JSON shipping address
    BROWSER_IP          VARCHAR(50),
    LANDING_PAGE_URL    VARCHAR(500),
    REFERRING_SITE      VARCHAR(500),
    UTM_SOURCE          VARCHAR(100),
    UTM_MEDIUM          VARCHAR(100),
    UTM_CAMPAIGN        VARCHAR(200),
    TAGS                VARCHAR(500),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Shopify ecommerce orders. Rich VARIANT fields for line items and addresses.';

-- Source: Shopify (Customer Events / Clickstream)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SHOPIFY_CUSTOMER_EVENT (
    EVENT_ID            VARCHAR(50) NOT NULL,
    CUSTOMER_ID         VARCHAR(30),
    SESSION_ID          VARCHAR(50),
    EVENT_TYPE          VARCHAR(30),       -- PAGE_VIEW, PRODUCT_VIEW, ADD_TO_CART, CHECKOUT_START, PURCHASE
    EVENT_TIMESTAMP     TIMESTAMP_NTZ NOT NULL,
    PAGE_URL            VARCHAR(500),
    PRODUCT_ID          VARCHAR(30),
    PRODUCT_CATEGORY    VARCHAR(100),
    DEVICE_TYPE         VARCHAR(20),
    BROWSER             VARCHAR(50),
    GEO_COUNTRY         VARCHAR(5),
    GEO_REGION          VARCHAR(50),
    EVENT_PROPERTIES    VARIANT,           -- Additional event-specific data
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Shopify customer clickstream/behavior events. High-volume event stream.';

-- Source: Custom POS System
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.POS_TRANSACTION (
    TRANSACTION_ID      VARCHAR(30) NOT NULL,
    TRANSACTION_LINE    NUMBER(5) NOT NULL,
    STORE_ID            VARCHAR(10) NOT NULL,
    REGISTER_ID         VARCHAR(10),
    CASHIER_ID          VARCHAR(20),
    CUSTOMER_ID         VARCHAR(20),       -- NULL for non-loyalty transactions
    LOYALTY_CARD_NUMBER VARCHAR(20),
    TRANSACTION_DATETIME TIMESTAMP_NTZ NOT NULL,
    SKU                 VARCHAR(40),
    QUANTITY            NUMBER(10,3),
    UNIT_PRICE          NUMBER(10,2),
    DISCOUNT_AMOUNT     NUMBER(10,2),
    PROMOTION_ID        VARCHAR(20),
    NET_AMOUNT          NUMBER(10,2),
    TAX_AMOUNT          NUMBER(10,2),
    PAYMENT_METHOD      VARCHAR(20),
    BASKET_ID           VARCHAR(30),
    RETURN_FLAG         BOOLEAN,
    RETURN_REASON_CODE  VARCHAR(10),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'In-store POS transactions at line level. Links to loyalty via card number.';

-- Source: Loyalty Platform
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.LOYALTY_MEMBER (
    MEMBER_ID           VARCHAR(20) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    LOYALTY_TIER        VARCHAR(20),       -- BRONZE, SILVER, GOLD, PLATINUM
    ENROLLMENT_DATE     DATE,
    POINTS_BALANCE      NUMBER(12),
    POINTS_LIFETIME     NUMBER(12),
    POINTS_REDEEMED     NUMBER(12),
    PREFERRED_STORE_ID  VARCHAR(10),
    PREFERRED_CATEGORIES VARIANT,          -- JSON array of top categories
    COMMUNICATION_PREFS VARIANT,           -- JSON {email: true, sms: false, push: true}
    LAST_ACTIVITY_DATE  DATE,
    CHURN_RISK_SCORE    NUMBER(5,4),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Loyalty program member profiles - SCD2. Tier changes tracked.';

-- Source: Salesforce Commerce Cloud (Promotions)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SFCC_PROMOTION (
    PROMOTION_ID        VARCHAR(30) NOT NULL,
    PROMOTION_NAME      VARCHAR(200),
    PROMOTION_TYPE      VARCHAR(30),       -- PERCENTAGE_OFF, BOGO, FIXED_AMOUNT, FREE_SHIPPING
    CHANNEL             VARCHAR(20),       -- ONLINE, STORE, OMNI
    START_DATE          DATE,
    END_DATE            DATE,
    DISCOUNT_VALUE      NUMBER(10,2),
    MINIMUM_PURCHASE    NUMBER(10,2),
    TARGET_SEGMENT      VARCHAR(50),
    BUDGET_AMOUNT       NUMBER(12,2),
    ACTUAL_SPEND        NUMBER(12,2),
    REDEMPTION_COUNT    NUMBER(10),
    STATUS              VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce Commerce Cloud promotions. Campaign definitions and spend tracking.';

-- Source: SAP S/4HANA SD (Store Master)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SAP_STORE_MASTER (
    STORE_ID            VARCHAR(10) NOT NULL,
    STORE_NAME          VARCHAR(100),
    STORE_FORMAT        VARCHAR(20),       -- HYPERMARKET, SUPERMARKET, EXPRESS, ONLINE_FC
    ADDRESS             VARCHAR(200),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    REGION              VARCHAR(50),
    DISTRICT            VARCHAR(50),
    DISTRICT_MANAGER    VARCHAR(50),
    SQUARE_FOOTAGE      NUMBER(10),
    OPEN_DATE           DATE,
    STATUS              VARCHAR(20),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP store/plant master. Includes geo coordinates for location analytics.';

-- Source: Genesys Cloud (Contact Center)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.GENESYS_INTERACTION (
    INTERACTION_ID      VARCHAR(50) NOT NULL,
    CUSTOMER_ID         VARCHAR(20),
    AGENT_ID            VARCHAR(30),
    QUEUE_NAME          VARCHAR(100),
    MEDIA_TYPE          VARCHAR(20),       -- VOICE, CHAT, EMAIL, SMS, SOCIAL
    DIRECTION           VARCHAR(10),       -- INBOUND, OUTBOUND
    START_DATETIME      TIMESTAMP_NTZ,
    END_DATETIME        TIMESTAMP_NTZ,
    HANDLE_TIME_SEC     NUMBER(10),
    HOLD_TIME_SEC       NUMBER(10),
    WAIT_TIME_SEC       NUMBER(10),
    WRAP_UP_CODE        VARCHAR(50),       -- ORDER_STATUS, RETURN, COMPLAINT, PRODUCT_INFO
    DISPOSITION         VARCHAR(30),       -- RESOLVED, ESCALATED, CALLBACK, TRANSFERRED
    SENTIMENT_SCORE     NUMBER(5,4),
    CSAT_SCORE          NUMBER(2),
    FIRST_CONTACT_RESOLUTION BOOLEAN,
    TRANSCRIPT_SUMMARY  VARCHAR(2000),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Genesys Cloud contact center interactions. All channels.';

-- Source: SAP S/4HANA (Supplier/Vendor)
CREATE OR REPLACE TABLE SUMMIT_RETAIL.SILVER.SAP_SUPPLIER (
    SUPPLIER_ID         VARCHAR(20) NOT NULL,
    SUPPLIER_NAME       VARCHAR(200),
    COUNTRY             VARCHAR(50),
    REGION              VARCHAR(50),
    CATEGORY_SPECIALTY  VARCHAR(100),
    PAYMENT_TERMS       VARCHAR(20),
    LEAD_TIME_AVG_DAYS  NUMBER(5),
    MINIMUM_ORDER_QTY   NUMBER(10),
    IS_ACTIVE           BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'SAP vendor master. Source: LFA1/LFB1 tables.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS SUMMIT_RETAIL.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.DIM_CUSTOMER (
    CUSTOMER_KEY        NUMBER AUTOINCREMENT,
    CUSTOMER_ID         VARCHAR(20) NOT NULL,
    FIRST_NAME          VARCHAR(100),
    LAST_NAME           VARCHAR(100),
    EMAIL_HASH          VARCHAR(64),
    LOYALTY_TIER        VARCHAR(20),
    LOYALTY_MEMBER_SINCE DATE,
    PREFERRED_CHANNEL   VARCHAR(20),
    PREFERRED_STORE_ID  VARCHAR(10),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    CUSTOMER_SEGMENT    VARCHAR(30),       -- VIP, REGULAR, OCCASIONAL, AT_RISK, LAPSED
    LIFETIME_VALUE      NUMBER(12,2),
    FIRST_PURCHASE_DATE DATE,
    LAST_PURCHASE_DATE  DATE,
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Customer dimension - SCD2. Unified across POS, ecommerce, loyalty.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.DIM_PRODUCT (
    PRODUCT_KEY         NUMBER AUTOINCREMENT,
    SKU                 VARCHAR(40) NOT NULL,
    PRODUCT_NAME        VARCHAR(200),
    BRAND               VARCHAR(100),
    CATEGORY_L1         VARCHAR(100),
    CATEGORY_L2         VARCHAR(100),
    CATEGORY_L3         VARCHAR(100),
    SUPPLIER_ID         VARCHAR(20),
    IS_PRIVATE_LABEL    BOOLEAN,
    SHELF_LIFE_DAYS     NUMBER(5),
    PRICE_REGULAR       NUMBER(10,2),
    PRICE_COST          NUMBER(10,2),
    MARGIN_PCT          NUMBER(5,4),
    SEASON_CODE         VARCHAR(10),
    _IS_CURRENT         BOOLEAN
) COMMENT = 'Product dimension. Conformed from SAP material master.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.DIM_STORE (
    STORE_KEY           NUMBER AUTOINCREMENT,
    STORE_ID            VARCHAR(10) NOT NULL,
    STORE_NAME          VARCHAR(100),
    STORE_FORMAT        VARCHAR(20),
    CITY                VARCHAR(100),
    STATE               VARCHAR(5),
    ZIP_CODE            VARCHAR(10),
    REGION              VARCHAR(50),
    DISTRICT            VARCHAR(50),
    LATITUDE            FLOAT,
    LONGITUDE           FLOAT,
    SQUARE_FOOTAGE      NUMBER(10),
    OPEN_DATE           DATE
) COMMENT = 'Store/Location dimension. Includes geo for spatial analytics.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    DAY_NAME            VARCHAR(10),
    IS_WEEKEND          BOOLEAN,
    IS_HOLIDAY          BOOLEAN,
    HOLIDAY_NAME        VARCHAR(50),
    FISCAL_YEAR         NUMBER(4),
    FISCAL_PERIOD       NUMBER(2),
    SEASON              VARCHAR(10)
) COMMENT = 'Date dimension with holiday and season flags.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.DIM_PROMOTION (
    PROMOTION_KEY       NUMBER AUTOINCREMENT,
    PROMOTION_ID        VARCHAR(30) NOT NULL,
    PROMOTION_NAME      VARCHAR(200),
    PROMOTION_TYPE      VARCHAR(30),
    CHANNEL             VARCHAR(20),
    START_DATE          DATE,
    END_DATE            DATE,
    DISCOUNT_VALUE      NUMBER(10,2),
    TARGET_SEGMENT      VARCHAR(50)
) COMMENT = 'Promotion dimension.';

-- Facts
CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.FACT_SALES (
    SALES_KEY           NUMBER AUTOINCREMENT,
    TRANSACTION_ID      VARCHAR(30),
    CUSTOMER_KEY        NUMBER,
    PRODUCT_KEY         NUMBER,
    STORE_KEY           NUMBER,
    DATE_KEY            NUMBER,
    PROMOTION_KEY       NUMBER,
    CHANNEL             VARCHAR(20),       -- STORE, ONLINE, CLICK_COLLECT
    QUANTITY            NUMBER(10,3),
    UNIT_PRICE          NUMBER(10,2),
    DISCOUNT_AMOUNT     NUMBER(10,2),
    NET_REVENUE         NUMBER(12,2),
    COST_OF_GOODS       NUMBER(12,2),
    GROSS_MARGIN        NUMBER(12,2),
    MARGIN_PCT          NUMBER(5,4),
    BASKET_ID           VARCHAR(30),
    IS_RETURN           BOOLEAN,
    RETURN_REASON       VARCHAR(50)
) COMMENT = 'Unified sales fact. Omnichannel: POS + Shopify + wholesale.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.FACT_INVENTORY_DAILY (
    STORE_KEY           NUMBER,
    PRODUCT_KEY         NUMBER,
    DATE_KEY            NUMBER,
    QTY_ON_HAND         NUMBER(15,3),
    QTY_IN_TRANSIT      NUMBER(15,3),
    QTY_AVAILABLE       NUMBER(15,3),
    DAYS_OF_SUPPLY      NUMBER(5,1),
    STOCKOUT_FLAG       BOOLEAN,
    OVERSTOCK_FLAG      BOOLEAN,
    STOCK_VALUE         NUMBER(12,2)
) COMMENT = 'Daily inventory position by store/product. Stockout and overstock detection.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.FACT_CUSTOMER_INTERACTION (
    INTERACTION_KEY     NUMBER AUTOINCREMENT,
    CUSTOMER_KEY        NUMBER,
    DATE_KEY            NUMBER,
    INTERACTION_TYPE    VARCHAR(30),
    CHANNEL             VARCHAR(20),
    HANDLE_TIME_SEC     NUMBER(10),
    WAIT_TIME_SEC       NUMBER(10),
    SENTIMENT_SCORE     NUMBER(5,4),
    CSAT_SCORE          NUMBER(2),
    FCR_FLAG            BOOLEAN,
    WRAP_UP_CATEGORY    VARCHAR(50)
) COMMENT = 'Contact center interaction fact. From Genesys Cloud.';

-- Aggregates
CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.AGG_BASKET_ANALYSIS (
    DATE_KEY            NUMBER,
    STORE_KEY           NUMBER,
    PRODUCT_A_KEY       NUMBER,
    PRODUCT_B_KEY       NUMBER,
    CO_OCCURRENCE_COUNT NUMBER(10),
    SUPPORT             NUMBER(7,6),
    CONFIDENCE          NUMBER(5,4),
    LIFT                NUMBER(7,4)
) COMMENT = 'Market basket affinity analysis. Product co-occurrence metrics.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.AGG_SALES_DAILY (
    DATE_KEY            NUMBER,
    STORE_KEY           NUMBER,
    CATEGORY_L1         VARCHAR(100),
    CHANNEL             VARCHAR(20),
    TOTAL_TRANSACTIONS  NUMBER(10),
    TOTAL_UNITS         NUMBER(12),
    TOTAL_REVENUE       NUMBER(15,2),
    TOTAL_MARGIN        NUMBER(15,2),
    AVG_BASKET_SIZE     NUMBER(10,2),
    AVG_ITEMS_PER_BASKET NUMBER(5,1),
    UNIQUE_CUSTOMERS    NUMBER(10),
    NEW_CUSTOMERS       NUMBER(10),
    RETURNING_CUSTOMERS NUMBER(10)
) COMMENT = 'Daily sales aggregate by store/category/channel. Core retail KPI table.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.AGG_CUSTOMER_RFM (
    CUSTOMER_KEY        NUMBER,
    COMPUTED_DATE       DATE,
    RECENCY_DAYS        NUMBER(5),
    FREQUENCY_90D       NUMBER(5),
    MONETARY_90D        NUMBER(12,2),
    RECENCY_SCORE       NUMBER(1),
    FREQUENCY_SCORE     NUMBER(1),
    MONETARY_SCORE      NUMBER(1),
    RFM_SEGMENT         VARCHAR(30),       -- CHAMPIONS, LOYAL, POTENTIAL, AT_RISK, HIBERNATING, LOST
    CLV_PREDICTED       NUMBER(12,2)
) COMMENT = 'Customer RFM segmentation. Refreshed weekly for targeting.';

CREATE OR REPLACE TABLE SUMMIT_RETAIL.GOLD.AGG_DEMAND_FORECAST (
    PRODUCT_KEY         NUMBER,
    STORE_KEY           NUMBER,
    FORECAST_DATE       DATE,
    FORECAST_QUANTITY   NUMBER(12,2),
    LOWER_BOUND         NUMBER(12,2),
    UPPER_BOUND         NUMBER(12,2),
    FORECAST_MODEL      VARCHAR(30),
    GENERATED_AT        TIMESTAMP_NTZ
) COMMENT = 'Demand forecast by product/store/day. Generated via Cortex ML Forecasting.';

