# 📊 CampaignPulse — Tableau Dashboard Build Guide

**Workbook:** `tableau/CampaignPulse_Marketing_ROI_Dashboard.twbx`
**Data source:** `data/marketing_campaign_cleaned.csv` (9,995 rows × 41 columns)
**Target version:** Tableau Desktop / Tableau Public 2024.1 or later
**Theme:** CampaignPulse (palette below)

---

## 1. Colour theme

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#2E86AB` | Titles, bars, headers, primary lines |
| Secondary | `#A23B72` | Secondary series, comparison bars |
| Accent | `#F18F01` | Highlights, targets, annotations |
| Positive | `#44BBA4` | Profit, good ROI, growth |
| Negative | `#C73E1D` | Loss, bad ROI, warnings |
| Background | `#F8F9FA` | Dashboard background |
| Text | `#2D3436` | Body text |

**Apply the palette:** create a *Custom Colour* palette in `My Tableau Repository`
(`Preferences.tps`) or use *Format → Workbook Theme → Import* with these values so all
dashboards stay consistent.

---

## 2. Connect to the data

1. Open `tableau/CampaignPulse_Marketing_ROI_Dashboard.twbx`
   (double-click — Tableau unpacks `Data/marketing_campaign_cleaned.csv` automatically).
2. If Tableau asks to repair the connection, use
   **Data → New Data Source → Text File** and point it at
   `data/marketing_campaign_cleaned.csv`.
3. Confirm the field roles: `campaign_id`, `campaign_name`, `campaign_type`, `channel`,
   `target_audience`, `geography`, `campaign_status`, `quarter`, `campaign_month`,
   `roi_category`, `budget_tier` → **Dimensions**; all money, funnel and rate fields →
   **Measures**; `start_date` / `end_date` → **Date**.
4. Create these **calculated fields** (already declared in the shipped `.twb`):

| Field | Formula | Type |
|-------|---------|------|
| `Is Profitable` | `IF [profit] > 0 THEN 'Profitable' ELSE 'Loss-making' END` | String |
| `ROI Band` | `IF [roi_percentage] < 0 THEN '1. Negative ROI' ELSEIF [roi_percentage] < 50 THEN '2. Low (0-50%)' ELSEIF [roi_percentage] < 150 THEN '3. Medium (50-150%)' ELSEIF [roi_percentage] < 300 THEN '4. High (150-300%)' ELSE '5. Exceptional (300%+)' END` | String |
| `Revenue per Dollar` | `[revenue_generated] / [amount_spent]` | Float |
| `Campaign Month (start)` | `DATETRUNC('month', [start_date])` | Date |
| `Profitability Flag` | `IF [profit] > 0 THEN 1 ELSE 0 END` | Integer |

5. Right-click the data source → **Extract** (recommended for performance) → save.

---

## 3. Dashboard 1 — Executive Overview

**Layout:** 5 KPI cards on top, then a 2×3 grid.

| Element | Sheet | Marks / Encoding |
|---------|-------|------------------|
| KPI card 1 | KPI | `SUM(revenue_generated)` → `$388.9M`, label "TOTAL REVENUE" |
| KPI card 2 | KPI | `SUM(amount_spent)` → `$198.4M`, label "TOTAL SPEND" |
| KPI card 3 | KPI | `(SUM(revenue)/SUM(spend)-1)*100` → `96.0%`, label "OVERALL ROI" |
| KPI card 4 | KPI | `COUNTD(campaign_id)` → `9,995`, label "TOTAL CAMPAIGNS" |
| KPI card 5 | KPI | `AVG(customer_acquisition_cost)` → `$266`, label "AVG CAC" |
| Revenue vs spend trend | Line | Columns: `Campaign Month (start)` (continuous month). Rows: `SUM(revenue_generated)` and `SUM(amount_spent)`. Two colours: Primary / Secondary. |
| ROI by campaign type | Bar (horizontal) | Rows: `campaign_type`. Columns: `AVG(roi_percentage)`. Colour: `AVG(roi_percentage)` (red→green diverging, stepped). Add data labels. |
| Campaign status distribution | Pie | Angle: `COUNTD(campaign_id)`. Colour: `campaign_status`. Add `% of total` labels. |
| Profitable vs unprofitable | Donut | Angle: `COUNTD(campaign_id)`. Colour: `Is Profitable` (Positive / Negative). |
| ROI by geography | Bar | Rows: `geography`. Columns: `AVG(roi_percentage)`. Sorted descending. |

**Filters to show:** Year, Quarter, Campaign Type, Channel, Geography
(right-click each → *Show Filter*).

**Title:** "Executive Overview" — add the CampaignPulse logo placeholder in the top-left.

---

## 4. Dashboard 2 — Channel Performance Analysis

