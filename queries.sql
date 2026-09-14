-- =====================================================================
-- ApexPlanet Data Analytics Internship - Task 2: SQL & Data Extraction
-- Database: SQLite (data/db/amazon_sales.db)
-- Table:    sales          (128,942 rows, one row per order line)
--           state_region   (lookup table: normalized state -> region)
-- Dialect note: written for SQLite; runs unchanged on Postgres/MySQL,
--               except LIMIT/OFFSET syntax and PRAGMA calls are SQLite-
--               specific (noted inline where relevant).
-- =====================================================================


-- =====================================================================
-- SECTION 1 (Day 9-11): SQL FUNDAMENTALS
-- =====================================================================

-- 1.1 SELECT / WHERE / ORDER BY / LIMIT
-- Ten highest-value shipped orders in the Western Dress category.
SELECT order_id, date, category, qty, amount, ship_state
FROM sales
WHERE category = 'Western Dress'
  AND status LIKE 'Shipped%'
ORDER BY amount DESC
LIMIT 10;


-- 1.2 JOIN: INNER JOIN
-- Every order line matched to its region via the state_region lookup
-- (states not present in the lookup are simply dropped by an INNER JOIN).
SELECT s.order_id, s.ship_state, r.region, s.amount
FROM sales AS s
INNER JOIN state_region AS r
    ON UPPER(TRIM(s.ship_state)) = r.state_norm
LIMIT 20;


-- 1.3 JOIN: LEFT JOIN
-- Same join, but keeping every order even when its state has no region
-- mapping yet (region shows as NULL) -- useful for spotting data-quality
-- gaps in ship_state values.
SELECT s.order_id, s.ship_state, r.region, s.amount
FROM sales AS s
LEFT JOIN state_region AS r
    ON UPPER(TRIM(s.ship_state)) = r.state_norm
WHERE r.region IS NULL
LIMIT 20;


-- 1.4 JOIN: RIGHT JOIN
-- Every region in the lookup, with a NULL order for any region that
-- (hypothetically) had zero matching orders. Included to demonstrate the
-- syntax; with this dataset every region does have matches.
SELECT r.region, r.state_norm, s.order_id
FROM sales AS s
RIGHT JOIN state_region AS r
    ON UPPER(TRIM(s.ship_state)) = r.state_norm
LIMIT 20;


-- 1.5 JOIN: FULL OUTER JOIN
-- Combines LEFT + RIGHT: unmatched orders AND unmatched lookup rows both
-- appear, with NULLs on the side that has no match. (SQLite added FULL
-- JOIN in 3.39+; MySQL has no native FULL JOIN and needs a UNION of a
-- LEFT and RIGHT join instead.)
SELECT s.order_id, s.ship_state, r.region
FROM sales AS s
FULL OUTER JOIN state_region AS r
    ON UPPER(TRIM(s.ship_state)) = r.state_norm
WHERE s.order_id IS NULL OR r.region IS NULL
LIMIT 20;


-- 1.6 GROUP BY + aggregate functions (COUNT, SUM, AVG, MIN, MAX)
SELECT
    category,
    COUNT(*)          AS order_count,
    SUM(qty)           AS total_units,
    ROUND(AVG(amount), 2) AS avg_order_value,
    MIN(amount)        AS min_order_value,
    MAX(amount)        AS max_order_value
FROM sales
WHERE amount > 0
GROUP BY category
ORDER BY order_count DESC;


-- 1.7 GROUP BY + HAVING
-- Shipping states with more than 500 orders AND an average order value
-- above 600 (a "high volume, high value" state segment).
SELECT
    ship_state,
    COUNT(*)               AS order_count,
    ROUND(AVG(amount), 2)  AS avg_order_value
FROM sales
WHERE amount > 0
GROUP BY ship_state
HAVING COUNT(*) > 500 AND AVG(amount) > 600
ORDER BY avg_order_value DESC;


-- 1.8 Subquery
-- Orders priced above the overall average order value.
SELECT order_id, category, amount
FROM sales
WHERE amount > (SELECT AVG(amount) FROM sales WHERE amount > 0)
ORDER BY amount DESC
LIMIT 15;


-- 1.9 CTE (WITH clause)
-- Same "above average" logic, written as a CTE for readability, then
-- broken down by category. (Referencing the CTE via a scalar subquery in
-- WHERE, rather than a comma cross join, keeps SQLite from re-evaluating
-- the average once per row of `sales`.)
WITH overall_avg AS (
    SELECT AVG(amount) AS avg_amount
    FROM sales
    WHERE amount > 0
)
SELECT category, COUNT(*) AS above_avg_orders
FROM sales
WHERE amount > (SELECT avg_amount FROM overall_avg)
GROUP BY category
ORDER BY above_avg_orders DESC;


