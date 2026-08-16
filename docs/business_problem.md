# 📊 Business Problem Statement
## Marketing Campaign Performance & ROI Analytics

---

## 🏢 Business Context

A multi-brand digital-first company runs marketing campaigns 
across multiple channels — Google Ads, Facebook, Instagram, 
YouTube, Email, and Website — targeting different audiences 
across various locations.

The company has been spending significant budget on marketing 
but the leadership team has raised a critical concern:

> "We are spending crores on marketing campaigns, but we don't 
>  know which channels actually generate PROFITABLE customers. 
>  Some campaigns get lots of clicks but low ROI. Some get 
>  fewer clicks but high ROI.
>  
>  If I give the marketing team another ₹10 lakh next month, 
>  where should they spend it — and what should we expect 
>  in return?"

---

## 🎯 The Core Business Problem

The company faces THREE critical questions:

### Problem 1: Channel ROI Blindness
- Multiple channels used (Google, Facebook, Email, etc.)
- No clarity on which channel gives highest ROI
- Budget may be going to underperforming channels

### Problem 2: Audience Targeting Confusion
- Multiple audience segments targeted
- Unclear which audience converts best
- Wasted spend on non-responsive audiences

### Problem 3: Campaign Type Effectiveness
- Multiple campaign types (Search, Display, Social, Email)
- No data-driven decision on which type to invest more
- Budget allocation based on gut feel, not data

---

## 📈 Project Objectives

As the Data Analyst on this project, I will:

1. **Measure Marketing Health**
   - Calculate overall ROI across all campaigns
   - Total spend vs total returns
   - Best and worst performing campaigns

2. **Identify Winning Channels**
   - ROI by each channel (Google, FB, Email, etc.)
   - Cost per acquisition (CAC) per channel
   - Conversion efficiency per channel

3. **Understand Audience Behavior**
   - Which audience segments convert best
   - Which segments give highest ROI
   - Location-wise performance patterns

4. **Analyze Campaign Types**
   - Which campaign type (Email, Social, Display) works best
   - Duration impact on ROI
   - Engagement vs conversion relationship

5. **Deliver Budget Recommendations**
   - Where to allocate next ₹10 lakh
   - Expected ROI from recommended allocation
   - Which channels to scale up / cut down

---

## 📊 Key Performance Indicators (KPIs)

| KPI | Definition | Business Meaning |
|-----|------------|------------------|
| Total Marketing Spend | Sum of Acquisition_Cost | How much we invested |
| Total Impressions | Sum of Impressions | Total reach |
| Total Clicks | Sum of Clicks | Traffic generated |
| Overall CTR | Clicks / Impressions × 100 | Ad effectiveness |
| Overall Conversion Rate | Avg Conversion_Rate | Purchase efficiency |
| Overall ROI | Avg ROI | Investment return |
| Cost per Click (CPC) | Spend / Clicks | Traffic cost |
| Cost per Acquisition | Spend / Conversions | Customer cost |
| ROAS | Revenue / Ad Spend | Return per ₹1 spent |
| Best Channel ROI | Max channel ROI | Winner identification |

---

## 👥 Stakeholders & Their Needs

| Stakeholder | What They Need |
|-------------|----------------|
| CMO (Chief Marketing Officer) | Overall marketing performance & budget strategy |
| Marketing Manager | Channel-wise performance to optimize daily |
| Campaign Manager | Which campaign type/audience to focus on |
| Finance Team | ROI justification for marketing spend |
| CEO | Business impact of marketing investment |

---

## 📦 Expected Deliverables

1. **SQL Analysis** — 15 business queries answered
2. **Python Notebooks** (4 notebooks):
   - Data Cleaning & EDA
   - Channel & Campaign Performance
   - CAC, LTV, ROI Deep Dive
   - Budget Allocation Recommendations
3. **Power BI Dashboard** — CMO Executive Dashboard
4. **Tableau Dashboard** — Published on Tableau Public
5. **Executive PPT** — 12-slide presentation
6. **Insights Document** — Data-backed recommendations
7. **Budget Playbook** — Where to spend next ₹10 lakh

---

## ⚠️ Assumptions & Limitations

- ROI values in dataset are treated as final numbers
- Acquisition_Cost is treated as total campaign spend
- Revenue is calculated as: ROI × Acquisition_Cost
- Analysis based on historical data (2021 snapshot)
- Attribution model is basic (last-click attribution assumed)
- Customer lifetime value not directly available in dataset

---

## 🎯 Success Criteria

This project succeeds if:

✅ Identify top 3 highest-ROI channels with data
✅ Identify top 3 lowest-ROI channels to cut
✅ Quantify expected returns for next ₹10 lakh spend
✅ Provide audience + channel + campaign type combinations
   that maximize ROI
✅ Dashboard enables weekly marketing decisions
✅ Recommendations implementable in next quarter