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

# Task 2: SQL & Data Extraction



## Overview

This task focuses on using SQL for data extraction, transformation, aggregation, and business-oriented analysis, along with integrating SQL databases with Python.

The analysis was performed on the cleaned **Amazon Sale Report** dataset containing **128,942 order lines from March–June 2022**, carried forward from Task 1.

## Objectives

- Practice SQL fundamentals for data extraction and analysis
- Perform filtering, sorting, aggregation, and grouping
- Understand and implement different SQL JOIN operations
- Use subqueries, CTEs, and window functions
- Answer business questions using SQL
- Calculate sales trends and category performance
- Perform retention analysis
- Calculate moving averages and cumulative revenue
- Create and query SQL views
- Understand query optimization using indexes and `EXPLAIN QUERY PLAN`
- Integrate Python with SQL using SQLAlchemy and Pandas
- Use parameterized queries for safer database operations

---

## 1. SQL Fundamentals

The notebook covers the following SQL concepts:

### SELECT, WHERE, ORDER BY & LIMIT

Retrieved the 10 highest-value shipped orders from the **Western Dress** category.

### SQL JOINs

Demonstrated:

- INNER JOIN
- LEFT JOIN
- RIGHT JOIN
- FULL OUTER JOIN

A `state_region` lookup table was used to map shipping states to regions.

### GROUP BY, Aggregations & HAVING

Performed category-level and state-level analysis using:

- `COUNT()`
- `SUM()`
- `AVG()`
- `MIN()`
- `MAX()`
- `HAVING`

Examples include order counts, total units, average order value, and high-value shipping states.

### Subqueries & CTEs

Used subqueries and Common Table Expressions (CTEs) to identify:

- Orders above the overall average order value
- Categories containing above-average orders

### Window Functions

Implemented:

- `ROW_NUMBER()`
- `RANK()`
- `LAG()`
- `LEAD()`

These were used to compare orders within product categories based on order value.

---

## 2. Advanced SQL & Business Analysis

### Monthly Sales Trend

Calculated monthly:

- Order count
- Total revenue
- Average order value

A bar chart was also created to visualize total revenue by month.

### Top Revenue-Generating Locations

Identified the top 10 shipping locations based on total revenue using:

- `ship_city`
- `ship_postal_code`
- Order count
- Total revenue

### Retention Analysis

Calculated the percentage of shipping locations that had orders across more than one distinct week.

> **Important:** The dataset does not contain a `customer_id`. Therefore, `ship_city` + `ship_postal_code` was used as a delivery-location/customer proxy for this analysis.

### Product Category Performance

Compared product categories using:

- Order count
- Units sold
- Total revenue
- Average order value
- Percentage contribution to total revenue

### 7-Day Moving Average & Cumulative Revenue

Used SQL window functions to calculate:

- Daily revenue
- 7-day moving average revenue
- Cumulative revenue

A visualization was created comparing daily revenue with the 7-day moving average.

### SQL View

Created a reusable SQL view:

`vw_monthly_category_revenue`

The view provides monthly revenue and order counts by product category.

### Query Optimization

Used:

`EXPLAIN QUERY PLAN`

to examine how SQLite executes queries and verify index usage.

Indexes created for the sales table include:

- `idx_sales_status`
- `idx_sales_category`
- `idx_sales_date`
- `idx_sales_state`
- `idx_sales_order_month`

---

## 3. Python + SQL Integration

Python was integrated with the SQL database using:

- **SQLAlchemy**
- **Pandas**
- `pandas.read_sql`

A reusable `db_utils.py` module was used throughout the notebook.

### Database Utility Functions

The module provides:

- `get_engine()` – creates and caches the SQLAlchemy database engine
- `run_query()` – executes parameterized SELECT queries and returns Pandas DataFrames
- `execute()` – executes non-SELECT SQL statements
- `explain()` – runs `EXPLAIN QUERY PLAN`
- `table_exists()` – verifies that required database tables exist

The database uses SQLite by default, with the connection configurable through the `DATABASE_URL` environment variable.

---

## 4. Parameterized SQL Queries

Parameterized SQL queries were used instead of directly inserting values into SQL strings.

## Key Business Insights

The SQL analysis was used to extract the following business insights:

- Identified monthly sales and revenue trends and compared average order values across months.
- Identified the top 10 revenue-generating shipping locations using city and postal code.
- Calculated a location-based retention rate by identifying shipping locations with orders across multiple weeks.
- Compared product categories based on order volume, units sold, total revenue, average order value, and revenue contribution.
- Calculated daily revenue, a 7-day moving average, and cumulative revenue to analyze sales trends over time.
- Identified orders above the overall average order value and compared their distribution across categories.
- Identified high-volume, high-value shipping states using order-count and average-order-value thresholds.
- Created a reusable SQL view for monthly category revenue analysis.
- Used EXPLAIN QUERY PLAN to examine index usage and query performance.

## Author
Data Analytics Intern — ApexPlanet Software Pvt. Ltd. Internship (45-Day Program)
