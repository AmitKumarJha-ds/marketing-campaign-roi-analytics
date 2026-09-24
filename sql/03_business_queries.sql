-- ================================================================
-- CampaignPulse - Marketing Campaign ROI Analytics
-- SQL FILE 03 : Business Analysis Queries
-- Target      : MySQL 8.0+  (CTEs, window functions, ROLLUP)
-- Purpose     : 30 production-grade analytical queries answering the
--               business questions in docs/business_problems.md.
--
-- ORGANISATION
--   CATEGORY 1 : Campaign Performance Analysis        (Q1-Q5)
--   CATEGORY 2 : Channel Analysis                     (Q6-Q10)
--   CATEGORY 3 : Budget & Financial Analysis          (Q11-Q15)
--   CATEGORY 4 : Geographic Analysis                  (Q16-Q18)
--   CATEGORY 5 : Audience Analysis                    (Q19-Q21)
--   CATEGORY 6 : Time-Based Analysis                  (Q22-Q25)
--   BONUS      : Advanced analytics                   (Q26-Q30)
--
-- Each query carries a comment header stating the business question,
-- the SQL, and the expected insight.
-- ================================================================

USE campaign_pulse_db;

-- ================================================================
-- CATEGORY 1 : CAMPAIGN PERFORMANCE ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q1. What is the overall average ROI across all campaigns?
-- Expected insight: blended (weighted) ROI is ~96%, but the simple
-- average of campaign-level ROI is ~100% and the MEDIAN is only
-- ~11.5% - the distribution is heavily right-skewed, so the mean
-- overstates typical performance.
-- Note: the median is derived with ROW_NUMBER()/COUNT() OVER ()
-- because MySQL 8 has no PERCENTILE_CONT() function.
-- ----------------------------------------------------------------
WITH ranked AS (
    SELECT roi_percentage,
           ROW_NUMBER() OVER (ORDER BY roi_percentage) AS rn,
           COUNT(*)     OVER ()                        AS n
    FROM marketing_campaigns
)
SELECT
    (SELECT COUNT(*) FROM marketing_campaigns)                          AS total_campaigns,
    ROUND(AVG(roi_percentage), 2)                                       AS avg_roi,
    ROUND(
        (SUM(revenue_generated) / SUM(amount_spent) - 1) * 100, 2)      AS blended_roi,
    ROUND((SELECT roi_percentage FROM ranked
           WHERE rn = FLOOR(n / 2) + 1), 2)                             AS median_roi,
    ROUND(MIN(roi_percentage), 2)                                       AS worst_roi,
    ROUND(MAX(roi_percentage), 2)                                       AS best_roi,
    ROUND(STDDEV(roi_percentage), 2)                                    AS roi_volatility,
    ROUND(SUM(revenue_generated), 2)                                    AS total_revenue,
    ROUND(SUM(amount_spent), 2)                                         AS total_spend,
    ROUND(SUM(profit), 2)                                               AS total_profit
FROM marketing_campaigns;

-- ----------------------------------------------------------------
-- Q2. Which campaign type delivers the highest average ROI?
-- Expected insight: Retention (203.9%) leads, followed by Conversion
-- (156.5%) and Lead Generation (145.3%). Brand Awareness is the only
-- value-destroying type at -50.8%.
-- ----------------------------------------------------------------
SELECT
    campaign_type,
    COUNT(*)                                              AS campaigns,
    ROUND(AVG(roi_percentage), 2)                         AS avg_roi,
    ROUND(AVG(revenue_generated), 2)                      AS avg_revenue,
    ROUND(SUM(revenue_generated), 2)                      AS total_revenue,
    ROUND(SUM(profit), 2)                                 AS total_profit,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable,
    RANK() OVER (ORDER BY AVG(roi_percentage) DESC)       AS roi_rank
FROM marketing_campaigns
GROUP BY campaign_type
ORDER BY avg_roi DESC;

-- ----------------------------------------------------------------
-- Q3. Top 10 best performing campaigns by revenue generated
-- Expected insight: revenue leaders are large-budget Conversion and
-- Retention campaigns; revenue leadership and ROI leadership are NOT
-- the same list.
-- ----------------------------------------------------------------
SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    channel,
    geography,
    target_audience,
    ROUND(budget_allocated, 2)   AS budget_allocated,
    ROUND(revenue_generated, 2)  AS revenue_generated,
    ROUND(profit, 2)             AS profit,
    ROUND(roi_percentage, 2)     AS roi_percentage,
    ROUND(performance_score, 2)  AS performance_score
