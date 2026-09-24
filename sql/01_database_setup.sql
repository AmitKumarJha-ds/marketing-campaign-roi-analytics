-- ================================================================
-- CampaignPulse - Marketing Campaign ROI Analytics
-- SQL FILE 01 : Database Setup
-- Target      : MySQL 8.0+ (also compatible with MariaDB 10.6+)
-- Author      : Amit Kumar Jha
-- Purpose     : Create the campaign_pulse_db database, the
--               marketing_campaigns table (all 41 columns of the
--               cleaned dataset), load the CSV export and create
--               the indexes required for analytical queries.
-- ================================================================

-- ----------------------------------------------------------------
-- 1. CREATE DATABASE
-- ----------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS campaign_pulse_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE campaign_pulse_db;

-- ----------------------------------------------------------------
-- 2. DROP TABLE IF EXISTS (idempotent re-runs)
-- ----------------------------------------------------------------
DROP TABLE IF EXISTS marketing_campaigns;

-- ----------------------------------------------------------------
-- 3. CREATE MAIN TABLE
--    27 source columns + 14 engineered columns = 41 columns
--    campaign_id is the primary key (validated as unique in
--    02_data_cleaning.sql).
-- ----------------------------------------------------------------
CREATE TABLE marketing_campaigns (

    -- ==================== IDENTIFIERS ====================
    campaign_id             VARCHAR(20)     NOT NULL,
    campaign_name           VARCHAR(200)    NULL,

    -- ==================== DIMENSIONS =====================
    campaign_type           VARCHAR(50)     NULL,
    channel                 VARCHAR(50)     NULL,
    target_audience         VARCHAR(50)     NULL,
    geography               VARCHAR(50)     NULL,

    -- ==================== DATES ==========================
    start_date              DATE            NULL,
    end_date                DATE            NULL,

    -- ==================== FINANCIALS ====================
    budget_allocated        DECIMAL(12,2)   NULL,
    amount_spent            DECIMAL(12,2)   NULL,
    revenue_generated       DECIMAL(14,2)   NULL,

    -- ==================== FUNNEL ========================
    impressions             BIGINT          NULL,
    clicks                  INT             NULL,
    leads_generated         INT             NULL,
    conversions             INT             NULL,

    -- ==================== KPI METRICS ===================
    roi_percentage          DECIMAL(10,2)   NULL,
    ctr                     DECIMAL(8,4)    NULL,
    conversion_rate         DECIMAL(8,4)    NULL,
    cpc                     DECIMAL(8,2)    NULL,
    cpa                     DECIMAL(8,2)    NULL,
    customer_acquisition_cost DECIMAL(8,2)  NULL,

    -- ==================== STATUS & TIME =================
    campaign_status         VARCHAR(20)     NULL,
    quarter                 VARCHAR(5)      NULL,
    year                    INT             NULL,

    -- ==================== ENGAGEMENT ====================
    satisfaction_score      DECIMAL(3,1)    NULL,
    bounce_rate             DECIMAL(6,2)    NULL,
    engagement_rate         DECIMAL(6,2)    NULL,

    -- ==================== ENGINEERED FEATURES ===========
    campaign_duration_days  INT             NULL,
    budget_utilization      DECIMAL(8,2)    NULL,
    revenue_per_impression  DECIMAL(12,6)   NULL,
    revenue_per_click       DECIMAL(12,2)   NULL,
    cost_efficiency_ratio   DECIMAL(10,2)   NULL,
    lead_to_conversion_rate DECIMAL(8,2)    NULL,
    profit                  DECIMAL(14,2)   NULL,
    profit_margin           DECIMAL(10,2)   NULL,
    campaign_month          VARCHAR(20)     NULL,
    campaign_quarter        INT             NULL,
    is_profitable           BOOLEAN         NULL,
    roi_category            VARCHAR(30)     NULL,
    budget_tier             VARCHAR(30)     NULL,
    performance_score       DECIMAL(8,2)    NULL,

    -- ==================== CONSTRAINTS ===================
    PRIMARY KEY (campaign_id),
    CONSTRAINT chk_dates     CHECK (end_date >= start_date),
    CONSTRAINT chk_spend     CHECK (amount_spent >= 0),
    CONSTRAINT chk_revenue   CHECK (revenue_generated >= 0),
    CONSTRAINT chk_funnel    CHECK (conversions <= leads_generated
                                AND leads_generated <= clicks
                                AND clicks <= impressions),
    CONSTRAINT chk_satisfaction CHECK (satisfaction_score BETWEEN 1 AND 5)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'CampaignPulse cleaned marketing campaign dataset';

-- ----------------------------------------------------------------
-- 4. LOAD DATA FROM CSV
--    Uncomment and adjust the path for your environment.
--    Make sure secure_file_priv allows the target directory:
--      SHOW VARIABLES LIKE 'secure_file_priv';
--    Alternative: use MySQL Workbench's "Table Data Import Wizard".
-- ----------------------------------------------------------------
-- LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marketing_campaign_cleaned.csv'
-- INTO TABLE marketing_campaigns
--     CHARACTER SET utf8mb4
--     FIELDS TERMINATED BY ','
--     OPTIONALLY ENCLOSED BY '"'
--     LINES TERMINATED BY '\r\n'
--     IGNORE 1 ROWS
--     (
--         campaign_id, campaign_name, campaign_type, channel, target_audience,
--         geography, start_date, end_date, budget_allocated, amount_spent,
--         impressions, clicks, leads_generated, conversions, revenue_generated,
--         roi_percentage, ctr, conversion_rate, cpc, cpa,
--         customer_acquisition_cost, campaign_status, quarter, year,
--         satisfaction_score, bounce_rate, engagement_rate, campaign_duration_days,
--         budget_utilization, revenue_per_impression, revenue_per_click,
--         cost_efficiency_ratio, lead_to_conversion_rate, profit, profit_margin,
--         campaign_month, campaign_quarter, @is_profitable, roi_category,
--         budget_tier, performance_score
--     )
--     SET is_profitable = (@is_profitable = 'True');

-- ----------------------------------------------------------------
-- 5. VERIFY DATA LOADED
-- ----------------------------------------------------------------
SELECT COUNT(*)                    AS total_records,
       COUNT(DISTINCT campaign_id) AS distinct_campaigns,
       MIN(start_date)             AS first_campaign,
       MAX(start_date)             AS last_campaign,
       SUM(budget_allocated)       AS total_budget,
       SUM(amount_spent)           AS total_spend,
       SUM(revenue_generated)      AS total_revenue
FROM marketing_campaigns;

SELECT * FROM marketing_campaigns LIMIT 10;

-- ----------------------------------------------------------------
-- 6. CREATE INDEXES FOR PERFORMANCE
--    Every dimension used in a GROUP BY / WHERE / JOIN in
--    03_business_queries.sql is indexed.
-- ----------------------------------------------------------------
CREATE INDEX idx_campaign_type ON marketing_campaigns(campaign_type);
CREATE INDEX idx_channel       ON marketing_campaigns(channel);
CREATE INDEX idx_geography     ON marketing_campaigns(geography);
CREATE INDEX idx_audience      ON marketing_campaigns(target_audience);
CREATE INDEX idx_year          ON marketing_campaigns(year);
CREATE INDEX idx_quarter       ON marketing_campaigns(campaign_quarter);
CREATE INDEX idx_status        ON marketing_campaigns(campaign_status);
CREATE INDEX idx_start_date    ON marketing_campaigns(start_date);
CREATE INDEX idx_roi           ON marketing_campaigns(roi_percentage);
CREATE INDEX idx_budget_tier   ON marketing_campaigns(budget_tier);

-- Composite index for the most common analytical slice
CREATE INDEX idx_channel_year   ON marketing_campaigns(channel, year);
CREATE INDEX idx_type_channel   ON marketing_campaigns(campaign_type, channel);

-- ----------------------------------------------------------------
-- 7. ANALYTICAL VIEWS
--    Pre-aggregated views so dashboards and reports do not have to
--    re-implement the same GROUP BY logic.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW vw_channel_performance AS
SELECT channel,
       COUNT(*)                                          AS campaigns,
       ROUND(AVG(roi_percentage), 2)                     AS avg_roi,
       ROUND(AVG(conversion_rate), 4)                    AS avg_conversion_rate,
       ROUND(AVG(ctr), 4)                                AS avg_ctr,
       ROUND(AVG(cpc), 2)                                AS avg_cpc,
       ROUND(AVG(cpa), 2)                                AS avg_cpa,
       ROUND(AVG(customer_acquisition_cost), 2)          AS avg_cac,
       ROUND(SUM(revenue_generated), 2)                  AS total_revenue,
       ROUND(SUM(profit), 2)                             AS total_profit,
       ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM marketing_campaigns
GROUP BY channel;

CREATE OR REPLACE VIEW vw_campaign_type_performance AS
SELECT campaign_type,
       COUNT(*)                                          AS campaigns,
       ROUND(AVG(roi_percentage), 2)                     AS avg_roi,
       ROUND(AVG(revenue_generated), 2)                  AS avg_revenue,
       ROUND(SUM(revenue_generated), 2)                  AS total_revenue,
       ROUND(SUM(profit), 2)                             AS total_profit,
       ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM marketing_campaigns
GROUP BY campaign_type;

CREATE OR REPLACE VIEW vw_monthly_trend AS
SELECT DATE_FORMAT(start_date, '%Y-%m-01')  AS month,
       YEAR(start_date)                     AS year,
       MONTH(start_date)                    AS month_num,
       COUNT(*)                             AS campaigns,
       ROUND(SUM(revenue_generated), 2)     AS revenue,
       ROUND(SUM(amount_spent), 2)          AS spend,
       ROUND(SUM(profit), 2)                AS profit,
       ROUND(AVG(roi_percentage), 2)        AS avg_roi
FROM marketing_campaigns
GROUP BY DATE_FORMAT(start_date, '%Y-%m-01'), YEAR(start_date), MONTH(start_date);

CREATE OR REPLACE VIEW vw_geography_performance AS
SELECT geography,
       COUNT(*)                                          AS campaigns,
       ROUND(AVG(roi_percentage), 2)                     AS avg_roi,
       ROUND(SUM(revenue_generated), 2)                  AS total_revenue,
       ROUND(AVG(customer_acquisition_cost), 2)          AS avg_cac,
       ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM marketing_campaigns
GROUP BY geography;

CREATE OR REPLACE VIEW vw_audience_performance AS
SELECT target_audience,
       COUNT(*)                                          AS campaigns,
       ROUND(AVG(roi_percentage), 2)                     AS avg_roi,
       ROUND(AVG(ctr), 4)                                AS avg_ctr,
       ROUND(AVG(conversion_rate), 4)                    AS avg_conversion_rate,
       ROUND(AVG(engagement_rate), 2)                    AS avg_engagement_rate,
       ROUND(AVG(customer_acquisition_cost), 2)          AS avg_cac
FROM marketing_campaigns
GROUP BY target_audience;

-- ----------------------------------------------------------------
-- 8. POST-SETUP VERIFICATION
-- ----------------------------------------------------------------
SHOW TABLES;

SELECT TABLE_NAME, TABLE_ROWS, TABLE_COMMENT
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'campaign_pulse_db';

SELECT INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns_indexed
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'campaign_pulse_db'
  AND TABLE_NAME = 'marketing_campaigns'
GROUP BY INDEX_NAME;

-- ================================================================
-- END OF 01_database_setup.sql
-- Next step: run 02_data_cleaning.sql, then 03_business_queries.sql
-- ================================================================