| Element | Sheet | Marks / Encoding |
|---------|-------|------------------|
| Channel ROI comparison | Bar (horizontal) | Rows: `channel`. Columns: `AVG(roi_percentage)`. Colour by ROI band. Sorted descending. |
| Channel conversion funnel | Funnel (or bar) | Use the funnel chart type (Tableau 2024+): Size = `SUM(conversions)`, Colour = `channel`. Fallback: horizontal bar of `SUM(leads_generated)` by channel. |
| CPC and CPA by channel | Dual-axis bar + line | Columns: `channel`. Rows: `AVG(cpc)` (bar) and `AVG(cpa)` (line, secondary axis). |
| Revenue contribution | Treemap | Size: `SUM(revenue_generated)`. Colour: `channel`. Label: `% of total`. |
| Channel performance over time | Line | Columns: `Campaign Month (start)` (quarter granularity). Rows: `AVG(roi_percentage)`. Colour: `channel`. Show the top 6 channels. |

**Insight call-outs to add as floating text:**
- "SEO 191.7% vs Instagram Ads 23.1% average ROI"
- "SEO acquires a customer for $198; Instagram Ads for $406"

---

## 5. Dashboard 3 — Campaign Deep Dive

| Element | Sheet | Marks / Encoding |
|---------|-------|------------------|
| Budget vs revenue scatter | Scatter | Columns: `SUM(budget_allocated)` (log axis). Rows: `SUM(revenue_generated)` (log axis). Colour: `campaign_type`. Detail: `campaign_name`. |
| Campaign duration vs ROI | Scatter | Columns: `campaign_duration_days`. Rows: `AVG(roi_percentage)`. Size: `SUM(budget_allocated)`. Colour: `campaign_type`. |
| Top 10 campaigns table | Table | Columns: `campaign_name`, `channel`, `campaign_type`, `budget_allocated`, `revenue_generated`, `roi_percentage`. Sort by ROI descending, take top 10. |
| Budget tier performance | Bar | Rows: `budget_tier`. Columns: `AVG(roi_percentage)`. Colour by `Is Profitable`. |
| Geographic performance | Map + bar | Map: `SUM(revenue_generated)` by `geography` (filled map). Companion bar: `AVG(roi_percentage)`. |

**Filters:** Year, Quarter, Campaign Type, Channel, Geography, Budget Tier.

---

## 6. Dashboard 4 — ROI Trends & Insights

| Element | Sheet | Marks / Encoding |
|---------|-------|------------------|
| Monthly ROI trend with forecast | Line | Columns: `Campaign Month (start)`. Rows: `AVG(roi_percentage)` (3-month rolling via a table calculation). Add a forecast via *Analytics → Forecast*. |
| Seasonal heatmap | Heatmap | Columns: `campaign_quarter`. Rows: `campaign_type`. Colour: `AVG(roi_percentage)` (Red-Green diverging, centre at 0). Add labels. |
| Audience segment radar | Radar | Use the Tableau radar-chart extension, or replicate with a line chart on a 4-axis template: `target_audience` vs `AVG(roi_percentage)`, `AVG(ctr)`, `AVG(conversion_rate)`, `AVG(engagement_rate)` (min-max scaled). |
| Correlation analysis | Bar | Rows: numeric field names. Columns: `CORR(field, roi_percentage)` (calculated field per driver). Sort by value. |
| Year-over-year growth | Dual axis | Columns: `year`. Rows: `SUM(revenue_generated)` (bar) and `AVG(customer_acquisition_cost)` (line). |

---

## 7. Dashboard-level settings (apply to all four)

1. **Size:** Fixed size 1600 × 900 px (or "Automatic" for responsive).
2. **Background:** `#F8F9FA`.
3. **Title:** 18 pt bold, `#2D3436`, left-aligned.
4. **Filters:** show as *Multiple Values (dropdown)* in the top-right corner.
5. **Tooltips:** customise each sheet's tooltip with
   `Campaign: <campaign_name>`, `Channel: <channel>`, `Budget: <budget_allocated>`,
   `Revenue: <revenue_generated>`, `ROI: <roi_percentage>%`.
6. **Actions:** add a *Filter* action from Executive Overview → Channel Analysis so
   clicking a campaign type filters the channel dashboard.
7. **Publish:** *File → Save to Tableau Public* (or Server → Publish) as
   `CampaignPulse_Marketing_ROI_Dashboard`.

---

## 8. Verification checklist

- [ ] All 41 fields load with correct types (no `Abc` on measures).
- [ ] Executive Overview shows Revenue $388.9M / Spend $198.4M / ROI 96.0% / 9,995 campaigns.
- [ ] Channel dashboard ranks SEO first and Instagram Ads last.
- [ ] Deep-dive table lists `CAMP_2843` (Newsletter Retention – Content Marketing 2024)
      as the top ROI campaign.
- [ ] Trends dashboard shows flat 2022→2024 revenue with rising CAC.
- [ ] Every dashboard has Year / Quarter / Campaign Type / Channel / Geography filters.

---

## 9. Notes on the shipped files

* `CampaignPulse_Marketing_ROI_Dashboard.twbx` bundles the `.twb` data-source layer,
  the cleaned CSV (`Data/`) and the four dashboard previews (`Image/`).
* The `.twb` shipped here declares the connection and all fields/calculations. Tableau
  does not export a machine-generated sheet layout from this repository, so the four
  dashboards are assembled manually using the tables in sections 3–6 — each table lists
  the exact shelves and encodings to use.
* `tableau/screenshots/*.png` are data-accurate renderings of the four finished
  dashboards, produced from the same cleaned dataset, and can be used directly in the
  report and presentation while Tableau is unavailable.
