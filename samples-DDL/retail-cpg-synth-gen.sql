-- ============================================================================
-- RETAIL & CPG VERTICAL - Synthetic Data Generation
-- Entity: Summit Retail Group
-- Prerequisites: Run retail-cpg-ddl.sql first to create all tables
-- Date Range: Dynamic - last 5 years from yesterday (re-runnable)
-- Estimated Runtime: ~5-8 minutes on XS warehouse
-- US calendar: Black Friday (+60%), Christmas, back-to-school, Valentine's, summer
-- ============================================================================

-- ============================================================================
-- CLEAN EXISTING DATA
-- ============================================================================
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.AGG_DEMAND_FORECAST;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.AGG_CUSTOMER_RFM;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.AGG_SALES_DAILY;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.AGG_BASKET_ANALYSIS;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.FACT_CUSTOMER_INTERACTION;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.FACT_INVENTORY_DAILY;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.FACT_SALES;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.DIM_PROMOTION;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.DIM_DATE;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.DIM_STORE;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.DIM_PRODUCT;
TRUNCATE TABLE SUMMIT_RETAIL.GOLD.DIM_CUSTOMER;

-- ============================================================================
-- 1. DIM_DATE (Dynamic 5-year span with retail-specific attributes)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.DIM_DATE
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))                  AS DATE_KEY,
    d                                                   AS FULL_DATE,
    YEAR(d)                                            AS YEAR,
    QUARTER(d)                                         AS QUARTER,
    MONTH(d)                                           AS MONTH,
    WEEKOFYEAR(d)                                      AS WEEK,
    DAYOFWEEK(d)                                       AS DAY_OF_WEEK,
    DAYNAME(d)                                         AS DAY_NAME,
    CASE WHEN DAYOFWEEK(d) IN (0, 6) THEN TRUE ELSE FALSE END AS IS_WEEKEND,
    -- US holidays
    CASE
        WHEN MONTH(d) = 1 AND DAY(d) = 1 THEN TRUE    -- New Year
        WHEN MONTH(d) = 7 AND DAY(d) = 4 THEN TRUE    -- July 4th
        WHEN MONTH(d) = 12 AND DAY(d) = 25 THEN TRUE  -- Christmas
        WHEN MONTH(d) = 11 AND DAYOFWEEK(d) = 4 AND DAY(d) BETWEEN 22 AND 28 THEN TRUE -- Thanksgiving
        ELSE FALSE
    END                                                AS IS_HOLIDAY,
    CASE
        WHEN MONTH(d) = 12 AND DAY(d) = 25 THEN 'Christmas'
        WHEN MONTH(d) = 11 AND DAYOFWEEK(d) = 4 AND DAY(d) BETWEEN 22 AND 28 THEN 'Thanksgiving'
        WHEN MONTH(d) = 1 AND DAY(d) = 1 THEN 'New Year'
        WHEN MONTH(d) = 7 AND DAY(d) = 4 THEN 'Independence Day'
        WHEN MONTH(d) = 2 AND DAY(d) = 14 THEN 'Valentines Day'
        ELSE NULL
    END                                                AS HOLIDAY_NAME,
    YEAR(d)                                            AS FISCAL_YEAR,
    MONTH(d)                                           AS FISCAL_PERIOD,
    CASE
        WHEN MONTH(d) IN (12, 1, 2) THEN 'WINTER'
        WHEN MONTH(d) IN (3, 4, 5) THEN 'SPRING'
        WHEN MONTH(d) IN (6, 7, 8) THEN 'SUMMER'
        ELSE 'FALL'
    END                                                AS SEASON
FROM (
    SELECT DATEADD('day', SEQ4(), DATEADD('year', -5, CURRENT_DATE())) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))
) dates
WHERE d < CURRENT_DATE();

-- ============================================================================
-- 2. DIM_CUSTOMER (5,000 customers with realistic segments)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.DIM_CUSTOMER
    (CUSTOMER_KEY, CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL_HASH, LOYALTY_TIER,
     LOYALTY_MEMBER_SINCE, PREFERRED_CHANNEL, PREFERRED_STORE_ID, CITY, STATE, ZIP_CODE,
     CUSTOMER_SEGMENT, LIFETIME_VALUE, FIRST_PURCHASE_DATE, LAST_PURCHASE_DATE,
     _VALID_FROM, _VALID_TO, _IS_CURRENT)