FROM marketing_campaigns
ORDER BY revenue_generated DESC
LIMIT 10;

-- ----------------------------------------------------------------
-- Q4. Bottom 10 worst performing campaigns by ROI
-- Expected insight: the worst performers are almost all Brand
-- Awareness and Re-engagement campaigns that spent budget without
-- generating attributable revenue (ROI close to -99%).
-- ----------------------------------------------------------------
SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    channel,
    ROUND(budget_allocated, 2)  AS budget_allocated,
    ROUND(amount_spent, 2)      AS amount_spent,
    ROUND(revenue_generated, 2) AS revenue_generated,
    ROUND(profit, 2)            AS profit,
    ROUND(roi_percentage, 2)    AS roi_percentage,
    ROUND(customer_acquisition_cost, 2) AS cac
FROM marketing_campaigns
ORDER BY roi_percentage ASC
LIMIT 10;

-- ----------------------------------------------------------------
-- Q5. Campaign performance breakdown by status
-- Expected insight: Cancelled campaigns average -48% ROI with only
-- 23% budget utilisation and 13% profitability - the clearest
-- "stop the bleed" cohort. Paused campaigns (24% ROI) are the second.
-- ----------------------------------------------------------------
SELECT
    campaign_status,
    COUNT(*)                                              AS campaigns,
    ROUND(AVG(roi_percentage), 2)                         AS avg_roi,
    ROUND(AVG(revenue_generated), 2)                      AS avg_revenue,
    ROUND(AVG(budget_utilization), 2)                     AS avg_budget_utilization,
    ROUND(AVG(campaign_duration_days), 1)                 AS avg_duration_days,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable,
    ROUND(SUM(profit), 2)                                 AS total_profit
FROM marketing_campaigns
GROUP BY campaign_status
ORDER BY avg_roi DESC;

-- ================================================================
-- CATEGORY 2 : CHANNEL ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q6. Which marketing channel has the highest ROI?
-- Expected insight: SEO (191.7%) > Email (185.8%) > Affiliate
-- (185.4%); Instagram Ads (23.1%) and Social Media (24.1%) are last.
-- ----------------------------------------------------------------
SELECT
    channel,
    COUNT(*)                                              AS campaigns,
    ROUND(AVG(roi_percentage), 2)                         AS avg_roi,
    ROUND(SUM(revenue_generated), 2)                      AS total_revenue,
    ROUND(SUM(profit), 2)                                 AS total_profit,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable,
    RANK() OVER (ORDER BY AVG(roi_percentage) DESC)       AS roi_rank
FROM marketing_campaigns
GROUP BY channel
ORDER BY avg_roi DESC;

-- ----------------------------------------------------------------
-- Q7. Channel-wise average CPC, CPA and CAC comparison
-- Expected insight: CPC and CAC rank differently - YouTube has the
-- cheapest clicks (~$0.6) but a high CAC because its traffic converts
-- poorly. CAC, not CPC, must drive budget decisions.
-- ----------------------------------------------------------------
SELECT
    channel,
    ROUND(AVG(cpc), 3)                                     AS avg_cpc,
    ROUND(AVG(cpa), 2)                                    AS avg_cpa,
    ROUND(AVG(customer_acquisition_cost), 2)              AS avg_cac,
    ROUND(AVG(ctr), 4)                                    AS avg_ctr,
    ROUND(AVG(conversion_rate), 4)                        AS avg_conversion_rate,
    ROUND(AVG(customer_acquisition_cost) - AVG(cpa), 2)   AS cac_overhead,
    RANK() OVER (ORDER BY AVG(customer_acquisition_cost))  AS cac_rank
FROM marketing_campaigns
GROUP BY channel
ORDER BY avg_cac ASC;

-- ----------------------------------------------------------------
-- Q8. Which channel generates the most revenue per dollar spent?
-- Expected insight: cost_efficiency_ratio (revenue / spend) ranks the
-- same channels on top - SEO ~2.8x, Email ~2.7x, Affiliate ~2.6x
-- revenue per dollar, versus ~1.2x for Instagram Ads.
-- ----------------------------------------------------------------
SELECT
    channel,
    ROUND(AVG(cost_efficiency_ratio), 3)                  AS avg_revenue_per_dollar,
    ROUND(SUM(revenue_generated) / NULLIF(SUM(amount_spent), 0), 3) AS portfolio_revenue_per_dollar,
    ROUND(AVG(revenue_per_click), 2)                      AS avg_revenue_per_click,
    ROUND(AVG(revenue_per_impression), 5)                 AS avg_revenue_per_impression,
    ROUND(AVG(amount_spent), 2)                           AS avg_spend,
    RANK() OVER (ORDER BY AVG(cost_efficiency_ratio) DESC) AS efficiency_rank
