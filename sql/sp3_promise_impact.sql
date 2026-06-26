-- ============================================================
-- OLIST Seller Promise — SP3: Seller Promise Change Impact
-- Sahil Changotra | June 2026
-- Questions:
--   Q1: Before vs after on-time delivery rate by seller
--   Q2: Promise direction vs customer review score
--   Q3: Diff-in-Diff A/B test simulation
-- ============================================================

-- Q1: Before vs After On-Time Delivery Rate by Seller
WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
)
SELECT
    s.seller_id,
    s.incentive_tier,
    s.promise_days_before,
    s.promise_days_after,
    s.promise_days_after - s.promise_days_before AS promise_change,
    CASE
        WHEN s.promise_days_after - s.promise_days_before < 0 THEN 'Tightened'
        WHEN s.promise_days_after - s.promise_days_before > 0 THEN 'Loosened'
        ELSE 'Unchanged'
    END AS promise_direction,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_purchase_timestamp < s.promise_change_date
    ) AS total_orders_before,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_purchase_timestamp >= s.promise_change_date
    ) AS total_orders_after,
    ROUND(COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_purchase_timestamp < s.promise_change_date
        AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
    ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_purchase_timestamp < s.promise_change_date
    ), 0), 2) AS on_time_rate_before,
    ROUND(COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_purchase_timestamp >= s.promise_change_date
        AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
    ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_purchase_timestamp >= s.promise_change_date
    ), 0), 2) AS on_time_rate_after
FROM kaggle.olist_orders o
JOIN seller_orders os ON o.order_id = os.order_id
JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.incentive_tier, s.promise_days_before,
         s.promise_days_after, s.promise_change_date
HAVING COUNT(DISTINCT o.order_id) FILTER (
    WHERE o.order_purchase_timestamp < s.promise_change_date
) >= 5
AND COUNT(DISTINCT o.order_id) FILTER (
    WHERE o.order_purchase_timestamp >= s.promise_change_date
) >= 5
ORDER BY (on_time_rate_after - on_time_rate_before) ASC;

-- Q2: Promise Direction vs Customer Review Score
WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
)
SELECT
    CASE
        WHEN s.promise_days_after - s.promise_days_before < 0 THEN 'Tightened'
        WHEN s.promise_days_after - s.promise_days_before > 0 THEN 'Loosened'
        ELSE 'Unchanged'
    END AS promise_direction,
    ROUND(AVG(r.review_score) FILTER (
        WHERE o.order_purchase_timestamp < s.promise_change_date
    ), 2) AS avg_review_before,
    ROUND(AVG(r.review_score) FILTER (
        WHERE o.order_purchase_timestamp >= s.promise_change_date
    ), 2) AS avg_review_after,
    ROUND(AVG(r.review_score) FILTER (
        WHERE o.order_purchase_timestamp >= s.promise_change_date
    ) - AVG(r.review_score) FILTER (
        WHERE o.order_purchase_timestamp < s.promise_change_date
    ), 2) AS review_change,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM kaggle.olist_orders o
JOIN seller_orders os ON o.order_id = os.order_id
JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
JOIN kaggle.olist_order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY avg_review_after DESC;

-- SP3 Q3 — Diff-in-Diff Results

WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
seller_base AS (
    SELECT
        s.seller_id,
        s.treatment_group,
        s.promise_change_date,
        DATE(o.order_delivered_customer_date) - DATE(o.order_estimated_delivery_date) AS days_gap,
        CASE
            WHEN o.order_purchase_timestamp >= s.promise_change_date THEN 'recent'
            WHEN o.order_purchase_timestamp < s.promise_change_date THEN 'prior'
        END AS period,
        CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1
            ELSE 0
        END AS on_time
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE o.order_status = 'delivered'
),
did_base AS (
    SELECT
        treatment_group,
        ROUND(AVG(on_time) FILTER (WHERE period = 'prior') * 100, 2) AS on_time_rate_before,
        ROUND(AVG(on_time) FILTER (WHERE period = 'recent') * 100, 2) AS on_time_rate_after,
        ROUND((AVG(on_time) FILTER (WHERE period = 'recent') -
               AVG(on_time) FILTER (WHERE period = 'prior')) * 100, 2) AS change
    FROM seller_base
    GROUP BY treatment_group
)
SELECT * FROM did_base
UNION ALL
SELECT
    'diff_in_diff' AS treatment_group,
    NULL AS on_time_rate_before,
    NULL AS on_time_rate_after,
    ROUND(
        (MAX(on_time_rate_after) FILTER (WHERE treatment_group = 'treated') -
         MAX(on_time_rate_before) FILTER (WHERE treatment_group = 'treated')) -
        (MAX(on_time_rate_after) FILTER (WHERE treatment_group = 'control') -
         MAX(on_time_rate_before) FILTER (WHERE treatment_group = 'control')), 2) AS change
FROM did_base;