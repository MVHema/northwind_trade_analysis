-- ================================================
-- PROJECT: Northwind International Trade Analysis
-- Tool: PostgreSQL 15 / DB Fiddle
-- Author: Venkata Hema Muddala
-- Date: 2026
-- Description: Business analysis of the classic Northwind
--              international food and beverage trading database
--              covering customer behaviour, revenue trends,
--              product performance and employee efficiency
-- ================================================

-- ================================================
-- DATABASE SCHEMA
-- ================================================
-- customers
-- orders
-- order_details
-- products
-- employees
-- categories
-- suppliers
-- shippers
-- customer_customer_demo
-- customer_demographics
-- employee_territories
-- territories
-- region
-- us_states

-- ================================================
-- KEY TABLE COLUMNS
-- ================================================
-- customers      (customer_id, company_name, contact_name, city, country)
-- orders         (order_id, customer_id, employee_id, order_date, ship_via, freight, ...)
-- order_details  (order_id, product_id, unit_price, quantity, discount)
-- products       (product_id, product_name, supplier_id, category_id, unit_price, units_in_stock, ...)
-- employees      (employee_id, last_name, first_name, hire_date, reports_to, ...)
-- categories     (category_id, category_name, description)
-- suppliers      (supplier_id, company_name, contact_name, city, country, ...)
-- shippers       (shipper_id, company_name, phone)

-- ================================================
-- TABLE RELATIONSHIPS
-- ================================================
-- customers.customer_id       -> orders.customer_id
-- orders.order_id             -> order_details.order_id
-- products.product_id         -> order_details.product_id
-- products.category_id        -> categories.category_id
-- products.supplier_id        -> suppliers.supplier_id
-- orders.employee_id          -> employees.employee_id
-- orders.ship_via             -> shippers.shipper_id
-- employees.employee_id       -> employee_territories.employee_id
-- employee_territories.territory_id -> territories.territory_id
-- territories.region_id       -> region.region_id
-- customer_customer_demo.customer_id -> customers.customer_id
-- customer_customer_demo.customer_type_id -> customer_demographics.customer_type_id

-- ================================================================
-- REVENUE DEFINITION USED IN THIS PROJECT
-- ================================================================
-- Net line revenue = unit_price * quantity * (1 - discount)
-- Northwind stores discount as a decimal fraction (for example 0.10 = 10%).


-- ================================================
-- SECTION 1: CUSTOMER ANALYSIS
-- ================================================

-- Q1: Customer distribution across countries
-- Approach: GROUP BY country with COUNT, sorted descending
SELECT country,
       COUNT(*) AS customer_count
FROM customers
GROUP BY country
ORDER BY customer_count DESC, country;


-- Q2: Customers who have never placed an order
-- Approach: LEFT JOIN + IS NULL pattern
SELECT c.customer_id,
       c.company_name,
       c.contact_name,
       c.country
FROM customers c
LEFT JOIN orders o
       ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.company_name;


-- Q3: Top 10 customers by total order value
-- Approach: JOIN customers -> orders -> order_details,
--           aggregate net revenue, rank customers by spending
WITH customer_spending AS (
    SELECT c.customer_id,
           c.company_name,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
    FROM customers c
    INNER JOIN orders o
            ON c.customer_id = o.customer_id
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.company_name
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM customer_spending
)
SELECT customer_id,
       company_name,
       ROUND(total_spent::numeric, 2) AS total_spent,
       spending_rank
FROM ranked
WHERE spending_rank <= 10
ORDER BY spending_rank, company_name;


-- Q4: Average number of orders per customer
-- Approach: Build customer-level order counts first,
--           then calculate the average across all customers
WITH customer_orders AS (
    SELECT c.customer_id,
           COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    LEFT JOIN orders o
           ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT ROUND(AVG(total_orders)::numeric, 2) AS avg_orders_per_customer
FROM customer_orders;


-- Q5: Customers active in 1997 but not in 1998
-- Approach: Set operation using EXCEPT
WITH active_1997 AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE order_date >= DATE '1997-01-01'
      AND order_date <  DATE '1998-01-01'
),
active_1998 AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE order_date >= DATE '1998-01-01'
      AND order_date <  DATE '1999-01-01'
)
SELECT c.customer_id,
       c.company_name,
       c.country
