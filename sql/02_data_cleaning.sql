-- ================================================================
-- CampaignPulse - Marketing Campaign ROI Analytics
-- SQL FILE 02 : Data Cleaning & Validation Queries
-- Target      : MySQL 8.0+
-- Purpose     : 12 read-only validation queries that audit the
--               marketing_campaigns table for NULLs, duplicates,
--               impossible values, broken dates, mis-computed KPIs
--               and outliers - plus the UPDATE statements that
--               repair each issue in place.
--
-- HOW TO USE
--   1. Run each "AUDIT" query first and read the result.
--   2. If rows are returned, run the matching "FIX" statement.
--   3. Re-run the audit to confirm 0 rows returned.
--
-- Every query below carries:
--   * a comment header explaining its purpose
--   * the query itself
--   * the expected insight / acceptance criteria
-- ================================================================

USE campaign_pulse_db;

-- ================================================================
-- QUERY 1 : NULL VALUES IN CRITICAL COLUMNS
-- Purpose   : Count NULLs per column so no KPI is silently computed
--             from incomplete data.
-- Expected  : 0 NULLs in every column after cleaning. Any column
--             showing a non-zero count must be imputed before the
--             dashboards are trusted.
-- ================================================================
SELECT
    SUM(CASE WHEN campaign_id              IS NULL THEN 1 ELSE 0 END) AS null_campaign_id,
    SUM(CASE WHEN campaign_name            IS NULL THEN 1 ELSE 0 END) AS null_campaign_name,
    SUM(CASE WHEN campaign_type            IS NULL THEN 1 ELSE 0 END) AS null_campaign_type,
    SUM(CASE WHEN channel                  IS NULL THEN 1 ELSE 0 END) AS null_channel,
    SUM(CASE WHEN target_audience          IS NULL THEN 1 ELSE 0 END) AS null_target_audience,
    SUM(CASE WHEN geography                IS NULL THEN 1 ELSE 0 END) AS null_geography,
    SUM(CASE WHEN start_date               IS NULL THEN 1 ELSE 0 END) AS null_start_date,
    SUM(CASE WHEN end_date                 IS NULL THEN 1 ELSE 0 END) AS null_end_date,
    SUM(CASE WHEN budget_allocated         IS NULL THEN 1 ELSE 0 END) AS null_budget_allocated,
    SUM(CASE WHEN amount_spent             IS NULL THEN 1 ELSE 0 END) AS null_amount_spent,
    SUM(CASE WHEN impressions              IS NULL THEN 1 ELSE 0 END) AS null_impressions,
    SUM(CASE WHEN clicks                   IS NULL THEN 1 ELSE 0 END) AS null_clicks,
    SUM(CASE WHEN leads_generated          IS NULL THEN 1 ELSE 0 END) AS null_leads_generated,
    SUM(CASE WHEN conversions              IS NULL THEN 1 ELSE 0 END) AS null_conversions,
    SUM(CASE WHEN revenue_generated        IS NULL THEN 1 ELSE 0 END) AS null_revenue_generated,
    SUM(CASE WHEN roi_percentage           IS NULL THEN 1 ELSE 0 END) AS null_roi_percentage,
    SUM(CASE WHEN satisfaction_score       IS NULL THEN 1 ELSE 0 END) AS null_satisfaction_score,
    SUM(CASE WHEN bounce_rate              IS NULL THEN 1 ELSE 0 END) AS null_bounce_rate,
    SUM(CASE WHEN engagement_rate          IS NULL THEN 1 ELSE 0 END) AS null_engagement_rate
FROM marketing_campaigns;

-- Percentage view of the same audit (columns ordered worst-first)
SELECT 'campaign_name' AS column_name,
       COUNT(*) - COUNT(campaign_name) AS missing_rows,
       ROUND((COUNT(*) - COUNT(campaign_name)) / COUNT(*) * 100, 2) AS missing_pct
FROM marketing_campaigns
UNION ALL
SELECT 'channel', COUNT(*) - COUNT(channel),
       ROUND((COUNT(*) - COUNT(channel)) / COUNT(*) * 100, 2) FROM marketing_campaigns
UNION ALL
SELECT 'revenue_generated', COUNT(*) - COUNT(revenue_generated),
       ROUND((COUNT(*) - COUNT(revenue_generated)) / COUNT(*) * 100, 2) FROM marketing_campaigns
