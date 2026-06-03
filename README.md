# RFM in Action: Behavioral Segmentation for E-Commerce

> *Turning raw transaction logs into actionable CRM strategy using RFM segmentation, cohort retention modeling, and behavioral clustering.*

---

## What This Project Is About

Most e-commerce businesses struggle to answer a deceptively simple question: **who are your best customers, and how do you keep them?**

This project builds a complete customer analytics pipeline for a UK-based online gift retailer — from raw transactional data to a business-ready segmentation framework. The goal was to move beyond surface-level sales reporting and deliver segment-level behavioral intelligence that can directly drive CRM, lifecycle marketing, and budget allocation decisions.

The core question driving the analysis:

> **Can we identify high-value customers, flag churn risk early, and design retention strategies — using only historical purchase data?**

Answer: Yes.

---

## Dataset

| Property | Detail |
|---|---|
| **Source** | UCI Online Retail II Dataset |
| **Period** | December 2009 – December 2011 |
| **Volume** | ~780K cleaned transaction records |
| **Market** | UK-based online gift retailer |

Each record includes invoice number, product details, quantity, unit price, customer ID, and purchase timestamp.

---

## Project Structure

```
├── sql/
│   ├── feature_engineering.sql      # Customer-level RFM + behavioral features
│   └── cohort_queries.sql           # Cohort construction & retention rate computation
│
├── notebooks/
│   ├── 01_eda_and_cleaning.ipynb    # Data validation, cleaning, schema audit
│   ├── 02_customer_segmentation.ipynb  # RFM scoring, K-Means exploration, segment mapping
│   └── 03_retention_analysis.ipynb  # Cohort analysis, retention curves, segment heatmaps
│
├── images/                          # All exported visualizations
└── README.md
```

---

## Phase 1 — Data Cleaning & Validation

**Objective:** Build a clean, reliable transaction table as the foundation for all downstream analysis.

The raw dataset had several quality issues that needed to be resolved before any meaningful analysis could begin:

- Converted raw timestamp strings to proper `datetime` format
- Dropped records with missing `CustomerID` (non-attributable transactions)
- Filtered out canceled invoices (prefix `C`) and return entries
- Removed zero-price and negative-quantity anomalies
- Eliminated exact duplicate rows
- Audited schema consistency and validated date coverage end-to-end

**Output:** A validated, purchase-only transaction table covering ~780K records across a 2-year window.

---

## Phase 2 — Customer Segmentation

### Step 1: Feature Engineering (SQL)

All customer-level features were computed in SQL before being passed to Python for modeling. Features built:

| Feature | Description |
|---|---|
| Recency | Days since most recent purchase |
| Frequency | Total distinct orders placed |
| Monetary Value | Cumulative spend across all invoices |
| Average Order Value | Spend per transaction |
| Interpurchase Gap | Avg. days between consecutive orders |
| Active Lifespan | Days between first and last purchase |
| Avg. Items per Order | Basket size indicator |
| Avg. Unit Price | Price tier proxy |

### Step 2: Unsupervised Clustering Exploration

Before committing to a segmentation approach, K-Means clustering was tested on scaled, transformed features:

- Applied **winsorization** to cap outlier distortion
- Used **log transformation** to normalize skewed distributions
- Scaled with **RobustScaler** to handle remaining spread
- Evaluated via elbow method, PCA scatter plots, and silhouette scores

**Finding:** Cluster boundaries were diffuse — behavioral gradients were continuous rather than naturally grouped. K-Means produced geometrically valid but business-ambiguous clusters.

**Decision:** Pivoted to **RFM-based rule segmentation** for interpretability, stability, and direct marketing alignment.

### Step 3: RFM Behavioral Segmentation

Each customer received R, F, and M scores, then was mapped to one of 10 actionable segments:

| Segment | Profile |
|---|---|
| **Champions** | Bought recently, buy often, spend the most |
| **Loyal** | Regular buyers with strong spend history |
| **Potential Loyalist** | Recent, moderate frequency — high growth potential |
| **Promising** | New-ish with decent engagement |
| **New Customers** | First-time buyers |
| **Need Attention** | Previously active, now going quiet |
| **About to Sleep** | Dropping off — needs re-engagement soon |
| **At Risk** | Was a good customer, hasn't returned |
| **Cannot Lose Them** | High-value but lapsed — critical win-back target |
| **Hibernating** | Low frequency, haven't purchased in a long time |

### Key Revenue Concentration Finding

> **Champions (~18% of customers) account for ~69% of total revenue.**

Loyal + Potential Loyalist segments represent the highest-upside growth opportunity with targeted nurture investment.

---

## Phase 3 — Cohort & Retention Analysis

### Cohort Construction

- Each customer was assigned to a **monthly cohort** based on their first purchase date
- A customer-month activity table tracked subsequent engagement
- Retention rates were computed for each month-since-acquisition offset

### Retention Findings

- **Sharp Month-1 → Month-2 drop**: Most customers do not return after their first purchase — indicating a critical onboarding gap
- **Long-tail repeat base**: A subset of customers becomes genuinely habitual, sustaining revenue well beyond 12 months
- **Segment divergence is dramatic**: Champions and Loyal cohorts retain at 3–5x the rate of Hibernating or At Risk cohorts

### Visualizations Produced

- Overall retention curve (all cohorts combined)
- Per-segment retention curves (Champions vs. At Risk, etc.)
- Cohort heatmaps broken down by RFM segment
- Weighted retention comparison across all 10 segments

---

## Business Recommendations

| Insight | Action |
|---|---|
| Champions drive outsized revenue | Protect with loyalty perks, early access, VIP treatment |
| Month-1 churn is the biggest leak | Build a structured post-purchase onboarding flow |
| At Risk / Cannot Lose Them are recoverable | Run time-limited win-back offers with personalized messaging |
| Hibernating customers have low ROI | Suppress from paid media; redirect budget to higher-return segments |
| Potential Loyalists are primed to grow | Increase touchpoint frequency before they plateau |

---

## Tech Stack

| Layer | Tools |
|---|---|
| **Data Warehousing** | Microsoft SQL Server |
| **Analysis & Modeling** | Python — Pandas, NumPy, Scikit-learn |
| **Visualization** | Seaborn, Matplotlib |
| **Methods** | RFM Segmentation, K-Means Clustering, PCA, Cohort Retention Analysis |

---

## How to Reproduce

1. Run SQL scripts in `/sql/` in order — `feature_engineering.sql` first, then `cohort_queries.sql`
2. Execute notebooks in `/notebooks/` sequentially (`01` → `02` → `03`)
3. All output visualizations are saved automatically to `/images/`

---

## Core Takeaway

> **Retention beats acquisition.** The data consistently shows that protecting and deepening relationships with existing high-value customers generates more durable revenue growth than investing the same budget into new customer acquisition. Segmentation is the mechanism that makes this actionable at scale.

---