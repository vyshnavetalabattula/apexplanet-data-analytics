# apexplanet-data-analytics
Data analytics internship project - ApexPlanet
#Task 1

**Foundational Setup & Exploratory Data Analysis (EDA)**

## Overview
- **Objective:** Set up an analytics environment, understand the data source, clean it,
  and perform exploratory data analysis with documented insights.
- **Dataset:** `Amazon_Sale_Report.csv` — Amazon.in order-level e-commerce data
  (31-Mar-2022 to 29-Jun-2022), 128,975 raw rows x 24 columns.
- **Key questions answered:** Which categories/states drive the most orders? How much
  revenue is lost to cancellations? How does daily sales volume trend over the period?
  Are there outlier/high-value orders worth flagging?

## Tech Stack
- Python, pandas, NumPy, Matplotlib, Seaborn
- Jupyter Notebook (executed, with embedded chart outputs)

## Project Structure
```
apexplanet-data-analytics/
├── data/
│   ├── raw/                 # original Amazon_Sale_Report.csv
│   └── processed/           # cleaned dataset + cleaning_log.txt
├── notebooks/
│   ├── 01_EDA_Amazon_Sale_Report.ipynb   # full EDA notebook
│   └── figures/              # exported PNG charts
├── scripts/
│   ├── clean_data.py         # reusable cleaning script
│   └── eda.py                 # reusable EDA/chart-generation script
├── reports/                   # (for Task 5 final report)
├── dashboards/                # (for Task 3 Power BI/Tableau files)
└── README.md
```

## How to Run
1. Ensure Python 3.10+ with `pandas`, `numpy`, `matplotlib`, `seaborn` installed:
   ```
   pip install pandas numpy matplotlib seaborn
   ```
2. From `scripts/`, run the cleaning step:
   ```
   python3 clean_data.py
   ```
3. Run the EDA/chart generation step:
   ```
   python3 eda.py
   ```
4. Open `notebooks/01_EDA_Amazon_Sale_Report.ipynb` in Jupyter to view the full,
   already-executed analysis with all charts inline.

## Data Cleaning Summary
| Step | Detail |
|---|---|
| Column names | Standardized to snake_case |
| Dropped columns | `Unnamed: 22` (empty) |
| Duplicates | 0 found |
| Data types | `date` → datetime; text fields → category |
| Missing `amount`/`currency` | 7,795 rows filled with 0 (cancelled/₹0 orders) |
| Missing `courier_status` | 6,872 rows filled with `"Not Shipped"` |
| Missing shipping address | 33 rows dropped (too few to impute) |
| `promotion-ids` | Converted to boolean `has_promotion` flag |
| Missing `fulfilled-by` | Filled with `"Amazon Fulfilled"` |
| Outliers (`amount`) | Flagged via IQR method (not removed) — 3,169 rows |
| **Result** | 128,942 rows x 27 columns (cleaned) |

## Key Findings
1. **~14.2%** of orders are `Cancelled`, plus ~1.5% `Shipped - Returned to Seller`.
2. **`Set`** and **`kurta`** categories account for ~78% of all order volume.
3. Median order value is **₹583** (IQR ₹413–₹771); ~2.5% of orders are high-value outliers.
4. Daily sales **peaked in early May (~₹1.2M/day)** then trended downward through June.
5. Order quantity vs. amount is only loosely correlated — most orders are single-unit.
6. Order volume is concentrated in a handful of states (led by Maharashtra, Karnataka).
7. Amazon-fulfilled orders dominate; B2B orders are under 1% of total volume.

## Author
Data Analytics Intern — ApexPlanet Software Pvt. Ltd. Internship (45-Day Program)