FROM (
    SELECT customer_id FROM active_1997
    EXCEPT
    SELECT customer_id FROM active_1998
) x
INNER JOIN customers c
        ON c.customer_id = x.customer_id
ORDER BY c.company_name;


-- ================================================
-- SECTION 2: REVENUE ANALYSIS
-- ================================================

-- Q6: Annual revenue comparison from 1996 to 1998
-- Approach: EXTRACT year, aggregate net revenue by year
SELECT EXTRACT(YEAR FROM o.order_date)::integer AS order_year,
       ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric, 2) AS annual_revenue
FROM orders o
INNER JOIN order_details od
        ON o.order_id = od.order_id
WHERE o.order_date >= DATE '1996-01-01'
  AND o.order_date <  DATE '1999-01-01'
GROUP BY order_year
ORDER BY order_year;


-- Q7: Monthly revenue trend with running total
-- Approach: Aggregate monthly revenue first, then SUM() OVER
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date)::date AS month,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monthly_revenue
    FROM orders o
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    GROUP BY month
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month,
       ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
       ROUND(
           SUM(monthly_revenue) OVER (ORDER BY month)::numeric,
           2
       ) AS running_total
FROM monthly
ORDER BY month;


-- Q8: Month-over-month revenue growth for 1997
-- Approach: LAG to get previous month revenue,
--           then calculate percentage growth
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date)::date AS month,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monthly_revenue
    FROM orders o
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    WHERE o.order_date >= DATE '1997-01-01'
      AND o.order_date <  DATE '1998-01-01'
    GROUP BY month
),
previous_month AS (
    SELECT month,
           monthly_revenue,
           LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue
    FROM monthly
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month,
       ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
       ROUND(prev_month_revenue::numeric, 2) AS prev_month_revenue,
       ROUND(
           (((monthly_revenue - prev_month_revenue) /
             NULLIF(prev_month_revenue, 0)) * 100)::numeric,
           2
       ) AS mom_growth_pct
FROM previous_month
WHERE prev_month_revenue IS NOT NULL
ORDER BY month;


-- Q9: Revenue breakdown by customer country
-- Approach: JOIN customers to orders and order_details,
--           then calculate each country's share of total revenue
WITH country_revenue AS (
    SELECT c.country,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM customers c
    INNER JOIN orders o
            ON c.customer_id = o.customer_id
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    GROUP BY c.country
)
SELECT country,
       ROUND(total_revenue::numeric, 2) AS total_revenue,
       ROUND(
           (total_revenue / NULLIF((SELECT SUM(total_revenue)
                                   FROM country_revenue), 0) * 100)::numeric,
           2
       ) AS pct_of_total
FROM country_revenue
ORDER BY total_revenue DESC;


-- Q10: Peak revenue month across the full dataset
-- Approach: Aggregate by month, sort revenue descending, return top month
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date)::date AS month,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monthly_revenue
    FROM orders o
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    GROUP BY month
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month,
       ROUND(monthly_revenue::numeric, 2) AS monthly_revenue
FROM monthly
ORDER BY monthly_revenue DESC
LIMIT 1;


-- ================================================
-- SECTION 3: PRODUCT ANALYSIS
-- ================================================

-- Q11: Top 10 revenue-generating products
-- Approach: JOIN products to order_details,
--           calculate net product revenue and sort descending
SELECT p.product_id,
       p.product_name,
       ROUND(
           SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric,
           2
       ) AS total_revenue
FROM products p
INNER JOIN order_details od
        ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;


-- Q12: Products that have never been ordered
-- Approach: LEFT JOIN + IS NULL
SELECT p.product_id,
       p.product_name,
       c.category_name