SELECT
    seq                                                AS CUSTOMER_KEY,
    'CUST-' || LPAD(seq::VARCHAR, 7, '0')              AS CUSTOMER_ID,
    GET(ARRAY_CONSTRUCT('James', 'Mary', 'Robert', 'Patricia', 'John', 'Jennifer', 'Michael', 'Linda',
        'David', 'Elizabeth', 'William', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica',
        'Thomas', 'Sarah', 'Christopher', 'Karen'), UNIFORM(0, 19, RANDOM()))::VARCHAR AS FIRST_NAME,
    GET(ARRAY_CONSTRUCT('Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
        'Rodriguez', 'Martinez', 'Anderson', 'Taylor', 'Thomas', 'Moore', 'Jackson', 'Martin',
        'Lee', 'Thompson', 'White', 'Harris'), UNIFORM(0, 19, RANDOM()))::VARCHAR AS LAST_NAME,
    MD5(seq::VARCHAR || 'email')                       AS EMAIL_HASH,
    -- Loyalty: Pareto - few Platinum, many Bronze
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 5 THEN 'PLATINUM'
        WHEN UNIFORM(0, 100, RANDOM()) < 20 THEN 'GOLD'
        WHEN UNIFORM(0, 100, RANDOM()) < 50 THEN 'SILVER'
        ELSE 'BRONZE'
    END                                                AS LOYALTY_TIER,
    DATEADD('day', -UNIFORM(60, 1800, RANDOM()), CURRENT_DATE()) AS LOYALTY_MEMBER_SINCE,
    GET(ARRAY_CONSTRUCT('STORE', 'STORE', 'STORE', 'ONLINE', 'ONLINE', 'OMNI'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS PREFERRED_CHANNEL,
    'S' || LPAD(UNIFORM(1, 50, RANDOM())::VARCHAR, 3, '0') AS PREFERRED_STORE_ID,
    GET(ARRAY_CONSTRUCT('New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia',
        'San Antonio', 'San Diego', 'Dallas', 'Austin', 'Jacksonville', 'Columbus', 'Charlotte',
        'Indianapolis', 'San Francisco', 'Seattle', 'Denver', 'Nashville', 'Portland', 'Detroit'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS CITY,
    GET(ARRAY_CONSTRUCT('NY', 'CA', 'IL', 'TX', 'AZ', 'PA', 'TX', 'CA', 'TX', 'TX',
        'FL', 'OH', 'NC', 'IN', 'CA', 'WA', 'CO', 'TN', 'OR', 'MI'),
        UNIFORM(0, 19, RANDOM()))::VARCHAR             AS STATE,
    LPAD(UNIFORM(10001, 99999, RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    -- Segment distribution: power law (few VIPs, many occasional)
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 3 THEN 'VIP'
        WHEN UNIFORM(0, 100, RANDOM()) < 15 THEN 'REGULAR'
        WHEN UNIFORM(0, 100, RANDOM()) < 40 THEN 'OCCASIONAL'
        WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 'AT_RISK'
        ELSE 'LAPSED'
    END                                                AS CUSTOMER_SEGMENT,
    -- CLV: log-normal (few high spenders dominate)
    ROUND(EXP(NORMAL(6.0, 1.5, RANDOM())), 2)         AS LIFETIME_VALUE, -- median ~$400, some >$10K
    DATEADD('day', -UNIFORM(90, 1800, RANDOM()), CURRENT_DATE()) AS FIRST_PURCHASE_DATE,
    DATEADD('day', -UNIFORM(1, 180, RANDOM()), CURRENT_DATE()) AS LAST_PURCHASE_DATE,
    DATEADD('year', -5, CURRENT_DATE())                AS _VALID_FROM,
    NULL                                               AS _VALID_TO,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 5000)));

-- ============================================================================
-- 3. DIM_PRODUCT (500 products across categories)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.DIM_PRODUCT
    (PRODUCT_KEY, SKU, PRODUCT_NAME, BRAND, CATEGORY_L1, CATEGORY_L2, CATEGORY_L3,
     SUPPLIER_ID, IS_PRIVATE_LABEL, SHELF_LIFE_DAYS, PRICE_REGULAR, PRICE_COST, MARGIN_PCT,
     SEASON_CODE, _IS_CURRENT)
SELECT
    seq                                                AS PRODUCT_KEY,
    'SKU-' || LPAD(seq::VARCHAR, 6, '0')               AS SKU,
    GET(ARRAY_CONSTRUCT(
        'Organic Whole Milk', 'Premium Ground Coffee', 'Artisan Sourdough Bread', 'Free Range Eggs 12pk',
        'Greek Yogurt Variety', 'Fresh Atlantic Salmon', 'Grass-Fed Ground Beef', 'Baby Spinach Mix',
        'Craft IPA 6-Pack', 'Sparkling Water 12pk', 'Almond Butter Smooth', 'Dark Chocolate 72%',
        'Frozen Pizza Margherita', 'Laundry Detergent 64oz', 'Paper Towels 8-Roll', 'Dish Soap Lemon',
        'Vitamin D3 5000IU', 'Protein Bar Box 12ct', 'Kombucha Ginger 16oz', 'Trail Mix Premium'
    ), MOD(seq - 1, 20))::VARCHAR || ' v' || CEIL(seq / 20)::VARCHAR AS PRODUCT_NAME,
    GET(ARRAY_CONSTRUCT(
        'Horizon Organic', 'Starbucks', 'La Boulangerie', 'Happy Hen', 'Chobani',
        'Wild Ocean', 'Belmont Ranch', 'Taylor Farms', 'Dogfish Head', 'LaCroix',
        'Justin''s', 'Lindt', 'Newman Own', 'Tide', 'Bounty', 'Dawn',
        'Nature Made', 'Kind', 'GT''s', 'Planters'
    ), MOD(seq - 1, 20))::VARCHAR                      AS BRAND,
    GET(ARRAY_CONSTRUCT('Grocery', 'Grocery', 'Grocery', 'Grocery', 'Grocery',
        'Fresh', 'Fresh', 'Fresh', 'Beverage', 'Beverage',
        'Grocery', 'Grocery', 'Frozen', 'Household', 'Household', 'Household',
        'Health', 'Health', 'Beverage', 'Grocery'),
        MOD(seq - 1, 20))::VARCHAR                     AS CATEGORY_L1,
    GET(ARRAY_CONSTRUCT('Dairy', 'Coffee & Tea', 'Bakery', 'Eggs', 'Dairy',
        'Seafood', 'Meat', 'Produce', 'Beer', 'Water',
        'Spreads', 'Candy', 'Frozen Meals', 'Laundry', 'Paper', 'Cleaning',
        'Vitamins', 'Snack Bars', 'Functional', 'Nuts & Seeds'),
        MOD(seq - 1, 20))::VARCHAR                     AS CATEGORY_L2,
    GET(ARRAY_CONSTRUCT('Milk', 'Ground Coffee', 'Bread', 'Shell Eggs', 'Yogurt',
        'Fresh Fish', 'Ground Beef', 'Salad Mix', 'IPA', 'Sparkling',
        'Nut Butter', 'Premium Chocolate', 'Pizza', 'Liquid Detergent', 'Paper Towels', 'Dish Liquid',
        'Supplements', 'Protein Bars', 'Kombucha', 'Trail Mix'),
        MOD(seq - 1, 20))::VARCHAR                     AS CATEGORY_L3,
    'SUP-' || LPAD(UNIFORM(1, 30, RANDOM())::VARCHAR, 4, '0') AS SUPPLIER_ID,
    IFF(UNIFORM(0, 100, RANDOM()) < 15, TRUE, FALSE)  AS IS_PRIVATE_LABEL,
    IFF(MOD(seq - 1, 20) IN (0,2,3,4,5,6,7,18), UNIFORM(5, 30, RANDOM()), NULL) AS SHELF_LIFE_DAYS,
    -- Price: log-normal distribution
    ROUND(EXP(NORMAL(1.8, 0.6, RANDOM())), 2)         AS PRICE_REGULAR,  -- median ~$6, range $2-$50
    ROUND(EXP(NORMAL(1.8, 0.6, RANDOM())) * UNIFORM(40, 70, RANDOM()) / 100.0, 2) AS PRICE_COST,
    ROUND(UNIFORM(25, 55, RANDOM()) / 100.0, 4)       AS MARGIN_PCT,
    GET(ARRAY_CONSTRUCT('ALL', 'ALL', 'ALL', 'ALL', 'ALL', 'ALL', 'ALL', 'ALL',
        'SUMMER', 'ALL', 'ALL', 'HOLIDAY', 'ALL', 'ALL', 'ALL', 'ALL',
        'ALL', 'ALL', 'ALL', 'ALL'),
        MOD(seq - 1, 20))::VARCHAR                     AS SEASON_CODE,
    TRUE                                               AS _IS_CURRENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 500)));

