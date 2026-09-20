-- =====================================================================
-- ApexPlanet Data Analytics Internship — Task 2: SQL & Data Extraction
-- Database: amazon_sales.db (SQLite)  |  Table: orders (128,942 rows)
-- =====================================================================


-- =====================================================================
-- SECTION 0: VIEWS (created up front so later queries can reference them)
-- =====================================================================

DROP VIEW IF EXISTS monthly_category_sales;
CREATE VIEW monthly_category_sales AS
SELECT order_month, category,
       COUNT(*) AS order_count,
       SUM(qty) AS units_sold,
       ROUND(SUM(amount), 2) AS total_revenue
FROM orders
WHERE amount > 0
GROUP BY order_month, category;

DROP VIEW IF EXISTS state_performance;
CREATE VIEW state_performance AS
SELECT ship_state,
       COUNT(*) AS order_count,
       ROUND(SUM(amount), 2) AS total_revenue,
       ROUND(AVG(amount), 2) AS avg_order_value,
       ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
GROUP BY ship_state;

DROP VIEW IF EXISTS daily_sales_summary;
CREATE VIEW daily_sales_summary AS
SELECT order_day,
       COUNT(*) AS order_count,
       ROUND(SUM(amount), 2) AS total_revenue
FROM orders
WHERE amount > 0
GROUP BY order_day;


-- =====================================================================
-- SECTION 1: SQL FUNDAMENTALS
-- =====================================================================

-- 1.1 SELECT / WHERE / ORDER BY / LIMIT --------------------------------
-- Ten most recent, highest-value orders that were actually delivered
SELECT order_id, date, category, amount, ship_state
FROM orders
WHERE status = 'Shipped - Delivered to Buyer'
ORDER BY amount DESC, date DESC
LIMIT 10;

-- 1.2 WHERE with multiple conditions -----------------------------------
-- High-value B2B orders in Karnataka
SELECT order_id, date, category, amount, ship_city
FROM orders
WHERE b2b = 1
  AND ship_state = 'KARNATAKA'
  AND amount > 1000
ORDER BY amount DESC;

-- 1.3 JOIN examples -------------------------------------------------------
-- SQLite note: this dataset is a single flat table (one row per order line),
-- so there is no natural second table to join against. To demonstrate JOIN
-- syntax as required, we self-join `orders` to compare each order against
-- other orders of the same SKU shipped to the same state (e.g. to spot
-- repeat SKU demand in a region).

-- INNER JOIN: pairs of different orders for the same SKU & state
SELECT a.order_id AS order_a, b.order_id AS order_b,
       a.sku, a.ship_state, a.amount AS amount_a, b.amount AS amount_b
FROM orders a
INNER JOIN orders b
    ON a.sku = b.sku
   AND a.ship_state = b.ship_state
   AND a.order_id < b.order_id
WHERE a.ship_state = 'DELHI'
LIMIT 10;

-- LEFT JOIN: every category, plus any matching monthly summary rows
-- from the aggregated `monthly_category_sales` view (see Section 3)
SELECT c.category, m.order_month, m.total_revenue
FROM (SELECT DISTINCT category FROM orders) c
LEFT JOIN monthly_category_sales m
    ON c.category = m.category
ORDER BY c.category, m.order_month
LIMIT 20;

-- 1.4 GROUP BY / HAVING / aggregate functions ----------------------------
-- Categories with more than 500 cancelled orders
SELECT category,
       COUNT(*) AS cancelled_orders,
       ROUND(SUM(amount), 2) AS lost_revenue
FROM orders
WHERE status = 'Cancelled'
GROUP BY category
HAVING COUNT(*) > 500
ORDER BY cancelled_orders DESC;

-- Aggregate summary per fulfilment type
SELECT fulfilment,
       COUNT(*) AS order_count,
       SUM(qty) AS total_units,
       ROUND(AVG(amount), 2) AS avg_order_value,
       ROUND(MIN(amount), 2) AS min_order_value,
       ROUND(MAX(amount), 2) AS max_order_value
FROM orders
GROUP BY fulfilment;

-- 1.5 Subqueries and CTEs (WITH clause) -----------------------------------
-- Orders priced above the overall average order value (subquery)
SELECT order_id, category, amount
FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders WHERE amount > 0)
ORDER BY amount DESC
LIMIT 10;

-- CTE: revenue per state, then filter to top-quartile states
WITH state_revenue AS (
    SELECT ship_state, SUM(amount) AS revenue
    FROM orders
    WHERE amount > 0
    GROUP BY ship_state
),
ranked AS (
    SELECT ship_state, revenue,
           NTILE(4) OVER (ORDER BY revenue DESC) AS quartile
    FROM state_revenue
)
SELECT ship_state, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE quartile = 1
ORDER BY revenue DESC;

-- 1.6 Window functions (ROW_NUMBER, RANK, LAG, LEAD) -----------------------
-- Rank each order's amount within its own category
SELECT order_id, category, amount,
       ROW_NUMBER() OVER (PARTITION BY category ORDER BY amount DESC) AS row_num,
       RANK()       OVER (PARTITION BY category ORDER BY amount DESC) AS rank_num