FROM marketing_campaigns
GROUP BY channel
ORDER BY avg_revenue_per_dollar DESC;

-- ----------------------------------------------------------------
-- Q9. Channel performance trend over quarters / years
-- Expected insight: owned and earned channels (SEO, Email, Affiliate)
-- hold their ROI in every quarter; paid social deteriorates after Q2.
-- ----------------------------------------------------------------
WITH channel_quarter AS (
    SELECT
        channel,
        year,
        campaign_quarter,
        COUNT(*)                                        AS campaigns,
        ROUND(AVG(roi_percentage), 2)                   AS avg_roi,
        ROUND(SUM(revenue_generated), 2)                AS revenue
    FROM marketing_campaigns
    GROUP BY channel, year, campaign_quarter
)
SELECT
    channel,
    year,
    campaign_quarter,
    campaigns,
    avg_roi,
    revenue,
    ROUND(AVG(avg_roi) OVER (PARTITION BY channel), 2)                    AS channel_avg_roi,
    ROUND(avg_roi - AVG(avg_roi) OVER (PARTITION BY channel), 2)          AS variance_vs_channel_avg,
    ROUND(avg_roi - LAG(avg_roi) OVER (PARTITION BY channel ORDER BY year, campaign_quarter), 2) AS qoq_change
FROM channel_quarter
ORDER BY channel, year, campaign_quarter;

-- ----------------------------------------------------------------
-- Q10. Channel conversion funnel: impressions -> clicks -> leads -> conversions
-- Expected insight: the funnel is widest (highest lead and conversion
-- rates) on SEO, Email and Affiliate; Instagram and YouTube leak at
-- every stage.
-- ----------------------------------------------------------------
SELECT
    channel,
    SUM(impressions)                                                AS total_impressions,
    SUM(clicks)                                                     AS total_clicks,
    SUM(leads_generated)                                            AS total_leads,
    SUM(conversions)                                                AS total_conversions,
    ROUND(SUM(clicks)        / NULLIF(SUM(impressions), 0) * 100, 3) AS ctr_pct,
    ROUND(SUM(leads_generated) / NULLIF(SUM(clicks), 0) * 100, 3)   AS click_to_lead_pct,
    ROUND(SUM(conversions)   / NULLIF(SUM(leads_generated), 0) * 100, 3) AS lead_to_conversion_pct,
    ROUND(SUM(conversions)   / NULLIF(SUM(impressions), 0) * 100, 4) AS impression_to_conversion_pct
FROM marketing_campaigns
GROUP BY channel
ORDER BY lead_to_conversion_pct DESC;

-- ================================================================
-- CATEGORY 3 : BUDGET & FINANCIAL ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q11. Total budget vs spend vs revenue (overall and by year)
-- Expected insight: the portfolio spent $198.4M to generate $388.9M
-- (96% blended ROI). Revenue is flat across 2022-2024 while spend
-- falls, so the efficiency gain is a spend cut, not a productivity win.
-- Note: written with UNION ALL instead of GROUP BY ... WITH ROLLUP so
-- the same statement also runs on engines without ROLLUP support.
-- ----------------------------------------------------------------
SELECT 'ALL YEARS'                                          AS period,
       COUNT(*)                                             AS campaigns,
       ROUND(SUM(budget_allocated), 2)                      AS total_budget,
       ROUND(SUM(amount_spent), 2)                          AS total_spend,
       ROUND(SUM(revenue_generated), 2)                     AS total_revenue,
       ROUND(SUM(profit), 2)                                AS total_profit,
       ROUND(SUM(amount_spent) / NULLIF(SUM(budget_allocated), 0) * 100, 2) AS budget_utilization_pct,
       ROUND((SUM(revenue_generated) / NULLIF(SUM(amount_spent), 0) - 1) * 100, 2) AS blended_roi
