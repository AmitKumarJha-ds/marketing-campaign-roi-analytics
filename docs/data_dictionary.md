# 📖 CampaignPulse — Data Dictionary

**Dataset:** `data/marketing_campaign_cleaned.csv`
**Rows:** 9,995 campaigns · **Columns:** 41 (27 source + 14 engineered)
**Period:** 1 Jan 2022 – 31 Dec 2024 (campaign start dates)
**Grain:** one row = one marketing campaign

Legend: 🟦 **Original** = present in the raw extract · 🟩 **Derived** = created in
`01_CampaignPulse_Data_Cleaning.ipynb`

---

## 1. Identifiers

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `campaign_id` | String | Unique campaign identifier, format `CAMP_nnnn`. Primary key of the table. | `CAMP_0001`, `CAMP_2843` | Joins to finance/CRM systems; guarantees each campaign is counted once. | 🟦 Original |
| `campaign_name` | String | Human-readable campaign name (theme + type + channel + year). | `Newsletter Retention - Content Marketing 2024` | Used in dashboards, tables and stakeholder reporting. | 🟦 Original |

## 2. Dimensions

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `campaign_type` | Category | Marketing objective of the campaign. 5 values. | `Brand Awareness`, `Lead Generation`, `Conversion`, `Retention`, `Re-engagement` | Strongest single driver of ROI (Retention 203.9% vs Brand Awareness −50.8%). | 🟦 Original |
| `channel` | Category | Media channel used. 10 values. | `Email`, `SEO`, `Google Ads`, `Instagram Ads`, `YouTube`, `Affiliate`, … | Determines cost structure and conversion quality. | 🟦 Original |
| `target_audience` | Category | Intended audience segment. 6 values. | `Mid-Age 35-50`, `Professionals 25-35`, `Students`, `Parents`, … | Drives CAC and conversion rate; segmentation basis for targeting. | 🟦 Original |
| `geography` | Category | Region of delivery. 6 values. | `North America`, `Europe`, `Asia Pacific`, `Latin America`, `Middle East`, `Africa` | Regional budget allocation and localisation decisions. | 🟦 Original |
| `campaign_status` | Category | Lifecycle status. 4 values. | `Completed`, `Active`, `Paused`, `Cancelled` | Governance: identifies the stop-the-bleed cohort (Cancelled = −48.1% ROI). | 🟦 Original |
| `quarter` | String | Calendar quarter of `start_date`. 4 values. | `Q1`, `Q2`, `Q3`, `Q4` | Fast slicing in dashboards. | 🟦 Original |
| `year` | Integer | Calendar year of `start_date`. | `2022`, `2023`, `2024` | Year-over-year comparisons. | 🟦 Original |
| `campaign_month` | String (ordered) | Month name of `start_date`. | `January` … `December` | Seasonality analysis at monthly granularity. | 🟩 Derived |
| `campaign_quarter` | Integer | Quarter number of `start_date`. | `1`, `2`, `3`, `4` | Numeric quarter for heatmaps and sorting. | 🟩 Derived |

## 3. Dates

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `start_date` | Date | Campaign launch date. | `2023-11-20` | Anchors all time-series analysis. | 🟦 Original |
| `end_date` | Date | Campaign end date (always ≥ `start_date` after cleaning). | `2024-02-18` | Defines duration and reporting window. | 🟦 Original |
| `campaign_duration_days` | Integer | `end_date − start_date` in days. | `7` … `180` | Tests whether longer flights improve ROI (they do not, r ≈ 0.00). | 🟩 Derived |

## 4. Financials

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `budget_allocated` | Float | Planned budget in USD (capped at the 99th percentile). | `2,833.93` … `248,000.00` | Plan vs actual; budget-tier analysis. | 🟦 Original |
| `amount_spent` | Float | Actual spend in USD. | `1,510.00` … `241,000.00` | Denominator of ROI, CPC, CPA and CAC. | 🟦 Original |
| `revenue_generated` | Float | Revenue attributed to the campaign in USD. | `121.42` … `468,743.26` | Numerator of ROI; the primary value metric. | 🟦 Original |
| `budget_utilization` | Float | `amount_spent / budget_allocated × 100`. | `55.00` … `105.00` | Spend discipline vs plan. | 🟩 Derived |
| `profit` | Float | `revenue_generated − amount_spent`. | `−48,887.00` … `460,000.00` | Absolute value created; basis of the profitability flag. | 🟩 Derived |
| `profit_margin` | Float | `profit / revenue_generated × 100`. | `−99.00` … `99.00` | Profitability intensity independent of campaign size. | 🟩 Derived |
| `cost_efficiency_ratio` | Float | `revenue_generated / amount_spent`. | `0.00` … `60.00` | Revenue returned per dollar spent; equals ROI/100 + 1. | 🟩 Derived |
| `revenue_per_impression` | Float | `revenue_generated / impressions`. | `0.0000` … `0.5000` | Monetisation of reach — how well traffic is monetised. | 🟩 Derived |
| `revenue_per_click` | Float | `revenue_generated / clicks`. | `0.00` … `500.00` | Monetisation of traffic; strongest positive correlate of ROI (r = 0.87). | 🟩 Derived |

