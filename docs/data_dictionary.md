# 📖 Data Dictionary
## Marketing Campaign Performance Dataset

**Source:** Kaggle — Marketing Campaign Performance Dataset  
**Total Records:** ~200,000 campaigns  
**Total Columns:** 16  
**File Format:** CSV  
**Time Period:** 2021  

---

## Column Details

### 🔑 Identifier Columns

| Column | Data Type | Description | Example |
|--------|-----------|-------------|---------|
| Campaign_ID | Integer | Unique ID for each campaign | 1, 2, 3 |
| Company | String | Company that ran the campaign | Innovate Industries, TechCorp |

---

### 📊 Campaign Details

| Column | Data Type | Description | Example Values |
|--------|-----------|-------------|----------------|
| Campaign_Type | String | Type of marketing campaign | Email, Social Media, Influencer, Display, Search |
| Channel_Used | String | Platform where campaign ran | Google Ads, Facebook, Instagram, YouTube, Email, Website |
| Duration | Integer | Days campaign was live | 15, 30, 45, 60 |
| Date | Date | Campaign start date | 2021-01-15 |

---

### 🎯 Audience & Location

| Column | Data Type | Description | Example |
|--------|-----------|-------------|---------|
| Target_Audience | String | Demographics targeted | Men 18-24, Women 25-34, All Ages |
| Location | String | Geographic location | New York, Los Angeles, Chicago |
| Language | String | Campaign language | English, Spanish, Mandarin |
| Customer_Segment | String | Buyer category | Tech Enthusiasts, Fashion, Health |

---

### 💰 Performance Metrics (KEY COLUMNS)

| Column | Data Type | Description | Business Use |
|--------|-----------|-------------|--------------|
| Impressions | Integer | Times ad was shown | Reach measurement |
| Clicks | Integer | Total clicks received | Traffic generated |
| Conversion_Rate | Float | % of clicks that converted (0.01-0.15) | Sales efficiency |
| Acquisition_Cost | Float | ₹ spent on campaign | Investment amount |
| ROI | Float | Return on Investment ratio (2-8x) | Profitability |
| Engagement_Score | Integer | Engagement rating (1-10) | Content quality |

---

## 🔢 Calculated Metrics (We Will Create)

These will be calculated during analysis:

| Metric | Formula | Purpose |
|--------|---------|---------|
| CTR (Click-Through Rate) | (Clicks / Impressions) × 100 | Ad effectiveness |
| Conversions | Clicks × Conversion_Rate | Total customers |
| CPC (Cost per Click) | Acquisition_Cost / Clicks | Cost per traffic |
| CPA (Cost per Acquisition) | Acquisition_Cost / Conversions | Cost per customer |
| Revenue | ROI × Acquisition_Cost | Total returns |
| Profit | Revenue - Acquisition_Cost | Net profit |
| ROAS | Revenue / Acquisition_Cost | Return per ₹1 |

---

## 🔍 Data Quality Notes

- Some columns may have NULL values (will check in EDA)
- Currency to be treated as ₹ (Indian Rupees) for our analysis
- Date column may need format conversion
- Categorical columns may have variations in naming
- These will be cleaned in the data preparation notebook