FROM orders
WHERE amount > 0
LIMIT 20;

-- Day-over-day change in daily revenue using LAG
WITH daily AS (
    SELECT order_day, SUM(amount) AS daily_revenue
    FROM orders
    WHERE amount > 0
    GROUP BY order_day
)
SELECT order_day,
       ROUND(daily_revenue, 2) AS daily_revenue,
       ROUND(LAG(daily_revenue) OVER (ORDER BY order_day), 2) AS prev_day_revenue,
       ROUND(daily_revenue - LAG(daily_revenue) OVER (ORDER BY order_day), 2) AS day_over_day_change
FROM daily
ORDER BY order_day
LIMIT 20;


-- =====================================================================
-- SECTION 2: ADVANCED SQL — BUSINESS QUESTIONS
-- =====================================================================

-- 2.1 Monthly sales trend --------------------------------------------------
SELECT order_month,
       COUNT(*) AS order_count,
       SUM(qty) AS units_sold,
       ROUND(SUM(amount), 2) AS total_revenue,
       ROUND(AVG(amount), 2) AS avg_order_value
FROM orders
WHERE amount > 0
GROUP BY order_month
ORDER BY order_month;

-- 2.2 Top 10 "customers" by revenue -----------------------------------------
-- NOTE: this dataset has no customer ID field (order-level export only).
-- As a documented adaptation, we use shipping city + state as the closest
-- available proxy for a "customer location" grouping.
SELECT ship_city, ship_state,
       COUNT(*) AS order_count,
       ROUND(SUM(amount), 2) AS total_revenue
FROM orders
WHERE amount > 0
GROUP BY ship_city, ship_state
ORDER BY total_revenue DESC
LIMIT 10;

-- 2.3 Customer retention rate ------------------------------------------------
-- NOTE: true customer retention cannot be computed without a customer ID.
-- As a documented proxy, we measure "SKU repeat-order rate": the share of
-- SKUs that were ordered more than once, as a rough demand-repetition signal.
WITH sku_orders AS (
    SELECT sku, COUNT(*) AS order_count
    FROM orders
    GROUP BY sku
)
SELECT
    COUNT(*) AS total_skus,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_skus,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_sku_rate_pct
FROM sku_orders;

-- 2.4 Product category performance --------------------------------------------
SELECT category,
       COUNT(*) AS order_count,
       SUM(qty) AS units_sold,
       ROUND(SUM(amount), 2) AS total_revenue,
       ROUND(AVG(amount), 2) AS avg_order_value,
       ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;

-- 2.5 Moving averages and cumulative sums --------------------------------------
WITH daily AS (
    SELECT order_day, SUM(amount) AS daily_revenue
    FROM orders
    WHERE amount > 0
    GROUP BY order_day
)
SELECT order_day,
       ROUND(daily_revenue, 2) AS daily_revenue,
       ROUND(AVG(daily_revenue) OVER (
           ORDER BY order_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_7day_avg,
       ROUND(SUM(daily_revenue) OVER (
           ORDER BY order_day ROWS UNBOUNDED PRECEDING
       ), 2) AS cumulative_revenue
FROM daily
ORDER BY order_day;


-- =====================================================================
-- SECTION 3: VIEWS FOR FREQUENTLY USED QUERIES
-- =====================================================================
-- (Views were created up front in Section 0 so earlier queries in this
--  file could reference them. Example usage shown below.)

-- Example usage of the views:
-- SELECT * FROM monthly_category_sales ORDER BY order_month, total_revenue DESC;
-- SELECT * FROM state_performance ORDER BY total_revenue DESC LIMIT 10;
-- SELECT * FROM daily_sales_summary ORDER BY order_day;


-- =====================================================================
-- SECTION 4: QUERY OPTIMIZATION
-- =====================================================================

-- Inspect the query plan for a common filter+aggregate query
EXPLAIN QUERY PLAN
SELECT category, SUM(amount)
FROM orders
WHERE ship_state = 'MAHARASHTRA'
GROUP BY category;

-- Add indexes on columns used heavily in WHERE/GROUP BY/JOIN clauses
CREATE INDEX IF NOT EXISTS idx_orders_ship_state ON orders(ship_state);
CREATE INDEX IF NOT EXISTS idx_orders_category    ON orders(category);
CREATE INDEX IF NOT EXISTS idx_orders_order_month ON orders(order_month);
CREATE INDEX IF NOT EXISTS idx_orders_sku         ON orders(sku);
CREATE INDEX IF NOT EXISTS idx_orders_status      ON orders(status);

-- Re-check the query plan after indexing (should now show a SEARCH
-- using idx_orders_ship_state instead of a full SCAN)
EXPLAIN QUERY PLAN
SELECT category, SUM(amount)
FROM orders
WHERE ship_state = 'MAHARASHTRA'
GROUP BY category;