ORDER BY missing_pct DESC;

-- FIX 1 : median imputation for numeric columns.
--         MySQL 8 has no PERCENTILE_CONT(), so the median is taken
--         with ORDER BY ... LIMIT 1 OFFSET <user variable>.
-- SET @n_imp := (SELECT COUNT(*) FROM marketing_campaigns WHERE impressions IS NOT NULL);
-- SET @imp_med := (SELECT impressions FROM marketing_campaigns
--                   WHERE impressions IS NOT NULL
--                   ORDER BY impressions LIMIT 1 OFFSET FLOOR(@n_imp / 2));
-- UPDATE marketing_campaigns SET impressions = @imp_med WHERE impressions IS NULL;

-- FIX 1b : mode imputation for categorical columns
-- UPDATE marketing_campaigns m
-- JOIN (
--     SELECT channel, COUNT(*) AS freq
--     FROM marketing_campaigns
--     WHERE channel IS NOT NULL
--     GROUP BY channel
--     ORDER BY freq DESC
--     LIMIT 1
-- ) c
-- SET m.channel = c.channel
-- WHERE m.channel IS NULL;

-- ================================================================
-- QUERY 2 : DUPLICATE campaign_id VALUES
-- Purpose   : campaign_id is the primary key; duplicates would
--             double-count budget and revenue in every KPI.
-- Expected  : 0 rows returned. In the raw extract 11 identifiers
--             appeared twice and were resolved in Python.
-- ================================================================
SELECT campaign_id,
       COUNT(*)                AS occurrences,
       COUNT(DISTINCT campaign_name) AS distinct_names,
       MIN(start_date)         AS earliest_start,
       MAX(start_date)         AS latest_start
FROM marketing_campaigns
GROUP BY campaign_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- FIX 2 : keep the most complete record per campaign_id
-- DELETE m
-- FROM marketing_campaigns m
-- JOIN (
--     SELECT campaign_id,
--            ROW_NUMBER() OVER (
--                PARTITION BY campaign_id
--                ORDER BY (campaign_name IS NOT NULL) DESC,
--                         (revenue_generated IS NOT NULL) DESC,
--                         start_date
--            ) AS rn
--     FROM marketing_campaigns
-- ) ranked ON m.campaign_id = ranked.campaign_id
-- WHERE ranked.rn > 1;

-- ================================================================
-- QUERY 3 : DUPLICATE FULL RECORDS (all business columns equal)
-- Purpose   : detect exact re-loads of the same campaign.
-- Expected  : 0 rows returned.
-- ================================================================
SELECT campaign_name, campaign_type, channel, start_date, end_date,
       budget_allocated, amount_spent, revenue_generated,
       COUNT(*) AS duplicate_rows
FROM marketing_campaigns
GROUP BY campaign_name, campaign_type, channel, start_date, end_date,
         budget_allocated, amount_spent, revenue_generated
HAVING COUNT(*) > 1;

-- FIX 3 : remove exact duplicates, keeping the lowest campaign_id
-- DELETE m
-- FROM marketing_campaigns m
-- JOIN (
--     SELECT MIN(campaign_id) AS keep_id,
--            campaign_name, campaign_type, channel, start_date, end_date,
--            budget_allocated, amount_spent, revenue_generated
--     FROM marketing_campaigns
--     GROUP BY campaign_name, campaign_type, channel, start_date, end_date,
--              budget_allocated, amount_spent, revenue_generated
--     HAVING COUNT(*) > 1
-- ) d
--   ON m.campaign_name  = d.campaign_name
--  AND m.campaign_type  = d.campaign_type
--  AND m.channel        = d.channel
--  AND m.start_date     = d.start_date
--  AND m.end_date       = d.end_date
--  AND m.budget_allocated = d.budget_allocated
--  AND m.amount_spent   = d.amount_spent
--  AND m.revenue_generated = d.revenue_generated
-- WHERE m.campaign_id <> d.keep_id;

-- ================================================================
-- QUERY 4 : DATE RANGE SANITY (end_date must be >= start_date)
-- Purpose   : impossible date pairs break duration and every
--             time-series aggregation.
-- Expected  : 0 rows returned. The raw extract contained 25 such
--             records; they were repaired with the median duration.
-- ================================================================
SELECT campaign_id, campaign_name, start_date, end_date,
       DATEDIFF(end_date, start_date) AS duration_days