-- ============================================================================
-- 4. DIM_STORE (50 stores)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.DIM_STORE
    (STORE_KEY, STORE_ID, STORE_NAME, STORE_FORMAT, CITY, STATE, ZIP_CODE, REGION,
     DISTRICT, LATITUDE, LONGITUDE, SQUARE_FOOTAGE, OPEN_DATE)
SELECT
    seq                                                AS STORE_KEY,
    'S' || LPAD(seq::VARCHAR, 3, '0')                  AS STORE_ID,
    'Summit ' || GET(ARRAY_CONSTRUCT('Plaza', 'Market', 'Fresh', 'Express', 'Super'),
        MOD(seq - 1, 5))::VARCHAR || ' #' || seq::VARCHAR AS STORE_NAME,
    GET(ARRAY_CONSTRUCT('HYPERMARKET', 'HYPERMARKET', 'SUPERMARKET', 'SUPERMARKET', 'SUPERMARKET',
        'SUPERMARKET', 'EXPRESS', 'EXPRESS', 'ONLINE_FC', 'SUPERMARKET'),
        MOD(seq - 1, 10))::VARCHAR                     AS STORE_FORMAT,
    GET(ARRAY_CONSTRUCT('New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
        'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'Austin',
        'Jacksonville', 'Columbus', 'Charlotte', 'Indianapolis', 'San Francisco',
        'Seattle', 'Denver', 'Nashville', 'Portland', 'Detroit',
        'Memphis', 'Boston', 'Baltimore', 'Milwaukee', 'Albuquerque',
        'Tucson', 'Fresno', 'Sacramento', 'Mesa', 'Atlanta',
        'Kansas City', 'Omaha', 'Miami', 'Raleigh', 'Minneapolis',
        'Cleveland', 'Tampa', 'St Louis', 'Pittsburgh', 'Cincinnati',
        'Orlando', 'Las Vegas', 'Louisville', 'Richmond', 'Oklahoma City',
        'Hartford', 'Salt Lake City', 'Birmingham', 'Buffalo', 'Rochester'),
        seq - 1)::VARCHAR                              AS CITY,
    GET(ARRAY_CONSTRUCT('NY', 'CA', 'IL', 'TX', 'AZ', 'PA', 'TX', 'CA', 'TX', 'TX',
        'FL', 'OH', 'NC', 'IN', 'CA', 'WA', 'CO', 'TN', 'OR', 'MI',
        'TN', 'MA', 'MD', 'WI', 'NM', 'AZ', 'CA', 'CA', 'AZ', 'GA',
        'MO', 'NE', 'FL', 'NC', 'MN', 'OH', 'FL', 'MO', 'PA', 'OH',
        'FL', 'NV', 'KY', 'VA', 'OK', 'CT', 'UT', 'AL', 'NY', 'NY'),
        seq - 1)::VARCHAR                              AS STATE,
    LPAD(UNIFORM(10001, 99999, RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    GET(ARRAY_CONSTRUCT('Northeast', 'West', 'Midwest', 'South', 'West',
        'Northeast', 'South', 'West', 'South', 'South'),
        MOD(seq - 1, 10))::VARCHAR                     AS REGION,
    'District ' || CEIL(seq / 10)::VARCHAR             AS DISTRICT,
    ROUND(UNIFORM(2500, 4800, RANDOM()) / 100.0, 4)   AS LATITUDE,
    ROUND(-UNIFORM(7000, 12500, RANDOM()) / 100.0, 4) AS LONGITUDE,
    UNIFORM(8000, 120000, RANDOM())                    AS SQUARE_FOOTAGE,
    DATEADD('day', -UNIFORM(365, 7300, RANDOM()), CURRENT_DATE()) AS OPEN_DATE
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 50)));