FROM products p
LEFT JOIN order_details od
       ON p.product_id = od.product_id
LEFT JOIN categories c
       ON p.category_id = c.category_id
WHERE od.product_id IS NULL
ORDER BY p.product_name;


-- Q13: Best-selling product in each category
-- Approach: Aggregate product revenue, then RANK within category
WITH product_revenue AS (
    SELECT p.product_id,
           p.product_name,
           c.category_name,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM products p
    INNER JOIN categories c
            ON p.category_id = c.category_id
    INNER JOIN order_details od
            ON p.product_id = od.product_id
    GROUP BY p.product_id, p.product_name, c.category_name
),
ranked AS (
    SELECT *,
           RANK() OVER (
               PARTITION BY category_name
               ORDER BY total_revenue DESC
           ) AS category_rank
    FROM product_revenue
)
SELECT product_name,
       category_name,
       ROUND(total_revenue::numeric, 2) AS total_revenue,
       category_rank
FROM ranked
WHERE category_rank = 1
ORDER BY category_name, product_name;


-- Q14: Most frequently bought-together product pairs
-- Approach: Self JOIN order_details on the same order,
--           product_id < product_id prevents duplicate/reversed pairs
SELECT p1.product_name AS product_1,
       p2.product_name AS product_2,
       COUNT(*) AS times_bought_together
FROM order_details a
INNER JOIN order_details b
        ON a.order_id = b.order_id
       AND a.product_id < b.product_id
INNER JOIN products p1
        ON a.product_id = p1.product_id
INNER JOIN products p2
        ON b.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC, product_1, product_2;


-- Q15: Each product's revenue as a percentage of category revenue
-- Approach: Two CTEs: product revenue and category revenue
WITH product_revenue AS (
    SELECT p.product_id,
           p.product_name,
           c.category_id,
           c.category_name,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS product_revenue
    FROM products p
    INNER JOIN categories c
            ON p.category_id = c.category_id
    INNER JOIN order_details od
            ON p.product_id = od.product_id
    GROUP BY p.product_id, p.product_name,
             c.category_id, c.category_name
),
category_revenue AS (
    SELECT c.category_id,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS category_revenue
    FROM categories c
    INNER JOIN products p
            ON c.category_id = p.category_id
    INNER JOIN order_details od
            ON p.product_id = od.product_id
    GROUP BY c.category_id
)
SELECT pr.product_name,
       pr.category_name,
       ROUND(pr.product_revenue::numeric, 2) AS product_revenue,
       ROUND(cr.category_revenue::numeric, 2) AS category_revenue,
       ROUND(
           (pr.product_revenue / NULLIF(cr.category_revenue, 0) * 100)::numeric,
           2
       ) AS pct_of_category
FROM product_revenue pr
INNER JOIN category_revenue cr
        ON pr.category_id = cr.category_id
ORDER BY pr.category_name, pct_of_category DESC;


-- ================================================
-- SECTION 4: EMPLOYEE / SALES PERFORMANCE
-- ================================================

-- Q16: Employee with the most orders handled
-- Approach: LEFT JOIN employees to orders,
--           COUNT DISTINCT orders, RANK and return rank 1
WITH employee_orders AS (
    SELECT e.employee_id,
           e.first_name,
           e.last_name,
           COUNT(DISTINCT o.order_id) AS total_orders
    FROM employees e
    LEFT JOIN orders o
           ON e.employee_id = o.employee_id
    GROUP BY e.employee_id, e.first_name, e.last_name
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM employee_orders
)
SELECT employee_id,
       first_name,
       last_name,
       total_orders
FROM ranked
WHERE order_rank = 1;


-- Q17: Revenue and average order value per employee
-- Approach: Calculate order-level revenue first to avoid duplication,
--           then aggregate orders by employee
WITH order_revenue AS (
    SELECT o.order_id,
           o.employee_id,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS order_revenue
    FROM orders o
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    GROUP BY o.order_id, o.employee_id
)
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       COUNT(orv.order_id) AS total_orders,
       ROUND(COALESCE(SUM(orv.order_revenue), 0)::numeric, 2) AS total_revenue,
       ROUND(
           COALESCE(
               SUM(orv.order_revenue) / NULLIF(COUNT(orv.order_id), 0),
               0
           )::numeric,
           2
       ) AS avg_order_value