FROM marketing_campaigns
UNION ALL
SELECT CAST(year AS CHAR),
       COUNT(*),
       ROUND(SUM(budget_allocated), 2),
       ROUND(SUM(amount_spent), 2),
       ROUND(SUM(revenue_generated), 2),
       ROUND(SUM(profit), 2),
       ROUND(SUM(amount_spent) / NULLIF(SUM(budget_allocated), 0) * 100, 2),
       ROUND((SUM(revenue_generated) / NULLIF(SUM(amount_spent), 0) - 1) * 100, 2)
FROM marketing_campaigns
GROUP BY year
ORDER BY period;

-- ----------------------------------------------------------------
-- Q12. Budget utilization rate by campaign type
-- Expected insight: budget utilisation is essentially uniform across all
-- five types (~81% of plan), so there is no evidence of differential spend
-- discipline - the differences between types are in the returns, not in the
-- spend. Retention and Conversion convert that spend far more effectively.
-- ----------------------------------------------------------------
SELECT
    campaign_type,
    COUNT(*)                                                       AS campaigns,
    ROUND(AVG(budget_allocated), 2)                                AS avg_budget,
    ROUND(AVG(amount_spent), 2)                                    AS avg_spend,
    ROUND(AVG(budget_utilization), 2)                              AS avg_budget_utilization_pct,
    ROUND(SUM(amount_spent) / NULLIF(SUM(budget_allocated), 0) * 100, 2) AS portfolio_utilization_pct,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi
FROM marketing_campaigns
GROUP BY campaign_type
ORDER BY avg_budget_utilization_pct DESC;

-- ----------------------------------------------------------------
-- Q13. Which budget tier has the best ROI?
-- Expected insight: Micro (<5K) campaigns return the highest average
-- ROI (115.9%) and Small (5K-25K) 104.2%, while Large (100K-250K)
-- falls to 66.8% - clear diminishing returns to scale.
-- ----------------------------------------------------------------
SELECT
    budget_tier,
    COUNT(*)                                                       AS campaigns,
    ROUND(AVG(budget_allocated), 2)                                AS avg_budget,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi,
    ROUND(AVG(revenue_generated), 2)                               AS avg_revenue,
    ROUND(SUM(revenue_generated), 2)                               AS total_revenue,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable,
    RANK() OVER (ORDER BY AVG(roi_percentage) DESC)                AS roi_rank
FROM marketing_campaigns
GROUP BY budget_tier
ORDER BY avg_roi DESC;

-- ----------------------------------------------------------------
-- Q14. Cost efficiency analysis: revenue per dollar by channel AND type
-- Expected insight: the single best combination is Retention x SEO /
-- Email / Affiliate; the worst is Brand Awareness x Instagram Ads.
-- Email/Affiliate/SEO return $144/$161/$198 per customer.
-- ----------------------------------------------------------------
WITH efficiency AS (
    SELECT
        channel,
        campaign_type,
        COUNT(*)                                                     AS campaigns,
        ROUND(AVG(cost_efficiency_ratio), 3)                         AS revenue_per_dollar,
        ROUND(AVG(roi_percentage), 2)                                AS avg_roi,
        ROUND(AVG(customer_acquisition_cost), 2)                     AS avg_cac,
        ROUND(SUM(profit), 2)                                        AS total_profit
    FROM marketing_campaigns
    GROUP BY channel, campaign_type
    HAVING COUNT(*) >= 30
)
SELECT *,
       RANK() OVER (ORDER BY revenue_per_dollar DESC) AS efficiency_rank
FROM efficiency
ORDER BY revenue_per_dollar DESC
LIMIT 15;