## 5. Funnel volumes

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `impressions` | Integer | Total ad/content impressions. | `1,024` … `12,900,000` | Reach; top of the funnel. | 🟦 Original |
| `clicks` | Integer | Total clicks. | `10` … `380,000` | Traffic volume. | 🟦 Original |
| `leads_generated` | Integer | Leads captured. | `0` … `24,000` | Mid-funnel volume; always ≤ clicks. | 🟦 Original |
| `conversions` | Integer | Conversions / sales. | `0` … `9,500` | Bottom of funnel; always ≤ leads. | 🟦 Original |
| `lead_to_conversion_rate` | Float | `conversions / leads_generated × 100`. | `0.00` … `100.00` | Funnel closing efficiency (r = +0.36 with ROI). | 🟩 Derived |

## 6. Performance metrics

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `roi_percentage` | Float | `((revenue_generated − amount_spent) / amount_spent) × 100`. | `−99.25` … `10,365.48` | The headline KPI of the whole project. | 🟦 Original (recomputed) |
| `ctr` | Float | `clicks / impressions × 100`. | `0.02` … `12.00` | Creative relevance; uncorrelated with ROI. | 🟦 Original (recomputed) |
| `conversion_rate` | Float | `conversions / clicks × 100`. | `0.00` … `35.00` | Landing-page / offer quality (r = +0.40 with ROI). | 🟦 Original (recomputed) |
| `cpc` | Float | `amount_spent / clicks`. | `0.10` … `12.00` | Media buying efficiency per click. | 🟦 Original (recomputed) |
| `cpa` | Float | `amount_spent / conversions`. | `1.00` … `12,000.00` | Direct cost of an acquisition. | 🟦 Original (recomputed) |
| `customer_acquisition_cost` | Float | Direct CPA plus a 25% overhead allocation (`cpa × 1.25`). | `1.25` … `15,000.00` | Fully-loaded acquisition cost — the master optimisation variable (r = −0.30 with ROI). | 🟦 Original (recomputed) |
| `performance_score` | Float | Composite score = `0.25 × CTR + 0.35 × conversion_rate + 0.40 × ROI`, each min-max scaled to 0–100. | `0.00` … `100.00` | Single ranking metric for campaign triage and scaling decisions. | 🟩 Derived |

## 7. Engagement & quality

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `satisfaction_score` | Float | Customer / stakeholder satisfaction, 1.0–5.0. | `1.0` … `5.0` | Health metric; weak predictor of ROI. | 🟦 Original |
| `bounce_rate` | Float | Landing-page bounce rate, 0–100%. | `18.00` … `92.00` | Traffic quality indicator. | 🟦 Original |
| `engagement_rate` | Float | Engagement rate, 0–100%. | `0.30` … `30.00` | Content resonance. | 🟦 Original |

## 8. Segmentation

| Column | Type | Description | Sample Values | Business Relevance | Kind |
|--------|------|-------------|---------------|--------------------|------|
| `roi_category` | Category | ROI banding, 5 values. | `Negative ROI`, `Low (0-50%)`, `Medium (50-150%)`, `High (150-300%)`, `Exceptional (300%+)` | Segment-level reporting; 46.6% of campaigns sit in `Negative ROI`. | 🟩 Derived |
| `budget_tier` | Category | Budget banding, 5 values. | `Micro (<5K)`, `Small (5K-25K)`, `Medium (25K-100K)`, `Large (100K-250K)`, `Enterprise (250K+)` | Reveals diminishing returns: Micro 115.9% vs Large 66.8% average ROI. | 🟩 Derived |
| `is_profitable` | Boolean | `profit > 0`. | `True` / `False` | Fast filter for the loss-making cohort (46.6% of campaigns). | 🟩 Derived |

---

## 9. Data-quality notes

| Check | Raw | Cleaned |
|-------|-----|---------|
| Rows | 10,018 | 9,995 |
| Missing cells | 2,510 (0.93%) | 0 |
| Exact duplicate rows | 6 | 0 |
| Duplicate `campaign_id` | 22 | 0 |
| Impossible negative values | 66 | 0 |
| `end_date` < `start_date` | 25 | 0 |
| Mis-computed `roi_percentage` | ~300 (3%) | 0 (recomputed) |
| Non-standard category labels | ~300 rows | 0 (5 types / 10 channels / 6 geographies / 6 audiences / 4 statuses) |
| Outliers | 6,974 observations | Winsorised at the 1st/99th percentile |

**Outlier treatment:** capped, not removed, so the sample size and the long right tail of
exceptional campaigns are preserved.