FROM employees e
LEFT JOIN order_revenue orv
       ON e.employee_id = orv.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_revenue DESC;


-- Q18: Employees performing above average revenue
-- Approach: Build employee revenue, then compare each employee
--           against the average employee revenue
WITH employee_revenue AS (
    SELECT e.employee_id,
           e.first_name,
           e.last_name,
           COALESCE(
               SUM(od.unit_price * od.quantity * (1 - od.discount)),
               0
           ) AS total_revenue
    FROM employees e
    LEFT JOIN orders o
           ON e.employee_id = o.employee_id
    LEFT JOIN order_details od
           ON o.order_id = od.order_id
    GROUP BY e.employee_id, e.first_name, e.last_name
)
SELECT employee_id,
       first_name,
       last_name,
       ROUND(total_revenue::numeric, 2) AS total_revenue
FROM employee_revenue
WHERE total_revenue > (SELECT AVG(total_revenue) FROM employee_revenue)
ORDER BY total_revenue DESC;


-- ================================================
-- SECTION 5: ADVANCED CUSTOMER ANALYSIS
-- ================================================

-- Q19: Customer first order, last order and days active
-- Approach: Aggregate first/last order dates per customer,
--           then subtract dates in PostgreSQL
SELECT c.customer_id,
       c.company_name,
       MIN(o.order_date) AS first_order_date,
       MAX(o.order_date) AS last_order_date,
       MAX(o.order_date) - MIN(o.order_date) AS days_active
FROM customers c
INNER JOIN orders o
        ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.company_name
ORDER BY days_active DESC;


-- Q20: Top 3 spending customers in each country
-- Approach: Customer-level revenue + RANK partitioned by country
WITH customer_spending AS (
    SELECT c.customer_id,
           c.company_name,
           c.country,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
    FROM customers c
    INNER JOIN orders o
            ON c.customer_id = o.customer_id
    INNER JOIN order_details od
            ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.company_name, c.country
),
ranked AS (
    SELECT *,
           RANK() OVER (
               PARTITION BY country
               ORDER BY total_spent DESC
           ) AS country_rank
    FROM customer_spending
)
SELECT country,
       company_name,
       ROUND(total_spent::numeric, 2) AS total_spent,
       country_rank
FROM ranked
WHERE country_rank <= 3
ORDER BY country, country_rank, company_name;


-- ================================================
-- OPTIONAL DATA QUALITY CHECKS
-- ================================================

-- Q21: Orders with missing customer or employee assignments
-- Approach: NULL checks on foreign-key columns
SELECT order_id,
       customer_id,
       employee_id,
       order_date
FROM orders
WHERE customer_id IS NULL
   OR employee_id IS NULL
ORDER BY order_id;


-- Q22: Products currently marked as discontinued
-- Approach: Filter discontinued flag
SELECT product_id,
       product_name,
       unit_price,
       units_in_stock,
       discontinued
FROM products
WHERE discontinued <> 0
ORDER BY product_name;


-- ================================================
-- PROJECT SUMMARY
-- ================================================
-- Skills demonstrated:
--   * Multi-table JOINs across 4+ tables
--   * INNER / LEFT JOINs
--   * CTEs
--   * Aggregate functions and GROUP BY
--   * HAVING / NULL handling / COALESCE
--   * Window functions: RANK, LAG, SUM OVER
--   * Window partitioning by country/category
--   * Self JOIN for product-pair analysis
--   * EXISTS / NOT EXISTS patterns
--   * Set operations (EXCEPT)
--   * Correlated subqueries
--   * CASE WHEN / conditional analysis
--   * PostgreSQL date arithmetic and DATE_TRUNC
--   * Revenue calculations with discount adjustment