-- ----------------------------------------------------------------
-- Q15. Month-over-month revenue growth rate
-- Expected insight: MoM growth oscillates around 0% with strong Q4
-- spikes; the 12-month rolling average is flat, confirming no
-- underlying growth.
-- ----------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01')  AS month,
        SUM(revenue_generated)               AS revenue,
        SUM(amount_spent)                    AS spend,
        COUNT(*)                             AS campaigns
    FROM marketing_campaigns
    GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
)
SELECT
    month,
    ROUND(revenue, 2)                                                AS revenue,
    ROUND(spend, 2)                                                  AS spend,
    campaigns,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
          / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2)   AS mom_growth_pct,
    ROUND(AVG(revenue) OVER (ORDER BY month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)              AS rolling_3m_revenue,
    ROUND(AVG(revenue) OVER (ORDER BY month
          ROWS BETWEEN 11 PRECEDING AND CURRENT ROW), 2)             AS rolling_12m_revenue
FROM monthly
ORDER BY month;

-- ================================================================
-- CATEGORY 4 : GEOGRAPHIC ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q16. ROI and revenue by geography
-- Expected insight: North America (121.6%) and Europe (111.7%)
-- generate $232M of the $389M total; Africa (51.8%) is weakest.
-- ----------------------------------------------------------------
SELECT
    geography,
    COUNT(*)                                                       AS campaigns,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi,
    ROUND(SUM(revenue_generated), 2)                               AS total_revenue,
    ROUND(SUM(revenue_generated) / (SELECT SUM(revenue_generated)
         FROM marketing_campaigns) * 100, 2)                       AS pct_of_total_revenue,
    ROUND(AVG(customer_acquisition_cost), 2)                       AS avg_cac,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM marketing_campaigns
GROUP BY geography
ORDER BY total_revenue DESC;

-- ----------------------------------------------------------------
-- Q17. Best performing channel in each geography
-- Expected insight: SEO and Email win in North America and Europe,
-- while Affiliate and Content Marketing lead in the emerging regions.
-- ----------------------------------------------------------------
WITH geo_channel AS (
    SELECT
        geography,
        channel,
        COUNT(*)                                       AS campaigns,
        ROUND(AVG(roi_percentage), 2)                  AS avg_roi,
        ROUND(SUM(revenue_generated), 2)               AS revenue,
        RANK() OVER (PARTITION BY geography ORDER BY AVG(roi_percentage) DESC) AS rank_in_geo
    FROM marketing_campaigns
    GROUP BY geography, channel
)
SELECT geography, channel, campaigns, avg_roi, revenue, rank_in_geo
FROM geo_channel
WHERE rank_in_geo <= 3
ORDER BY geography, rank_in_geo;

-- ----------------------------------------------------------------
-- Q18. Geographic campaign volume and success rate
-- Expected insight: volume is concentrated in North America (30% of
-- campaigns) and its success rate is the highest (57%) - a
-- self-reinforcing allocation that should be tested against Africa
-- and the Middle East with smaller, experimental budgets.
-- ----------------------------------------------------------------
SELECT
    geography,
    COUNT(*)                                                       AS campaigns,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM marketing_campaigns) * 100, 2) AS pct_of_campaigns,
    SUM(CASE WHEN is_profitable THEN 1 ELSE 0 END)                 AS profitable_campaigns,
    SUM(CASE WHEN NOT is_profitable THEN 1 ELSE 0 END)             AS loss_making_campaigns,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS success_rate_pct,
    ROUND(AVG(budget_allocated), 2)                                AS avg_budget,
    ROUND(SUM(profit), 2)                                          AS total_profit
FROM marketing_campaigns
GROUP BY geography
ORDER BY campaigns DESC;

-- ================================================================
-- CATEGORY 5 : AUDIENCE ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q19. ROI by target audience segment
-- Expected insight: Mid-Age 35-50 (167.5%) and Professionals 25-35
-- (152.5%) lead; Students (7.5%) and Young Adults (38.9%) trail.
-- Mid-Age and Professionals also carry the lowest CAC ($218 / $226).
-- ----------------------------------------------------------------
SELECT
    target_audience,
    COUNT(*)                                                       AS campaigns,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi,
    ROUND(AVG(ctr), 4)                                             AS avg_ctr,
    ROUND(AVG(conversion_rate), 4)                                 AS avg_conversion_rate,
    ROUND(AVG(engagement_rate), 2)                                 AS avg_engagement_rate,
    ROUND(AVG(customer_acquisition_cost), 2)                       AS avg_cac,
    ROUND(AVG(revenue_generated), 2)                               AS avg_revenue
FROM marketing_campaigns
GROUP BY target_audience
ORDER BY avg_roi DESC;

-- ----------------------------------------------------------------
-- Q20. Which audience responds best to which channel?
-- Expected insight: Mid-Age 35-50 responds best to SEO and
-- Affiliate; Students respond worst to YouTube and Instagram Ads.
-- ----------------------------------------------------------------
WITH audience_channel AS (
    SELECT
        target_audience,
        channel,
        COUNT(*)                                       AS campaigns,
        ROUND(AVG(roi_percentage), 2)                  AS avg_roi,
        RANK() OVER (PARTITION BY target_audience
                     ORDER BY AVG(roi_percentage) DESC) AS rank_in_audience
    FROM marketing_campaigns
    GROUP BY target_audience, channel
)
SELECT target_audience, channel, campaigns, avg_roi, rank_in_audience
FROM audience_channel
WHERE rank_in_audience <= 3
ORDER BY target_audience, rank_in_audience;