FROM marketing_campaigns
WHERE end_date < start_date
   OR start_date IS NULL
   OR end_date IS NULL;

-- FIX 4 : rebuild the end date using the median valid duration.
--         MySQL 8 allows a user variable in LIMIT ... OFFSET.
-- SET @n_days := (SELECT COUNT(*) FROM marketing_campaigns WHERE end_date >= start_date);
-- SET @median_days := (SELECT DATEDIFF(end_date, start_date) FROM marketing_campaigns
--                       WHERE end_date >= start_date
--                       ORDER BY DATEDIFF(end_date, start_date)
--                       LIMIT 1 OFFSET FLOOR(@n_days / 2));
-- UPDATE marketing_campaigns
-- SET end_date = DATE_ADD(start_date, INTERVAL @median_days DAY)
-- WHERE end_date < start_date;

-- ================================================================
-- QUERY 5 : NEGATIVE / IMPOSSIBLE VALUES IN MEASURES
-- Purpose   : budget, spend, revenue and funnel counts can never
--             be negative.
-- Expected  : 0 rows returned. The raw extract contained 66
--             impossible negatives.
-- ================================================================
SELECT
    SUM(CASE WHEN budget_allocated < 0 THEN 1 ELSE 0 END) AS neg_budget,
    SUM(CASE WHEN amount_spent     < 0 THEN 1 ELSE 0 END) AS neg_spend,
    SUM(CASE WHEN impressions      < 0 THEN 1 ELSE 0 END) AS neg_impressions,
    SUM(CASE WHEN clicks           < 0 THEN 1 ELSE 0 END) AS neg_clicks,
    SUM(CASE WHEN leads_generated  < 0 THEN 1 ELSE 0 END) AS neg_leads,
    SUM(CASE WHEN conversions      < 0 THEN 1 ELSE 0 END) AS neg_conversions,
    SUM(CASE WHEN revenue_generated < 0 THEN 1 ELSE 0 END) AS neg_revenue
FROM marketing_campaigns;

-- Detail listing of offending records
SELECT campaign_id, budget_allocated, amount_spent, impressions,
       clicks, leads_generated, conversions, revenue_generated
FROM marketing_campaigns
WHERE budget_allocated < 0 OR amount_spent < 0 OR impressions < 0
   OR clicks < 0 OR leads_generated < 0 OR conversions < 0
   OR revenue_generated < 0;

-- FIX 5 : neutralise negatives to NULL, then impute (see FIX 1)
-- UPDATE marketing_campaigns SET revenue_generated = NULL WHERE revenue_generated < 0;
-- UPDATE marketing_campaigns SET impressions      = NULL WHERE impressions      < 0;
-- UPDATE marketing_campaigns SET clicks           = NULL WHERE clicks           < 0;

-- ================================================================
-- QUERY 6 : VALIDATE THE ROI CALCULATION
-- Purpose   : roi_percentage must equal
--             ((revenue - spend) / spend) * 100.
--             ~3% of raw rows used budget_allocated instead of
--             amount_spent.
-- Expected  : 0 rows with a difference greater than 0.5pp.
-- ================================================================
SELECT campaign_id,
       amount_spent,
       revenue_generated,
       roi_percentage                                          AS stored_roi,
       ROUND((revenue_generated - amount_spent) / amount_spent * 100, 2) AS recalculated_roi,
       ROUND(roi_percentage -
             (revenue_generated - amount_spent) / amount_spent * 100, 2) AS difference
FROM marketing_campaigns
WHERE amount_spent > 0
  AND ABS(roi_percentage - (revenue_generated - amount_spent) / amount_spent * 100) > 0.5
ORDER BY ABS(difference) DESC;

-- FIX 6 : recompute ROI everywhere from the base metrics
-- UPDATE marketing_campaigns
-- SET roi_percentage = ROUND((revenue_generated - amount_spent) / amount_spent * 100, 2)
-- WHERE amount_spent > 0;