-- 1.10 Window functions: ROW_NUMBER, RANK, LAG, LEAD
-- For each category, rank orders by amount and show how each order's
-- value compares to the order immediately before/after it in that ranking.
SELECT
    category,
    order_id,
    amount,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY amount DESC) AS row_num,
    RANK()       OVER (PARTITION BY category ORDER BY amount DESC) AS rank_num,
    LAG(amount)  OVER (PARTITION BY category ORDER BY amount DESC) AS prev_amount,
    LEAD(amount) OVER (PARTITION BY category ORDER BY amount DESC) AS next_amount
FROM sales
WHERE amount > 0
ORDER BY category, row_num
LIMIT 30;


-- =====================================================================
-- SECTION 2 (Day 12-14): ADVANCED SQL -- BUSINESS QUESTIONS
-- =====================================================================

-- 2.1 Monthly sales trend
SELECT
    order_month,
    COUNT(*)               AS order_count,
    SUM(amount)             AS total_revenue,
    ROUND(AVG(amount), 2)  AS avg_order_value
FROM sales
WHERE amount > 0
GROUP BY order_month
ORDER BY order_month;


-- 2.2 Top 10 "customers" by revenue
-- NOTE: this Amazon Sale Report export has no customer_id column -- Amazon
-- does not expose one in seller reports. As the closest available proxy,
-- ship_postal_code + ship_city stands in for a "customer/delivery
-- location". Swap in a real customer_id here if your source system has one.
SELECT
    ship_city,
    ship_postal_code,
    COUNT(*)      AS order_count,
    SUM(amount)    AS total_revenue
FROM sales
WHERE amount > 0
GROUP BY ship_city, ship_postal_code
ORDER BY total_revenue DESC
LIMIT 10;


-- 2.3 "Customer" retention rate (proxy, same caveat as 2.2)
-- Share of ship-to locations that ordered in more than one distinct
-- order_week during the period covered by the data.
WITH location_weeks AS (
    SELECT
        ship_city,
        ship_postal_code,
        COUNT(DISTINCT order_week) AS active_weeks
    FROM sales
    WHERE amount > 0
    GROUP BY ship_city, ship_postal_code
)
SELECT
    COUNT(*)                                          AS total_locations,
    SUM(CASE WHEN active_weeks > 1 THEN 1 ELSE 0 END)  AS returning_locations,
    ROUND(
        100.0 * SUM(CASE WHEN active_weeks > 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    )                                                  AS retention_rate_pct
FROM location_weeks;


-- 2.4 Product category performance
SELECT
    category,
    COUNT(*)                                             AS order_count,
    SUM(qty)                                              AS units_sold,
    SUM(amount)                                            AS total_revenue,
    ROUND(AVG(amount), 2)                                 AS avg_order_value,
    ROUND(100.0 * SUM(amount) / (SELECT SUM(amount) FROM sales WHERE amount > 0), 2)
                                                            AS pct_of_total_revenue
FROM sales
WHERE amount > 0
GROUP BY category
ORDER BY total_revenue DESC;


-- 2.5 Moving average and cumulative sum of daily revenue
WITH daily AS (
    SELECT order_day, SUM(amount) AS daily_revenue
    FROM sales
    WHERE amount > 0
    GROUP BY order_day
)
SELECT
    order_day,
    daily_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY order_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)                                            AS revenue_7day_moving_avg,
    SUM(daily_revenue) OVER (
        ORDER BY order_day ROWS UNBOUNDED PRECEDING
    )                                                 AS revenue_cumulative
FROM daily
ORDER BY order_day;


-- 2.6 View for a frequently used query: monthly category revenue
-- (created here for documentation; scripts/load_data.py or the notebook
-- creates it in the live database.)
CREATE VIEW IF NOT EXISTS vw_monthly_category_revenue AS
SELECT
    order_month,
    category,
    COUNT(*)      AS order_count,
    SUM(amount)    AS total_revenue
FROM sales
WHERE amount > 0
GROUP BY order_month, category;

-- Using the view:
-- SELECT * FROM vw_monthly_category_revenue ORDER BY order_month, total_revenue DESC;


-- 2.7 Query optimization: EXPLAIN QUERY PLAN + indexing
-- Run before creating an index on status to see a full table scan (SCAN sales):
EXPLAIN QUERY PLAN
SELECT * FROM sales WHERE status = 'Cancelled';

-- After scripts/load_data.py creates idx_sales_status, the same query plan
-- shows SQLite using that index (SEARCH sales USING INDEX idx_sales_status)
-- instead of scanning all 128,942 rows.