-- ----------------------------------------------------------------
-- Q21. Audience segment profitability analysis
-- Expected insight: Mid-Age and Professionals deliver 62% and 60%
-- profitable campaigns respectively; Students only 42%.
-- ----------------------------------------------------------------
SELECT
    target_audience,
    COUNT(*)                                                       AS campaigns,
    ROUND(SUM(profit), 2)                                          AS total_profit,
    ROUND(AVG(profit), 2)                                          AS avg_profit_per_campaign,
    ROUND(AVG(profit_margin), 2)                                   AS avg_profit_margin_pct,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable,
    ROUND(AVG(CASE WHEN is_profitable THEN profit ELSE 0 END), 2)  AS avg_profit_when_profitable,
    ROUND(AVG(CASE WHEN NOT is_profitable THEN profit ELSE 0 END), 2) AS avg_loss_when_unprofitable
FROM marketing_campaigns
GROUP BY target_audience
ORDER BY total_profit DESC;

-- ================================================================
-- CATEGORY 6 : TIME-BASED ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- Q22. Seasonal performance: which quarter delivers the best ROI?
-- Expected insight: Q2 (106.3%) edges out Q3 (103.7%); Q1 (94.7%) is
-- weakest. Campaign TYPE matters far more than quarter (+/-10pp).
-- ----------------------------------------------------------------
SELECT
    campaign_quarter,
    COUNT(*)                                                       AS campaigns,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi,
    ROUND(SUM(revenue_generated), 2)                               AS total_revenue,
    ROUND(AVG(revenue_generated), 2)                               AS avg_revenue,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM marketing_campaigns
GROUP BY campaign_quarter
ORDER BY campaign_quarter;

-- ----------------------------------------------------------------
-- Q23. Year-over-year performance comparison
-- Expected insight: blended ROI 98.8% (2022) -> 92.1% (2023) ->
-- 97.1% (2024) while average CAC rose from $261 to $270 - efficiency
-- is flat and acquisition cost is creeping up.
-- ----------------------------------------------------------------
WITH yearly AS (
    SELECT
        year,
        COUNT(*)                                       AS campaigns,
        ROUND(SUM(revenue_generated), 2)               AS revenue,
        ROUND(SUM(amount_spent), 2)                    AS spend,
        ROUND(AVG(roi_percentage), 2)                  AS avg_roi,
        ROUND(AVG(customer_acquisition_cost), 2)       AS avg_cac,
        ROUND(AVG(ctr), 4)                             AS avg_ctr
    FROM marketing_campaigns
    GROUP BY year
)
SELECT
    year,
    campaigns,
    revenue,
    spend,
    avg_roi,
    avg_cac,
    avg_ctr,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year))
          / NULLIF(LAG(revenue) OVER (ORDER BY year), 0) * 100, 2)  AS revenue_yoy_pct,
    ROUND((avg_cac - LAG(avg_cac) OVER (ORDER BY year))
          / NULLIF(LAG(avg_cac) OVER (ORDER BY year), 0) * 100, 2)  AS cac_yoy_pct,
    ROUND(avg_roi - LAG(avg_roi) OVER (ORDER BY year), 2)           AS roi_yoy_change
FROM yearly
ORDER BY year;

-- ----------------------------------------------------------------
-- Q24. Campaign duration impact on ROI (short vs long)
-- Expected insight: duration is NOT a performance lever - average ROI
-- is ~95-104% in every duration bucket (correlation ~0.00).
-- ----------------------------------------------------------------
WITH duration_band AS (
    SELECT
        CASE
            WHEN campaign_duration_days <= 30  THEN '1. Short (0-30 days)'
            WHEN campaign_duration_days <= 60  THEN '2. Medium (31-60 days)'
            WHEN campaign_duration_days <= 90  THEN '3. Long (61-90 days)'
            WHEN campaign_duration_days <= 120 THEN '4. Extended (91-120 days)'
            ELSE '5. Marathon (120+ days)'
        END                                            AS duration_band,
        campaign_duration_days,
        roi_percentage,
        revenue_generated,
        is_profitable
    FROM marketing_campaigns
)
SELECT
    duration_band,
    COUNT(*)                                                       AS campaigns,
    ROUND(AVG(campaign_duration_days), 1)                          AS avg_duration_days,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi,
    ROUND(AVG(revenue_generated), 2)                               AS avg_revenue,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2) AS pct_profitable