-- ================================================================
-- QUERY 7 : CAMPAIGN STATUS DISTRIBUTION
-- Purpose   : confirm the controlled vocabulary is complete and
--             standardised (no lower-case / padded variants).
-- Expected  : exactly 4 statuses: Completed, Active, Paused,
--             Cancelled - and no spelling variants.
-- ================================================================
SELECT campaign_status,
       COUNT(*)                                            AS campaigns,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM marketing_campaigns) * 100, 2) AS pct_of_total,
       ROUND(AVG(roi_percentage), 2)                       AS avg_roi,
       ROUND(AVG(budget_utilization), 2)                   AS avg_budget_utilization,
       ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM marketing_campaigns
GROUP BY campaign_status
ORDER BY campaigns DESC;

-- FIX 7 : standardise status labels
-- UPDATE marketing_campaigns
-- SET campaign_status = CONCAT(UPPER(LEFT(TRIM(campaign_status), 1)),
--                              LOWER(SUBSTRING(TRIM(campaign_status), 2)))
-- WHERE campaign_status <> TRIM(campaign_status)
--    OR BINARY campaign_status <> CONCAT(UPPER(LEFT(TRIM(campaign_status), 1)),
--                                        LOWER(SUBSTRING(TRIM(campaign_status), 2)));

-- ================================================================
-- QUERY 8 : CATEGORICAL VOCABULARY STANDARDISATION
-- Purpose   : every dimension must contain only the expected set of
--             values. Unexpected values indicate casing/whitespace
--             drift that fragments GROUP BY results.
-- Expected  : every dimension returns exactly its reference count
--             (campaign_type 5, channel 10, geography 6,
--              target_audience 6, campaign_status 4).
-- ================================================================
SELECT 'campaign_type'  AS dimension, COUNT(DISTINCT campaign_type)  AS distinct_values FROM marketing_campaigns
UNION ALL SELECT 'channel',         COUNT(DISTINCT channel)                FROM marketing_campaigns
UNION ALL SELECT 'geography',       COUNT(DISTINCT geography)              FROM marketing_campaigns
UNION ALL SELECT 'target_audience', COUNT(DISTINCT target_audience)       FROM marketing_campaigns
UNION ALL SELECT 'campaign_status', COUNT(DISTINCT campaign_status)       FROM marketing_campaigns
UNION ALL SELECT 'roi_category',    COUNT(DISTINCT roi_category)          FROM marketing_campaigns
UNION ALL SELECT 'budget_tier',     COUNT(DISTINCT budget_tier)           FROM marketing_campaigns;

-- Detail: values that differ from the reference vocabulary
SELECT channel, COUNT(*) AS rows_affected
FROM marketing_campaigns
WHERE TRIM(channel) <> channel
   OR channel NOT IN ('Email','Social Media','Google Ads','Facebook Ads',
                      'Instagram Ads','YouTube','SEO','Content Marketing',
                      'Influencer','Affiliate')
GROUP BY channel;

-- FIX 8 : trim and re-case every dimension
-- UPDATE marketing_campaigns SET channel        = TRIM(channel);
-- UPDATE marketing_campaigns SET campaign_type  = TRIM(campaign_type);
-- UPDATE marketing_campaigns SET geography      = TRIM(geography);
-- UPDATE marketing_campaigns SET target_audience= TRIM(target_audience);
-- UPDATE marketing_campaigns SET campaign_status= TRIM(campaign_status);

