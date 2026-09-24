# 🎯 CampaignPulse — Business Problems Addressed

This document lists the business questions the project was built to answer, the analysis that
answers each one, and the evidence produced.

---

## Primary business questions

| # | Business question | Where it is answered | Evidence / answer |
|---|-------------------|----------------------|-------------------|
| 1 | Which marketing campaigns deliver the highest ROI? | Chart 1, Chart 6, SQL Q2/Q3 | **Retention (203.9%)** and **Conversion (156.5%)** types; top campaign `CAMP_2843` at **10,365% ROI** on a $2,834 budget |
| 2 | How do different marketing channels compare in cost-efficiency? | Chart 2, Chart 7, SQL Q6/Q7/Q8 | **SEO 191.7%**, **Email 185.8%**, **Affiliate 185.4%** vs **Instagram 23.1%**, **Social Media 24.1%**; CAC $198 (SEO) vs $406 (Instagram) |
| 3 | What is the optimal budget allocation across campaign types? | Chart 1, Chart 5, SQL Q12 | Rebalance from Brand Awareness (−50.8%) into Retention / Conversion / Lead Generation |
| 4 | Which geographic regions respond best to marketing efforts? | Chart 9, SQL Q16/Q18 | **North America 121.6%** and **Europe 111.7%** ($232M of $389M revenue); **Africa 51.8%** weakest |
| 5 | What is the ideal campaign duration for maximum ROI? | Chart 8, SQL Q24 | Duration is **not** a lever — average ROI is 95–104% in every duration bucket (r ≈ 0.00) |
| 6 | Which target audience segments are most profitable? | Chart 10, SQL Q19/Q21 | **Mid-Age 35-50 (167.5%)** and **Professionals 25-35 (152.5%)**; **Students (7.5%)** weakest |
| 7 | How do seasonal patterns affect campaign performance? | Chart 11, SQL Q22 | **Q2 106.3%** best, **Q1 94.7%** worst; campaign *type* matters ~10× more than quarter |
| 8 | What is the relationship between budget size and success? | Chart 5, SQL Q13 | Budget elasticity ≈ **0.70** (diminishing returns); Micro tier 115.9% vs Large tier 66.8% |
| 9 | Which campaigns should be scaled, paused or discontinued? | Chart 6, SQL Q26/Q27 | Scale the top-decile `performance_score` campaigns; triage the **4,660 loss-making** campaigns ($86.2M of spend) |
| 10 | What is the customer acquisition cost trend across channels? | Chart 7, SQL Q7/Q23 | CAC $261 (2022) → $266 (2023) → **$270 (2024)**; Instagram and Influencer most expensive |
| 11 | How has marketing efficiency evolved over 3 years? | Chart 3, SQL Q23 | Blended ROI **98.8% → 92.1% → 97.1%**; revenue flat while spend fell from $68.5M to $63.6M |
| 12 | Which channel + audience + type combination yields the highest returns? | SQL Q14/Q20 | **Retention × SEO / Email / Affiliate** and **Mid-Age 35-50 × SEO (311% ROI)** |
| 13 | Are there diminishing returns as budgets increase? | Chart 5, SQL Q13 | **Yes** — elasticity 0.70, ROI falls monotonically from Micro to Large tiers |
| 14 | What distinguishes top performers from underperformers? | Chart 6, Chart 12, SQL Q27 | Low CAC, high conversion rate, high `revenue_per_click` — **not** impressions, clicks or budget |
| 15 | How can the company optimise spend to maximise ROI? | Findings, Recommendations | Reallocate ~15% of Brand Awareness budget to Retention; shift paid social to SEO/Email/Affiliate; manage to CAC |

---

## Supporting questions answered by the SQL layer

| # | Question | Query |
|---|----------|-------|
| 16 | What is the overall average ROI and how skewed is it? | Q1 |
| 17 | Which statuses consume budget without returning it? | Q5 |
| 18 | What is the full funnel conversion by channel? | Q10 |
| 19 | How much of the budget is actually used? | Q11, Q12 |
| 20 | What is the month-over-month revenue growth rate? | Q15 |
| 21 | What is the best channel in each geography? | Q17 |
| 22 | What is the cumulative revenue trajectory? | Q25, Q29 |
| 23 | Which campaigns are in the top 1% of performance? | Q27 |
| 24 | How stable is each channel's ROI over time? | Q28 |
| 25 | What are the executive KPIs in one view? | Q30 |

---

## Business impact framing

| Problem | Size of the prize |
|---------|-------------------|
| Loss-making campaigns (46.6% of the portfolio) | **$86.2M of spend** producing negative attributable revenue |
| Brand Awareness campaigns | **$39.9M spend → $21.2M revenue** (−47% return, $18.7M lost) |
| Cancelled campaigns | 699 campaigns, 23% budget utilisation, only 13% profitable |
| Channel mix inefficiency | Moving spend from Instagram/Social Media ($406/$335 CAC) to Email/Affiliate/SEO ($144/$161/$198 CAC) cuts blended CAC materially |
| CAC creep | +$9 per customer since 2022 with no revenue growth |

---

## Assumptions and limitations

1. **Revenue attribution** is taken as given in the source data; no multi-touch attribution
   model is applied.
2. **`customer_acquisition_cost`** is modelled as direct CPA plus a 25% overhead allocation,
   since the source provides both fields separately.
3. **Outliers are capped, not removed**, so average ROI reflects a slightly conservative view
   of the break-out campaigns.
4. **Cancelled and Paused campaigns** are retained in the dataset because their economics are
   themselves a business signal.
5. The dataset is **synthetic** — generated to be statistically realistic (funnel consistency,
   channel-level economics, seasonality, diminishing returns) for portfolio and demonstration
   purposes.
