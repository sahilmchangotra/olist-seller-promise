-- ========================================================================================
-- OLIST Seller Promise — SP2: Time-Based Revenue Analysis
-- Sahil Changotra | June 2026
-- Questions:
--   Q1: Monthly revenue with YoY comparison (LAG 12)
--   Q2: Weekday vs weekend revenue pattern
--   Q3: 7-day and 30-day rolling averages
--   Q4: Holiday season impact analysis
-- ========================================================================================

-- SP2 Q1 — Monthly Revenue with YoY

WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS avg_order_value
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    month,
    total_revenue,
    total_orders,
    avg_order_value,
    ROUND(LAG(total_revenue, 12) OVER (ORDER BY month), 2) AS revenue_same_month_last_year,
    ROUND(total_revenue - LAG(total_revenue, 12) OVER (ORDER BY month), 2) AS yoy_change
FROM monthly_revenue
ORDER BY month;


-- SP2 Q2 — Weekday vs Weekend Revenue

WITH daily_orders AS (
    SELECT
        DATE(o.order_purchase_timestamp) AS order_date,
        EXTRACT(DOW FROM o.order_purchase_timestamp) AS day_of_week,
        CASE
            WHEN EXTRACT(DOW FROM o.order_purchase_timestamp) IN (0, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM kaggle.olist_orders o
    JOIN kaggle.olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE(o.order_purchase_timestamp),
             EXTRACT(DOW FROM o.order_purchase_timestamp)
)
SELECT
    day_of_week,
    day_type,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_revenue), 2) AS avg_revenue
FROM daily_orders
GROUP BY day_of_week, day_type
ORDER BY day_of_week;


-- SP2 Q3 — 7 and 30 Day Rolling Averages

WITH daily_orders AS (
    SELECT
        DATE(o.order_purchase_timestamp) AS order_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM kaggle.olist_orders o
    JOIN kaggle.olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE(o.order_purchase_timestamp)
)
SELECT
    order_date,
    total_orders,
    total_revenue,
    ROUND(AVG(total_orders) OVER (
        ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7d_orders,
    ROUND(AVG(total_orders) OVER (
        ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS rolling_30d_orders,
    ROUND(AVG(total_revenue) OVER (
        ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7d_revenue,
    ROUND(AVG(total_revenue) OVER (
        ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS rolling_30d_revenue
FROM daily_orders
ORDER BY order_date;


-- Q4: Holiday Season Impact Analysis

WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
holiday_base AS (
    SELECT
        CASE
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (1, 2)
                THEN EXTRACT(YEAR FROM o.order_purchase_timestamp) - 1
            ELSE EXTRACT(YEAR FROM o.order_purchase_timestamp)
        END AS cycle_year,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9, 10)
                THEN 'Pre-Holiday'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (11, 12)
                THEN 'Holiday'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (1, 2)
                THEN 'Post-Holiday'
        END AS period,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_revenue,
        ROUND(AVG(oi.price), 2) AS avg_order_value,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    AND EXTRACT(YEAR FROM o.order_purchase_timestamp) != 2016
    AND EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (1, 2, 9, 10, 11, 12)
    GROUP BY 1, 2
)
SELECT
    cycle_year,
    period,
    total_orders,
    total_revenue,
    avg_order_value,
    on_time_rate
FROM holiday_base
WHERE period IS NOT NULL
ORDER BY cycle_year,
    CASE period
        WHEN 'Pre-Holiday' THEN 1
        WHEN 'Holiday' THEN 2
        WHEN 'Post-Holiday' THEN 3
    END;

