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

# # Task 2 — SQL & Data Extraction

## Objective

Master SQL queries for data extraction, transformation, and aggregation; connect Python to a database.

## What Was Built

- **`data/processed/amazon_sales.db`** — SQLite database loaded from the Task 1 cleaned dataset (table `orders`, 128,942 rows).
- **`scripts/queries.sql`** — Complete SQL script covering fundamentals, advanced business queries, 3 views, and indexing/optimization.
- **`scripts/db_utils.py`** — Reusable Python module for database connections using SQLAlchemy, with automatic fallback to `sqlite3` if SQLAlchemy is not installed.
- **`notebooks/02_SQL_Data_Extraction.ipynb`** — Executed notebook running SQL queries from Python using `pandas.read_sql()`.

## Dataset Limitation & Adaptations

The Amazon Sale Report is an **order-line export with no customer ID field**. Therefore, two of the internship's suggested business queries were adapted accordingly. The adaptations are clearly documented in both the `.sql` file and the notebook.

| Suggested Query | Adaptation Used | Reason |
|---|---|---|
| Top 10 customers by revenue | Top 10 shipping city/state combinations by revenue | No customer ID exists — location is the closest available grouping |
| Customer retention rate | SKU repeat-order rate | No customer ID exists — SKU repetition is used as a demand-repetition proxy |

All other suggested queries, including monthly sales trends, product category performance, moving averages, and cumulative sums, are answered directly.

## SQL Concepts Covered

- `SELECT` / `WHERE` / `ORDER BY` / `LIMIT`
- `JOIN` — self-join, since there is only one table; demonstrates `INNER` / `LEFT JOIN` syntax
- `GROUP BY` / `HAVING`
- Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`
- Subqueries and CTEs using the `WITH` clause
- Window functions:
  - `ROW_NUMBER`
  - `RANK`
  - `LAG`
  - `NTILE`
- Views:
  - `monthly_category_sales`
  - `state_performance`
  - `daily_sales_summary`
- Query optimization using `EXPLAIN QUERY PLAN`
- Five indexes created on frequently filtered columns

## Key Findings

1. **Monthly revenue declined** from ₹28.8M in April → ₹26.2M in May → ₹23.4M in June.

2. **Maharashtra and Karnataka** were the top two revenue-generating states, with ₹13.3M and ₹10.5M respectively. Together, they contributed approximately **18% of total revenue**.

3. The **Set** and **kurta** categories recorded ₹3.47M and ₹1.87M respectively in cancelled order value, representing the biggest cancellation-driven revenue leaks.

4. Indexing `ship_state` changed the query plan from a full table **`SCAN`** to an index **`SEARCH`**, improving query execution for filtered aggregate queries.

## How to Run

Navigate to the `scripts` directory:

```bash
cd scripts
```

### Check the Database Connection

```bash
python3 db_utils.py
```

### Rebuild Views and Indexes

```bash
python3 -c "from db_utils import get_connection, execute_script; execute_script('queries.sql', get_connection())"
```

### Run the Notebook

Open:

```text
notebooks/02_SQL_Data_Extraction.ipynb
```

The notebook contains the SQL queries executed against the SQLite database using Python and displays the resulting outputs.
## Data Analytics Intern — ApexPlanet Software Pvt. Ltd. Internship (45-Day Program)