-- ============================================================================
-- 5. DIM_PROMOTION (200 promotions over 5 years)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.DIM_PROMOTION
    (PROMOTION_KEY, PROMOTION_ID, PROMOTION_NAME, PROMOTION_TYPE, CHANNEL,
     START_DATE, END_DATE, DISCOUNT_VALUE, TARGET_SEGMENT)
SELECT
    seq                                                AS PROMOTION_KEY,
    'PROMO-' || LPAD(seq::VARCHAR, 5, '0')             AS PROMOTION_ID,
    GET(ARRAY_CONSTRUCT(
        'Black Friday Blowout', 'Back to School Savings', 'Summer Fresh Deals', 'Valentine Special',
        'Spring Cleaning Sale', 'Holiday Gift Guide', 'New Year New You', 'Easter Basket Bonanza',
        'Memorial Day BBQ', 'Labor Day Deals', 'Loyalty Double Points', 'Buy 2 Get 1',
        'Flash Sale 24hr', 'Category Champion', 'Weekend Warriors', 'Digital Exclusive'
    ), MOD(seq - 1, 16))::VARCHAR || ' ' || CEIL(seq / 16)::VARCHAR AS PROMOTION_NAME,
    GET(ARRAY_CONSTRUCT('PERCENTAGE_OFF', 'PERCENTAGE_OFF', 'BOGO', 'FIXED_AMOUNT', 'FREE_SHIPPING', 'PERCENTAGE_OFF'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS PROMOTION_TYPE,
    GET(ARRAY_CONSTRUCT('OMNI', 'STORE', 'ONLINE', 'OMNI', 'ONLINE', 'STORE'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS CHANNEL,
    DATEADD('day', -UNIFORM(1, 1800, RANDOM()), CURRENT_DATE()) AS START_DATE,
    DATEADD('day', -UNIFORM(1, 1800, RANDOM()) + UNIFORM(3, 30, RANDOM()), CURRENT_DATE()) AS END_DATE,
    ROUND(UNIFORM(5, 50, RANDOM()) * 1.0, 2)          AS DISCOUNT_VALUE,
    GET(ARRAY_CONSTRUCT('ALL', 'ALL', 'LOYALTY_GOLD+', 'NEW_CUSTOMERS', 'AT_RISK', 'VIP'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS TARGET_SEGMENT
FROM (SELECT SEQ4() + 1 AS seq FROM TABLE(GENERATOR(ROWCOUNT => 200)));

-- ============================================================================
-- 6. FACT_SALES (~500,000 transactions over 5 years)
-- Seasonality: Black Friday week (+60%), Dec 1-23 (+40%), back-to-school Aug (+20%),
--              Valentine's week (+15%), summer June-July (+10%), Jan post-holiday (-20%)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.FACT_SALES
    (TRANSACTION_ID, CUSTOMER_KEY, PRODUCT_KEY, STORE_KEY, DATE_KEY, PROMOTION_KEY,
     CHANNEL, QUANTITY, UNIT_PRICE, DISCOUNT_AMOUNT, NET_REVENUE, COST_OF_GOODS,
     GROSS_MARGIN, MARGIN_PCT, BASKET_ID, IS_RETURN, RETURN_REASON)
SELECT
    'TXN-' || LPAD(ROW_NUMBER() OVER (ORDER BY d.DATE_KEY, s.STORE_KEY)::VARCHAR, 9, '0') AS TRANSACTION_ID,
    -- 70% identified customers, 30% anonymous
    IFF(UNIFORM(0, 100, RANDOM()) < 70, UNIFORM(1, 5000, RANDOM()), NULL) AS CUSTOMER_KEY,
    UNIFORM(1, 500, RANDOM())                          AS PRODUCT_KEY,
    s.STORE_KEY                                        AS STORE_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    IFF(UNIFORM(0, 100, RANDOM()) < 25, UNIFORM(1, 200, RANDOM()), NULL) AS PROMOTION_KEY, -- 25% on promotion
    GET(ARRAY_CONSTRUCT('STORE', 'STORE', 'STORE', 'STORE', 'ONLINE', 'ONLINE', 'CLICK_COLLECT'),
        UNIFORM(0, 6, RANDOM()))::VARCHAR              AS CHANNEL,
    GREATEST(1, ROUND(NORMAL(2.5, 1.5, RANDOM())))::INT AS QUANTITY,
    -- Price: log-normal
    ROUND(EXP(NORMAL(1.8, 0.6, RANDOM())), 2)         AS UNIT_PRICE,
    IFF(UNIFORM(0, 100, RANDOM()) < 25,
        ROUND(EXP(NORMAL(1.8, 0.6, RANDOM())) * UNIFORM(5, 30, RANDOM()) / 100.0, 2), 0) AS DISCOUNT_AMOUNT,
    ROUND(EXP(NORMAL(2.2, 0.7, RANDOM())), 2)         AS NET_REVENUE,
    ROUND(EXP(NORMAL(2.2, 0.7, RANDOM())) * UNIFORM(40, 70, RANDOM()) / 100.0, 2) AS COST_OF_GOODS,
    ROUND(EXP(NORMAL(2.2, 0.7, RANDOM())) * UNIFORM(25, 55, RANDOM()) / 100.0, 2) AS GROSS_MARGIN,
    ROUND(UNIFORM(20, 55, RANDOM()) / 100.0, 4)       AS MARGIN_PCT,
    'BSK-' || TO_CHAR(d.FULL_DATE, 'YYYYMMDD') || '-' || LPAD(UNIFORM(1, 5000, RANDOM())::VARCHAR, 5, '0') AS BASKET_ID,
    IFF(UNIFORM(0, 100, RANDOM()) < 4, TRUE, FALSE)   AS IS_RETURN, -- 4% return rate
    IFF(UNIFORM(0, 100, RANDOM()) < 4,
        GET(ARRAY_CONSTRUCT('DEFECTIVE', 'WRONG_SIZE', 'CHANGED_MIND', 'DUPLICATE', 'PRICE_MATCH'),
            UNIFORM(0, 4, RANDOM()))::VARCHAR, NULL)   AS RETURN_REASON
FROM SUMMIT_RETAIL.GOLD.DIM_DATE d
CROSS JOIN (SELECT STORE_KEY FROM SUMMIT_RETAIL.GOLD.DIM_STORE LIMIT 20) s
WHERE
    -- Seasonal volume control: base ~40 transactions/store/day, modulated by season
    UNIFORM(0, 100, RANDOM()) < (
        40
        -- Black Friday week (day after Thanksgiving through following Sunday)
        + CASE WHEN MONTH(d.FULL_DATE) = 11 AND DAY(d.FULL_DATE) BETWEEN 24 AND 30 THEN 35 ELSE 0 END
        -- December holiday shopping
        + CASE WHEN MONTH(d.FULL_DATE) = 12 AND DAY(d.FULL_DATE) BETWEEN 1 AND 23 THEN 25 ELSE 0 END
        -- Back to school (August)
        + CASE WHEN MONTH(d.FULL_DATE) = 8 THEN 10 ELSE 0 END
        -- Valentine's week
        + CASE WHEN MONTH(d.FULL_DATE) = 2 AND DAY(d.FULL_DATE) BETWEEN 7 AND 14 THEN 8 ELSE 0 END
        -- Summer boost
        + CASE WHEN MONTH(d.FULL_DATE) IN (6, 7) THEN 5 ELSE 0 END
        -- Post-holiday January dip
        - CASE WHEN MONTH(d.FULL_DATE) = 1 THEN 12 ELSE 0 END
        -- Weekend boost
        + CASE WHEN DAYOFWEEK(d.FULL_DATE) IN (0, 6) THEN 10 ELSE 0 END
        -- YoY growth 4%
        + ROUND(4 * DATEDIFF('month', DATEADD('year', -5, CURRENT_DATE()), d.FULL_DATE) / 60.0)
    );

-- ============================================================================
-- 7. FACT_INVENTORY_DAILY (~150,000 rows: 50 stores x top 100 products x sampled days)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.FACT_INVENTORY_DAILY
    (STORE_KEY, PRODUCT_KEY, DATE_KEY, QTY_ON_HAND, QTY_IN_TRANSIT, QTY_AVAILABLE,
     DAYS_OF_SUPPLY, STOCKOUT_FLAG, OVERSTOCK_FLAG, STOCK_VALUE)
SELECT
    s.STORE_KEY                                        AS STORE_KEY,
    p.PRODUCT_KEY                                      AS PRODUCT_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    -- On-hand: seasonal with occasional stockouts
    GREATEST(0, ROUND(NORMAL(80, 30, RANDOM())
        * (1.0 - 0.3 * CASE WHEN MONTH(d.FULL_DATE) IN (11, 12) THEN 1 ELSE 0 END) -- depleted in holiday
        * IFF(UNIFORM(0, 100, RANDOM()) < 3, 0, 1.0)  -- 3% stockout
    ))                                                 AS QTY_ON_HAND,
    GREATEST(0, ROUND(NORMAL(20, 10, RANDOM())))       AS QTY_IN_TRANSIT,
    GREATEST(0, ROUND(NORMAL(70, 25, RANDOM())))       AS QTY_AVAILABLE,
    GREATEST(0, ROUND(NORMAL(12, 5, RANDOM()), 1))     AS DAYS_OF_SUPPLY,
    IFF(UNIFORM(0, 100, RANDOM()) < 3, TRUE, FALSE)   AS STOCKOUT_FLAG,
    IFF(UNIFORM(0, 100, RANDOM()) < 8, TRUE, FALSE)   AS OVERSTOCK_FLAG,
    ROUND(GREATEST(0, NORMAL(80, 30, RANDOM())) * EXP(NORMAL(1.8, 0.6, RANDOM())), 2) AS STOCK_VALUE
FROM SUMMIT_RETAIL.GOLD.DIM_DATE d
CROSS JOIN (SELECT STORE_KEY FROM SUMMIT_RETAIL.GOLD.DIM_STORE LIMIT 15) s
CROSS JOIN (SELECT PRODUCT_KEY FROM SUMMIT_RETAIL.GOLD.DIM_PRODUCT LIMIT 50) p
WHERE
    -- Weekly snapshots only to manage volume
    DAYOFWEEK(d.FULL_DATE) = 1
    AND UNIFORM(0, 100, RANDOM()) < 70;

-- ============================================================================
-- 8. FACT_CUSTOMER_INTERACTION (~30,000 contact center interactions)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.FACT_CUSTOMER_INTERACTION
    (CUSTOMER_KEY, DATE_KEY, INTERACTION_TYPE, CHANNEL, HANDLE_TIME_SEC,
     WAIT_TIME_SEC, SENTIMENT_SCORE, CSAT_SCORE, FCR_FLAG, WRAP_UP_CATEGORY)
SELECT
    UNIFORM(1, 5000, RANDOM())                         AS CUSTOMER_KEY,
    d.DATE_KEY                                         AS DATE_KEY,
    GET(ARRAY_CONSTRUCT('INQUIRY', 'COMPLAINT', 'RETURN_REQUEST', 'ORDER_STATUS', 'PRODUCT_INFO', 'BILLING'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS INTERACTION_TYPE,
    GET(ARRAY_CONSTRUCT('VOICE', 'VOICE', 'CHAT', 'CHAT', 'EMAIL', 'SMS'),
        UNIFORM(0, 5, RANDOM()))::VARCHAR              AS CHANNEL,
    GREATEST(30, ROUND(NORMAL(300, 120, RANDOM())))    AS HANDLE_TIME_SEC,
    GREATEST(0, ROUND(NORMAL(60, 45, RANDOM())))       AS WAIT_TIME_SEC,
    IFF(UNIFORM(0, 100, RANDOM()) < 2, NULL,
        LEAST(1.0, GREATEST(0.0, ROUND(NORMAL(0.65, 0.2, RANDOM()), 4)))) AS SENTIMENT_SCORE,
    IFF(UNIFORM(0, 100, RANDOM()) < 30, NULL,
        UNIFORM(1, 10, RANDOM()))                      AS CSAT_SCORE,
    IFF(UNIFORM(0, 100, RANDOM()) < 72, TRUE, FALSE)  AS FCR_FLAG,
    GET(ARRAY_CONSTRUCT('ORDER_STATUS', 'RETURN_PROCESS', 'COMPLAINT_RESOLVED', 'PRODUCT_INFO',
        'BILLING_ISSUE', 'LOYALTY_INQUIRY', 'DELIVERY_PROBLEM', 'EXCHANGE'),
        UNIFORM(0, 7, RANDOM()))::VARCHAR              AS WRAP_UP_CATEGORY
FROM SUMMIT_RETAIL.GOLD.DIM_DATE d
WHERE UNIFORM(0, 100, RANDOM()) < (
    -- More contacts during/after peak shopping (returns in Jan, holiday inquiries)
    12
    + CASE WHEN MONTH(d.FULL_DATE) = 1 THEN 8 ELSE 0 END  -- post-holiday returns
    + CASE WHEN MONTH(d.FULL_DATE) IN (11, 12) THEN 6 ELSE 0 END  -- holiday inquiries
);

-- ============================================================================
-- 9. AGG_SALES_DAILY (computed from FACT_SALES)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.AGG_SALES_DAILY
    (DATE_KEY, STORE_KEY, CATEGORY_L1, CHANNEL, TOTAL_TRANSACTIONS, TOTAL_UNITS,
     TOTAL_REVENUE, TOTAL_MARGIN, AVG_BASKET_SIZE, AVG_ITEMS_PER_BASKET,
     UNIQUE_CUSTOMERS, NEW_CUSTOMERS, RETURNING_CUSTOMERS)
SELECT
    f.DATE_KEY,
    f.STORE_KEY,
    COALESCE(p.CATEGORY_L1, 'Unknown')                 AS CATEGORY_L1,
    f.CHANNEL,
    COUNT(DISTINCT f.BASKET_ID)                        AS TOTAL_TRANSACTIONS,
    SUM(f.QUANTITY)::INT                               AS TOTAL_UNITS,
    ROUND(SUM(f.NET_REVENUE), 2)                       AS TOTAL_REVENUE,
    ROUND(SUM(f.GROSS_MARGIN), 2)                      AS TOTAL_MARGIN,
    ROUND(AVG(f.NET_REVENUE), 2)                       AS AVG_BASKET_SIZE,
    ROUND(AVG(f.QUANTITY), 1)                          AS AVG_ITEMS_PER_BASKET,
    COUNT(DISTINCT f.CUSTOMER_KEY)                     AS UNIQUE_CUSTOMERS,
    ROUND(COUNT(DISTINCT f.CUSTOMER_KEY) * 0.15)::INT  AS NEW_CUSTOMERS,
    ROUND(COUNT(DISTINCT f.CUSTOMER_KEY) * 0.85)::INT  AS RETURNING_CUSTOMERS
FROM SUMMIT_RETAIL.GOLD.FACT_SALES f
LEFT JOIN SUMMIT_RETAIL.GOLD.DIM_PRODUCT p ON f.PRODUCT_KEY = p.PRODUCT_KEY
GROUP BY f.DATE_KEY, f.STORE_KEY, p.CATEGORY_L1, f.CHANNEL;

-- ============================================================================
-- 10. AGG_CUSTOMER_RFM (latest snapshot)
-- ============================================================================
INSERT INTO SUMMIT_RETAIL.GOLD.AGG_CUSTOMER_RFM
    (CUSTOMER_KEY, COMPUTED_DATE, RECENCY_DAYS, FREQUENCY_90D, MONETARY_90D,
     RECENCY_SCORE, FREQUENCY_SCORE, MONETARY_SCORE, RFM_SEGMENT, CLV_PREDICTED)
SELECT
    CUSTOMER_KEY,
    DATEADD('day', -1, CURRENT_DATE())                 AS COMPUTED_DATE,
    UNIFORM(1, 365, RANDOM())                          AS RECENCY_DAYS,
    GREATEST(0, ROUND(NORMAL(4, 3, RANDOM())))::INT    AS FREQUENCY_90D,
    ROUND(EXP(NORMAL(4.5, 1.2, RANDOM())), 2)         AS MONETARY_90D,
    UNIFORM(1, 5, RANDOM())                            AS RECENCY_SCORE,
    UNIFORM(1, 5, RANDOM())                            AS FREQUENCY_SCORE,
    UNIFORM(1, 5, RANDOM())                            AS MONETARY_SCORE,
    CASE
        WHEN UNIFORM(0, 100, RANDOM()) < 10 THEN 'CHAMPIONS'
        WHEN UNIFORM(0, 100, RANDOM()) < 25 THEN 'LOYAL'
        WHEN UNIFORM(0, 100, RANDOM()) < 40 THEN 'POTENTIAL'
        WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 'AT_RISK'
        WHEN UNIFORM(0, 100, RANDOM()) < 80 THEN 'HIBERNATING'
        ELSE 'LOST'
    END                                                AS RFM_SEGMENT,
    ROUND(EXP(NORMAL(5.5, 1.5, RANDOM())), 2)         AS CLV_PREDICTED
FROM SUMMIT_RETAIL.GOLD.DIM_CUSTOMER
WHERE _IS_CURRENT = TRUE;