FROM duration_band
GROUP BY duration_band
ORDER BY duration_band;

-- ----------------------------------------------------------------
-- Q25. Monthly trend analysis with running totals
-- Expected insight: cumulative revenue crosses $100M in mid-2023;
-- the running total flattens through 2024, confirming the flat trend.
-- ----------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_FORMAT(start_date, '%Y-%m-01') AS month,
        SUM(revenue_generated)              AS revenue,
        SUM(profit)                         AS profit,
        COUNT(*)                            AS campaigns
    FROM marketing_campaigns
    GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
)
SELECT
    month,
    ROUND(revenue, 2)                                              AS monthly_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY month), 2)                   AS cumulative_revenue,
    ROUND(profit, 2)                                               AS monthly_profit,
    ROUND(SUM(profit) OVER (ORDER BY month), 2)                    AS cumulative_profit,
    campaigns,
    ROUND(SUM(campaigns) OVER (ORDER BY month), 0)                 AS cumulative_campaigns,
    ROUND(revenue / NULLIF(SUM(revenue) OVER (), 0) * 100, 3)      AS pct_of_total
FROM monthly
ORDER BY month;

-- ================================================================
-- BONUS QUERIES : ADVANCED ANALYTICS (Q26-Q30)
-- ================================================================

-- ----------------------------------------------------------------
-- Q26. Profitable vs unprofitable campaign comparison
-- Expected insight: 53.4% of campaigns are profitable. The profitable
-- half averages +235% ROI; the losing half averages -54% ROI. The
-- losing half still consumes $86.2M of spend - the largest single
-- profit pool available to the business.
-- ----------------------------------------------------------------
SELECT
    CASE WHEN is_profitable THEN 'Profitable' ELSE 'Unprofitable' END AS profitability_group,
    COUNT(*)                                                       AS campaigns,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM marketing_campaigns) * 100, 2) AS pct_of_campaigns,
    ROUND(SUM(amount_spent), 2)                                    AS total_spend,
    ROUND(SUM(revenue_generated), 2)                               AS total_revenue,
    ROUND(SUM(profit), 2)                                          AS total_profit,
    ROUND(AVG(roi_percentage), 2)                                  AS avg_roi,
    ROUND(AVG(customer_acquisition_cost), 2)                       AS avg_cac,
    ROUND(AVG(conversion_rate), 4)                                 AS avg_conversion_rate,
    ROUND(AVG(performance_score), 2)                               AS avg_performance_score
FROM marketing_campaigns
GROUP BY CASE WHEN is_profitable THEN 'Profitable' ELSE 'Unprofitable' END
ORDER BY total_profit DESC;

-- ----------------------------------------------------------------
-- Q27. Campaign efficiency scoring and ranking
-- Expected insight: the composite score (25% CTR, 35% conversion rate,
-- 40% ROI) isolates the campaigns worth scaling - all of them sit in
-- the top decile of performance_score.
-- ----------------------------------------------------------------
WITH scored AS (
    SELECT
        campaign_id,
        campaign_name,
        channel,
        campaign_type,
        roi_percentage,
        conversion_rate,
        ctr,
        performance_score,
        profit,
        PERCENT_RANK() OVER (ORDER BY performance_score) AS percentile_rank
    FROM marketing_campaigns
)
SELECT
    campaign_id, campaign_name, channel, campaign_type,
    ROUND(roi_percentage, 2)  AS roi_pct,
    ROUND(conversion_rate, 4) AS conversion_rate,
    ROUND(ctr, 4)             AS ctr,
    ROUND(performance_score, 2) AS performance_score,
    ROUND(percentile_rank * 100, 2) AS percentile,
    ROUND(profit, 2)          AS profit
FROM scored
WHERE percentile_rank >= 0.99
ORDER BY performance_score DESC
LIMIT 20;

