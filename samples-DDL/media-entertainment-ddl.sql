-- ============================================================================
-- MEDIA & ENTERTAINMENT VERTICAL - Sample DDL
-- Source Systems: Adobe Analytics (Web/App Events), Conviva (Video QoE),
--                 Brightcove (Content CMS), Salesforce CDP (Profiles),
--                 Stripe (Subscriptions)
-- Entity: Nova Media Group
-- ============================================================================

CREATE DATABASE IF NOT EXISTS NOVA_MEDIA;

-- ============================================================================
-- SILVER LAYER - Cleaned & conformed from source systems
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS NOVA_MEDIA.SILVER;

-- Source: Adobe Analytics (Streaming Events)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.ADOBE_STREAM_EVENT (
    EVENT_ID            VARCHAR(50) NOT NULL,
    USER_ID             VARCHAR(30),
    SESSION_ID          VARCHAR(50),
    CONTENT_ID          VARCHAR(30),
    EVENT_TYPE          VARCHAR(30),           -- PLAY_START, PLAY_END, PAUSE, SEEK, RESUME, AD_START, AD_END
    TIMESTAMP           TIMESTAMP_NTZ NOT NULL,
    DEVICE_TYPE         VARCHAR(20),           -- SMART_TV, MOBILE, TABLET, DESKTOP, GAME_CONSOLE
    PLATFORM            VARCHAR(20),           -- IOS, ANDROID, WEB, ROKU, FIRE_TV, APPLE_TV
    GEO_COUNTRY         VARCHAR(5),
    GEO_STATE           VARCHAR(5),
    DURATION_SECONDS    NUMBER(10),
    CONTENT_POSITION_SEC NUMBER(10),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Adobe Analytics streaming events. Play/pause/seek interactions at sub-second grain.';

-- Source: Conviva (Video Quality of Experience)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.CONVIVA_QOE_SESSION (
    SESSION_ID          VARCHAR(50) NOT NULL,
    USER_ID             VARCHAR(30),
    CONTENT_ID          VARCHAR(30),
    START_TIME          TIMESTAMP_NTZ NOT NULL,
    END_TIME            TIMESTAMP_NTZ,
    BITRATE_AVG_KBPS    NUMBER(10),
    BUFFERING_RATIO     NUMBER(5,4),           -- % of time spent buffering
    STARTUP_TIME_MS     NUMBER(10),
    ERRORS              NUMBER(5),
    CDN_PROVIDER        VARCHAR(30),           -- CLOUDFRONT, AKAMAI, FASTLY
    DEVICE_TYPE         VARCHAR(20),
    OS_VERSION          VARCHAR(30),
    PLAYER_VERSION      VARCHAR(20),
    VIDEO_EXITS_BEFORE_START NUMBER(3),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Conviva video QoE session metrics. Buffering, bitrate, and startup performance.';

-- Source: Brightcove (Content CMS)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.BRIGHTCOVE_CONTENT (
    CONTENT_ID          VARCHAR(30) NOT NULL,
    TITLE               VARCHAR(300),
    SERIES_ID           VARCHAR(30),
    SERIES_NAME         VARCHAR(200),
    SEASON              NUMBER(3),
    EPISODE             NUMBER(5),
    GENRE               VARCHAR(50),           -- DRAMA, COMEDY, DOCUMENTARY, ACTION, HORROR, KIDS
    RELEASE_DATE        DATE,
    DURATION_MINUTES    NUMBER(5),
    CONTENT_TYPE        VARCHAR(20),           -- MOVIE, EPISODE, SHORT, TRAILER, LIVE_EVENT
    RATING              VARCHAR(10),           -- TV-MA, TV-14, TV-PG, TV-G, R, PG-13
    LANGUAGE            VARCHAR(10),
    RIGHTS_TERRITORY    VARCHAR(50),
    LICENSE_START       DATE,
    LICENSE_END         DATE,
    PRODUCTION_COST     NUMBER(12,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Brightcove content catalog. Metadata, rights windows, and classification.';

-- Source: Stripe (Subscriptions)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.STRIPE_SUBSCRIPTION (
    SUBSCRIPTION_ID     VARCHAR(30) NOT NULL,
    USER_ID             VARCHAR(30),
    PLAN_ID             VARCHAR(20),
    PLAN_NAME           VARCHAR(50),
    STATUS              VARCHAR(20),           -- ACTIVE, TRIALING, PAST_DUE, CANCELED, PAUSED
    START_DATE          DATE,
    CANCEL_DATE         DATE,
    TRIAL_END           DATE,
    MONTHLY_AMOUNT      NUMBER(8,2),
    CURRENCY            VARCHAR(5),
    PAYMENT_METHOD      VARCHAR(20),           -- CARD, PAYPAL, APPLE_PAY, GOOGLE_PAY
    CANCEL_REASON       VARCHAR(50),           -- PRICE, CONTENT, QUALITY, COMPETITOR, UNUSED
    CANCEL_FEEDBACK     VARCHAR(500),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Stripe subscription lifecycle. Trials, activations, cancellations, and win-backs.';

-- Source: Salesforce CDP (User Profiles)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.SFDC_USER_PROFILE (
    USER_ID             VARCHAR(30) NOT NULL,
    EMAIL               VARCHAR(200),
    SIGNUP_DATE         DATE,
    AGE_GROUP           VARCHAR(10),           -- 18-24, 25-34, 35-44, 45-54, 55-64, 65+
    GENDER              VARCHAR(10),
    COUNTRY             VARCHAR(5),
    STATE               VARCHAR(5),
    PREFERRED_LANGUAGE  VARCHAR(10),
    ACQUISITION_CHANNEL VARCHAR(30),           -- ORGANIC, PAID_SOCIAL, DISPLAY, REFERRAL, BUNDLE_PARTNER
    HOUSEHOLD_SIZE      NUMBER(2),
    VALID_FROM          TIMESTAMP_NTZ NOT NULL,
    VALID_TO            TIMESTAMP_NTZ,
    IS_CURRENT          BOOLEAN DEFAULT TRUE,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce CDP user profiles - SCD2. Demographics and acquisition attribution.';

-- Source: Adobe Analytics (Ad Impressions)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.ADOBE_AD_IMPRESSION (
    IMPRESSION_ID       VARCHAR(50) NOT NULL,
    USER_ID             VARCHAR(30),
    AD_ID               VARCHAR(30),
    CAMPAIGN_ID         VARCHAR(30),
    TIMESTAMP           TIMESTAMP_NTZ NOT NULL,
    PLACEMENT           VARCHAR(30),           -- PRE_ROLL, MID_ROLL, POST_ROLL, BANNER, INTERSTITIAL
    FORMAT              VARCHAR(20),           -- VIDEO_15S, VIDEO_30S, VIDEO_60S, DISPLAY, NATIVE
    VIEWABLE_FLAG       BOOLEAN,
    CLICK_FLAG          BOOLEAN,
    COMPLETION_FLAG     BOOLEAN,
    REVENUE_CPM         NUMBER(8,4),
    ADVERTISER_ID       VARCHAR(30),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Adobe ad impression delivery. AVOD/hybrid tier ad monetization events.';

-- Source: Brightcove (Content Rights)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.BRIGHTCOVE_RIGHTS (
    RIGHTS_ID           VARCHAR(30) NOT NULL,
    CONTENT_ID          VARCHAR(30),
    TERRITORY           VARCHAR(5),
    WINDOW_START        DATE,
    WINDOW_END          DATE,
    LICENSE_FEE         NUMBER(12,2),
    LICENSOR            VARCHAR(100),
    EXCLUSIVITY         VARCHAR(20),           -- EXCLUSIVE, NON_EXCLUSIVE, FIRST_RUN
    MINIMUM_GUARANTEE   NUMBER(12,2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Brightcove content rights/licenses. Territory and window management.';

-- Source: Adobe Analytics (Search Events)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.ADOBE_SEARCH_EVENT (
    SEARCH_ID           VARCHAR(50) NOT NULL,
    USER_ID             VARCHAR(30),
    QUERY_TEXT          VARCHAR(500),
    TIMESTAMP           TIMESTAMP_NTZ NOT NULL,
    RESULTS_COUNT       NUMBER(5),
    CLICK_POSITION      NUMBER(3),
    CONTENT_CLICKED_ID  VARCHAR(30),
    NO_RESULTS_FLAG     BOOLEAN,
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Adobe Analytics search/discovery events. Content findability and intent signals.';

-- Source: Stripe (Payments)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.STRIPE_PAYMENT (
    PAYMENT_ID          VARCHAR(30) NOT NULL,
    SUBSCRIPTION_ID     VARCHAR(30),
    USER_ID             VARCHAR(30),
    AMOUNT              NUMBER(8,2),
    CURRENCY            VARCHAR(5),
    STATUS              VARCHAR(20),           -- SUCCEEDED, FAILED, REFUNDED, DISPUTED
    PAYMENT_DATE        DATE,
    FAILURE_REASON      VARCHAR(50),           -- CARD_DECLINED, INSUFFICIENT_FUNDS, EXPIRED_CARD
    RETRY_COUNT         NUMBER(2),
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Stripe payment transactions. Revenue recognition and failed payment recovery.';

-- Source: Salesforce CDP (Marketing Campaigns)
CREATE OR REPLACE TABLE NOVA_MEDIA.SILVER.SFDC_CAMPAIGN (
    CAMPAIGN_ID         VARCHAR(30) NOT NULL,
    CAMPAIGN_NAME       VARCHAR(200),
    CHANNEL             VARCHAR(30),           -- EMAIL, PUSH, IN_APP, SOCIAL, DISPLAY, TV_PROMO
    START_DATE          DATE,
    END_DATE            DATE,
    BUDGET              NUMBER(12,2),
    ACTUAL_SPEND        NUMBER(12,2),
    TARGET_SEGMENT      VARCHAR(50),           -- NEW_RELEASE, WINBACK, TRIAL_CONVERT, UPSELL
    OBJECTIVE           VARCHAR(30),           -- AWARENESS, ACQUISITION, RETENTION, UPGRADE
    _LOADED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Salesforce CDP marketing campaigns. Audience targeting and budget allocation.';

-- ============================================================================
-- GOLD LAYER - Business-ready dimensional model
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS NOVA_MEDIA.GOLD;

-- Dimensions
CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.DIM_USER (
    USER_KEY            NUMBER AUTOINCREMENT,
    USER_ID             VARCHAR(30) NOT NULL,
    EMAIL_DOMAIN        VARCHAR(100),
    AGE_GROUP           VARCHAR(10),
    GENDER              VARCHAR(10),
    COUNTRY             VARCHAR(5),
    STATE               VARCHAR(5),
    PREFERRED_LANGUAGE  VARCHAR(10),
    ACQUISITION_CHANNEL VARCHAR(30),
    SIGNUP_DATE         DATE,
    COHORT_MONTH        DATE,
    TENURE_DAYS         NUMBER(5),
    HOUSEHOLD_SIZE      NUMBER(2),
    _VALID_FROM         TIMESTAMP_NTZ,
    _VALID_TO           TIMESTAMP_NTZ,
    _IS_CURRENT         BOOLEAN
) COMMENT = 'User/subscriber dimension - SCD2. Demographics, cohort, and tenure.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.DIM_CONTENT (
    CONTENT_KEY         NUMBER AUTOINCREMENT,
    CONTENT_ID          VARCHAR(30) NOT NULL,
    TITLE               VARCHAR(300),
    SERIES_NAME         VARCHAR(200),
    SEASON              NUMBER(3),
    EPISODE             NUMBER(5),
    GENRE               VARCHAR(50),
    CONTENT_TYPE        VARCHAR(20),
    DURATION_MINUTES    NUMBER(5),
    RATING              VARCHAR(10),
    RELEASE_DATE        DATE,
    LANGUAGE            VARCHAR(10),
    IS_ORIGINAL         BOOLEAN,
    PRODUCTION_COST     NUMBER(12,2)
) COMMENT = 'Content dimension. Catalog metadata for viewing and performance analysis.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.DIM_DATE (
    DATE_KEY            NUMBER NOT NULL,
    FULL_DATE           DATE NOT NULL,
    YEAR                NUMBER(4),
    QUARTER             NUMBER(1),
    MONTH               NUMBER(2),
    WEEK                NUMBER(2),
    DAY_OF_WEEK         NUMBER(1),
    IS_WEEKEND          BOOLEAN,
    IS_RELEASE_DAY      BOOLEAN
) COMMENT = 'Standard date dimension.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.DIM_PLAN (
    PLAN_KEY            NUMBER AUTOINCREMENT,
    PLAN_ID             VARCHAR(20) NOT NULL,
    PLAN_NAME           VARCHAR(50),
    MONTHLY_PRICE       NUMBER(8,2),
    TIER                VARCHAR(20),           -- BASIC, STANDARD, PREMIUM
    AD_SUPPORTED_FLAG   BOOLEAN,
    MAX_STREAMS         NUMBER(2),
    MAX_RESOLUTION      VARCHAR(10),           -- SD, HD, 4K
    LAUNCH_DATE         DATE,
    RETIRE_DATE         DATE
) COMMENT = 'Subscription plan dimension. Pricing tiers and feature sets.';

-- Facts
CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.FACT_VIEWING (
    DATE_KEY            NUMBER,
    USER_KEY            NUMBER,
    CONTENT_KEY         NUMBER,
    WATCH_TIME_MINUTES  NUMBER(10),
    COMPLETION_PCT      NUMBER(5,2),
    DEVICE_TYPE         VARCHAR(20),
    PLATFORM            VARCHAR(20),
    SESSIONS            NUMBER(5),
    BINGE_FLAG          BOOLEAN                -- 3+ episodes same series in one session
) COMMENT = 'Daily viewing fact. Watch time, completion, and binge behavior.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.FACT_SUBSCRIPTION (
    DATE_KEY            NUMBER,
    USER_KEY            NUMBER,
    PLAN_KEY            NUMBER,
    MRR                 NUMBER(8,2),
    STATUS              VARCHAR(20),
    TENURE_DAYS         NUMBER(5),
    TRIAL_FLAG          BOOLEAN,
    DOWNGRADE_FLAG      BOOLEAN,
    UPGRADE_FLAG        BOOLEAN
) COMMENT = 'Subscription status snapshot fact. MRR and lifecycle state tracking.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.FACT_AD_REVENUE (
    DATE_KEY            NUMBER,
    USER_KEY            NUMBER,
    CONTENT_KEY         NUMBER,
    IMPRESSIONS         NUMBER(10),
    CLICKS              NUMBER(10),
    COMPLETIONS         NUMBER(10),
    REVENUE             NUMBER(10,2),
    FILL_RATE           NUMBER(5,4),
    AVG_CPM             NUMBER(8,4)
) COMMENT = 'Ad revenue fact. AVOD/hybrid tier monetization by content and user.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.FACT_QOE (
    DATE_KEY            NUMBER,
    CONTENT_KEY         NUMBER,
    DEVICE_TYPE         VARCHAR(20),
    CDN_PROVIDER        VARCHAR(30),
    AVG_BITRATE_KBPS    NUMBER(10),
    BUFFER_RATIO        NUMBER(5,4),
    STARTUP_TIME_P50_MS NUMBER(10),
    STARTUP_TIME_P95_MS NUMBER(10),
    ERROR_RATE          NUMBER(5,4),
    SESSIONS            NUMBER(10),
    EXITS_BEFORE_START  NUMBER(10)
) COMMENT = 'Video quality of experience fact. CDN and device performance analysis.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.FACT_ENGAGEMENT (
    DATE_KEY            NUMBER,
    USER_KEY            NUMBER,
    SESSIONS            NUMBER(5),
    SEARCH_COUNT        NUMBER(5),
    WATCHLIST_ADDS      NUMBER(5),
    SHARES              NUMBER(5),
    RATINGS_GIVEN       NUMBER(5),
    PROFILES_SWITCHED   NUMBER(3),
    TOTAL_TIME_MINUTES  NUMBER(10)
) COMMENT = 'Daily user engagement fact. Multi-signal engagement composite.';

-- Aggregates
CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.AGG_CONTENT_DAILY (
    DATE_KEY            NUMBER,
    CONTENT_KEY         NUMBER,
    UNIQUE_VIEWERS      NUMBER(10),
    TOTAL_WATCH_HOURS   NUMBER(12,2),
    COMPLETION_RATE     NUMBER(5,4),
    AVG_RATING          NUMBER(3,1),
    SEARCH_IMPRESSIONS  NUMBER(10),
    COST_PER_VIEW_HOUR  NUMBER(8,4)
) COMMENT = 'Daily content performance aggregate. Viewership and efficiency metrics.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.AGG_COHORT_RETENTION (
    COHORT_MONTH_KEY    NUMBER,
    MONTHS_SINCE_SIGNUP NUMBER(3),
    PLAN_TIER           VARCHAR(20),
    ACTIVE_USERS        NUMBER(10),
    CHURNED_USERS       NUMBER(10),
    RETENTION_PCT       NUMBER(5,4),
    AVG_WATCH_HOURS     NUMBER(10,2),
    REVENUE_RETAINED    NUMBER(12,2)
) COMMENT = 'Monthly cohort retention analysis. Survival curves by plan tier.';

CREATE OR REPLACE TABLE NOVA_MEDIA.GOLD.AGG_DAU_MAU (
    DATE_KEY            NUMBER,
    PLAN_TIER           VARCHAR(20),
    DAU                 NUMBER(10),
    WAU                 NUMBER(10),
    MAU                 NUMBER(10),
    DAU_MAU_RATIO       NUMBER(5,4),
    AVG_SESSION_MINUTES NUMBER(10,2),
    SESSIONS_PER_USER   NUMBER(5,2)
) COMMENT = 'Daily/weekly/monthly active user metrics. Platform stickiness KPIs.';