-- ================================================================
-- QUERY 9 : OUTLIER DETECTION (IQR METHOD)
-- Purpose   : identify records beyond 1.5 x IQR so they can be
--             winsorised rather than deleted.
-- Expected  : the extreme tail is small (< 2% of rows per metric);
--             the raw extract contained 6,974 outlier observations.
-- Note      : MySQL 8 has no PERCENTILE_CONT(), so quartiles are
--             derived with ROW_NUMBER() against the row count.
-- ================================================================
WITH ranked AS (
    SELECT revenue_generated, amount_spent, impressions,
           ROW_NUMBER() OVER (ORDER BY revenue_generated) AS rn_rev,
           ROW_NUMBER() OVER (ORDER BY amount_spent)     AS rn_spend,
           ROW_NUMBER() OVER (ORDER BY impressions)      AS rn_imp,
           COUNT(*) OVER ()                              AS n
    FROM marketing_campaigns
),
quartiles AS (
    SELECT
        MAX(CASE WHEN rn_rev  = FLOOR(n * 0.25) + 1 THEN revenue_generated END) AS rev_q1,
        MAX(CASE WHEN rn_rev  = FLOOR(n * 0.75) + 1 THEN revenue_generated END) AS rev_q3,
        MAX(CASE WHEN rn_spend = FLOOR(n * 0.25) + 1 THEN amount_spent END)     AS spend_q1,
        MAX(CASE WHEN rn_spend = FLOOR(n * 0.75) + 1 THEN amount_spent END)     AS spend_q3,
        MAX(CASE WHEN rn_imp   = FLOOR(n * 0.25) + 1 THEN impressions END)      AS imp_q1,
        MAX(CASE WHEN rn_imp   = FLOOR(n * 0.75) + 1 THEN impressions END)      AS imp_q3
    FROM ranked
)
SELECT 'revenue_generated' AS metric,
       rev_q1  AS q1,
       rev_q3  AS q3,
       rev_q3 - rev_q1 AS iqr,
       rev_q3 + 1.5 * (rev_q3 - rev_q1) AS upper_fence,
       (SELECT COUNT(*) FROM marketing_campaigns
         WHERE revenue_generated > (SELECT rev_q3 + 1.5 * (rev_q3 - rev_q1) FROM quartiles)) AS outliers_above
FROM quartiles
UNION ALL
SELECT 'amount_spent', spend_q1, spend_q3, spend_q3 - spend_q1,
       spend_q3 + 1.5 * (spend_q3 - spend_q1),
       (SELECT COUNT(*) FROM marketing_campaigns
         WHERE amount_spent > (SELECT spend_q3 + 1.5 * (spend_q3 - spend_q1) FROM quartiles))
FROM quartiles
UNION ALL
SELECT 'impressions', imp_q1, imp_q3, imp_q3 - imp_q1,
       imp_q3 + 1.5 * (imp_q3 - imp_q1),
       (SELECT COUNT(*) FROM marketing_campaigns
         WHERE impressions > (SELECT imp_q3 + 1.5 * (imp_q3 - imp_q1) FROM quartiles))
FROM quartiles;

-- FIX 9 : winsorise revenue_generated at the 1st / 99th percentile.
--         MySQL 8 allows a user variable in LIMIT ... OFFSET.
-- SET @n_rev  := (SELECT COUNT(*) FROM marketing_campaigns);
-- SET @rev_lo := (SELECT revenue_generated FROM marketing_campaigns
--                  ORDER BY revenue_generated LIMIT 1 OFFSET FLOOR(@n_rev * 0.01));
-- SET @rev_hi := (SELECT revenue_generated FROM marketing_campaigns
--                  ORDER BY revenue_generated LIMIT 1 OFFSET FLOOR(@n_rev * 0.99));
-- UPDATE marketing_campaigns
-- SET revenue_generated = LEAST(GREATEST(revenue_generated, @rev_lo), @rev_hi);

-- ================================================================
-- QUERY 10 : ORPHAN RECORDS & INTERNAL INCONSISTENCIES
-- Purpose   : detect logical contradictions that a schema cannot
--             express: spend above budget, funnel inversion,
--             zero denominators, dates outside the study window.
-- Expected  : 0 rows returned after cleaning.
-- ================================================================
SELECT campaign_id,
       budget_allocated, amount_spent,
       impressions, clicks, leads_generated, conversions,
       start_date, end_date
FROM marketing_campaigns
WHERE amount_spent > budget_allocated * 1.10      -- spend >10% over plan
   OR conversions > leads_generated                -- funnel inversion
   OR leads_generated > clicks                     -- funnel inversion
   OR clicks > impressions                         -- funnel inversion
   OR impressions = 0 OR clicks = 0
   OR start_date < '2022-01-01' OR start_date > '2024-12-31'
   OR bounce_rate < 0 OR bounce_rate > 100
   OR engagement_rate < 0 OR engagement_rate > 100
   OR satisfaction_score < 1 OR satisfaction_score > 5;