-- ----------------------------------------------------------------
-- Q28. Window function: running average ROI by channel
-- Expected insight: the running mean reveals how stable each channel
-- is month to month; SEO/Email stay above the portfolio mean while
-- Instagram/Social Media drift below it.
-- ----------------------------------------------------------------
WITH channel_month AS (
    SELECT
        channel,
        DATE_FORMAT(start_date, '%Y-%m-01') AS month,
        AVG(roi_percentage)                 AS monthly_roi,
        COUNT(*)                            AS campaigns
    FROM marketing_campaigns
    GROUP BY channel, DATE_FORMAT(start_date, '%Y-%m-01')
)
SELECT
    channel,
    month,
    ROUND(monthly_roi, 2)                                                   AS monthly_avg_roi,
    campaigns,
    ROUND(AVG(monthly_roi) OVER (PARTITION BY channel ORDER BY month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)                     AS running_3m_avg_roi,
    ROUND(AVG(monthly_roi) OVER (PARTITION BY channel), 2)                  AS channel_lifetime_avg_roi,
    ROUND(monthly_roi - AVG(monthly_roi) OVER (PARTITION BY channel), 2)    AS variance_vs_lifetime
FROM channel_month
ORDER BY channel, month;

-- ----------------------------------------------------------------
-- Q29. Cumulative revenue by campaign type over time
-- Expected insight: Retention and Conversion accumulate profit
-- fastest; Brand Awareness's cumulative line is almost flat, which is
-- the visual proof that it never pays back.
-- ----------------------------------------------------------------
WITH type_month AS (
    SELECT
        campaign_type,
        DATE_FORMAT(start_date, '%Y-%m-01') AS month,
        SUM(revenue_generated)              AS revenue,
        SUM(profit)                         AS profit
    FROM marketing_campaigns
    GROUP BY campaign_type, DATE_FORMAT(start_date, '%Y-%m-01')
)
SELECT
    campaign_type,
    month,
    ROUND(revenue, 2)                                              AS monthly_revenue,
    ROUND(SUM(revenue) OVER (PARTITION BY campaign_type ORDER BY month), 2) AS cumulative_revenue,
    ROUND(SUM(profit)  OVER (PARTITION BY campaign_type ORDER BY month), 2) AS cumulative_profit,
    ROUND(SUM(revenue) OVER (PARTITION BY campaign_type ORDER BY month)
          / NULLIF(SUM(SUM(revenue)) OVER (PARTITION BY campaign_type), 0) * 100, 2) AS pct_of_type_total
FROM type_month
ORDER BY campaign_type, month;

-- ----------------------------------------------------------------
-- Q30. Executive summary query: key KPIs in one query
-- Expected insight: a single row suitable for the executive dashboard
-- header - revenue, spend, profit, blended ROI, CAC, CTR, profitable
-- share and the count of loss-making campaigns.
-- ----------------------------------------------------------------
SELECT
    COUNT(*)                                                        AS total_campaigns,
    ROUND(SUM(budget_allocated), 2)                                 AS total_budget,
    ROUND(SUM(amount_spent), 2)                                     AS total_spend,
    ROUND(SUM(revenue_generated), 2)                                AS total_revenue,
    ROUND(SUM(profit), 2)                                           AS total_profit,
    ROUND((SUM(revenue_generated) / NULLIF(SUM(amount_spent), 0) - 1) * 100, 2) AS blended_roi_pct,
    ROUND(AVG(roi_percentage), 2)                                   AS avg_campaign_roi_pct,
    ROUND(AVG(customer_acquisition_cost), 2)                        AS avg_cac,
    ROUND(AVG(cpc), 2)                                              AS avg_cpc,
    ROUND(AVG(ctr), 3)                                              AS avg_ctr_pct,
    ROUND(AVG(conversion_rate), 3)                                  AS avg_conversion_rate_pct,
    ROUND(AVG(CASE WHEN is_profitable THEN 1 ELSE 0 END) * 100, 2)  AS pct_profitable,
    SUM(CASE WHEN NOT is_profitable THEN 1 ELSE 0 END)              AS loss_making_campaigns,
    ROUND(SUM(CASE WHEN NOT is_profitable THEN amount_spent ELSE 0 END), 2) AS spend_on_loss_makers,
    (SELECT channel FROM marketing_campaigns
     GROUP BY channel ORDER BY AVG(roi_percentage) DESC LIMIT 1)     AS best_channel_by_roi,
    (SELECT campaign_type FROM marketing_campaigns
     GROUP BY campaign_type ORDER BY AVG(roi_percentage) DESC LIMIT 1) AS best_type_by_roi,
    (SELECT geography FROM marketing_campaigns
     GROUP BY geography ORDER BY AVG(roi_percentage) DESC LIMIT 1) AS best_geography_by_roi
FROM marketing_campaigns;

-- ================================================================
-- END OF 03_business_queries.sql
-- 30 queries covering performance, channels, budget, geography,
-- audience, time-based and advanced analytics.
-- ================================================================