-- ================================================================
-- QUERY 11 : DATA QUALITY SUMMARY REPORT
-- Purpose   : one row per quality dimension with a pass/fail flag,
--             suitable for a data-governance dashboard.
-- Expected  : every score at 100%.
-- ================================================================
SELECT 'Completeness' AS quality_dimension,
       ROUND((1 - (
           (COUNT(*) - COUNT(campaign_id)) + (COUNT(*) - COUNT(channel)) +
           (COUNT(*) - COUNT(revenue_generated)) + (COUNT(*) - COUNT(amount_spent))
       ) / (COUNT(*) * 4.0)) * 100, 2) AS score_pct,
       CASE WHEN (COUNT(*) - COUNT(campaign_id)) + (COUNT(*) - COUNT(channel)) +
                 (COUNT(*) - COUNT(revenue_generated)) + (COUNT(*) - COUNT(amount_spent)) = 0
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM marketing_campaigns
UNION ALL
SELECT 'Uniqueness',
       ROUND((1 - (COUNT(*) - COUNT(DISTINCT campaign_id)) / COUNT(*)) * 100, 2),
       CASE WHEN COUNT(*) = COUNT(DISTINCT campaign_id) THEN 'PASS' ELSE 'FAIL' END
FROM marketing_campaigns
UNION ALL
SELECT 'Validity',
       ROUND((SUM(CASE WHEN budget_allocated >= 0 AND amount_spent >= 0
                        AND revenue_generated >= 0 AND impressions >= 0
                        AND satisfaction_score BETWEEN 1 AND 5 THEN 1 ELSE 0 END)
             / COUNT(*)) * 100, 2),
       CASE WHEN SUM(CASE WHEN budget_allocated < 0 OR amount_spent < 0
                           OR revenue_generated < 0 OR impressions < 0
                           OR satisfaction_score NOT BETWEEN 1 AND 5
                          THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM marketing_campaigns
UNION ALL
SELECT 'Consistency',
       ROUND((SUM(CASE WHEN end_date >= start_date
                        AND conversions <= leads_generated
                        AND leads_generated <= clicks
                        AND clicks <= impressions THEN 1 ELSE 0 END)
             / COUNT(*)) * 100, 2),
       CASE WHEN SUM(CASE WHEN end_date < start_date
                           OR conversions > leads_generated
                           OR leads_generated > clicks
                           OR clicks > impressions THEN 1 ELSE 0 END) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM marketing_campaigns
UNION ALL
SELECT 'Timeliness',
       ROUND((SUM(CASE WHEN start_date BETWEEN '2022-01-01' AND '2024-12-31'
                        THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2),
       CASE WHEN SUM(CASE WHEN start_date NOT BETWEEN '2022-01-01' AND '2024-12-31'
                          THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM marketing_campaigns;

-- ================================================================
-- QUERY 12 : FINAL VALIDATION AFTER CLEANING
-- Purpose   : single acceptance query - every column of the result
--             must read 0 / PASS before the dataset is released to
--             the dashboards.
-- ================================================================
SELECT
    (SELECT COUNT(*) FROM marketing_campaigns)                                  AS total_rows,
    (SELECT COUNT(*) FROM (SELECT campaign_id FROM marketing_campaigns
                           GROUP BY campaign_id HAVING COUNT(*) > 1) d)         AS duplicate_ids,
    (SELECT COUNT(*) FROM marketing_campaigns WHERE campaign_id IS NULL)        AS null_ids,
    (SELECT COUNT(*) FROM marketing_campaigns WHERE revenue_generated IS NULL)  AS null_revenue,
    (SELECT COUNT(*) FROM marketing_campaigns WHERE end_date < start_date)      AS bad_dates,
    (SELECT COUNT(*) FROM marketing_campaigns WHERE amount_spent < 0)           AS negative_spend,
    (SELECT COUNT(*) FROM marketing_campaigns WHERE conversions > leads_generated) AS funnel_errors,
    (SELECT COUNT(*) FROM marketing_campaigns
      WHERE ABS(roi_percentage -
                (revenue_generated - amount_spent) / amount_spent * 100) > 0.5) AS roi_mismatches,
    CASE WHEN (SELECT COUNT(*) FROM marketing_campaigns) > 0
          AND (SELECT COUNT(*) FROM marketing_campaigns WHERE campaign_id IS NULL) = 0
          AND (SELECT COUNT(*) FROM marketing_campaigns WHERE end_date < start_date) = 0
         THEN 'CLEAN - RELEASE TO DASHBOARDS'
         ELSE 'DIRTY - DO NOT RELEASE' END                                      AS release_status;

-- ================================================================
-- END OF 02_data_cleaning.sql
-- Next step: run 03_business_queries.sql
-- ================================================================
