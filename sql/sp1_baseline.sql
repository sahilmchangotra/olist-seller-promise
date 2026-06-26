-- ====================================================================================
-- OLIST Seller Promise — SP1: Seller Delivery Baseline
-- Sahil Changotra | June 2026
-- Questions:
--   Q1: Seller performance profile by incentive tier
--   Q2: Monthly on-time rate by incentive tier
--   Q3: Freight efficiency analysis
-- ====================================================================================

-- SP1 Q1 — Seller Performance by Incentive Tier

WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
seller_base AS (
    SELECT
        s.seller_id,
        s.incentive_tier,
        s.incentive_earned,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(AVG(s.freight_subsidy_pct), 2) AS avg_freight_subsidy,
        AVG(COUNT(DISTINCT o.order_id)) OVER (PARTITION BY s.incentive_tier) AS tier_avg_orders
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id, s.incentive_tier, s.incentive_earned
)
SELECT
    seller_id,
    incentive_tier,
    incentive_earned,
    on_time_rate,
    total_orders,
    avg_freight_subsidy,
    AVG(on_time_rate) OVER (PARTITION BY incentive_tier) AS tier_avg_on_time_rate,
    ROUND(on_time_rate - AVG(on_time_rate) OVER (PARTITION BY incentive_tier), 2) AS gap_vs_tier_avg
FROM seller_base
ORDER BY on_time_rate ASC;


-- SP1 Q2 — Monthly On-Time Rate by Incentive Tier
WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
monthly_base AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        s.incentive_tier,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp), s.incentive_tier
)
SELECT
    month,
    incentive_tier,
    on_time_rate,
    ROUND(LAG(on_time_rate) OVER (PARTITION BY incentive_tier ORDER BY month), 2) AS prev_month_rate,
    ROUND(on_time_rate - LAG(on_time_rate) OVER (PARTITION BY incentive_tier ORDER BY month), 2) AS mom_change
FROM monthly_base
ORDER BY month, incentive_tier;


-- SP1 Q3 — Freight Efficiency by Seller

WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
)
SELECT
    s.seller_id,
    s.incentive_tier,
    ROUND(COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
    ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate,
    ROUND(SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0) * 100, 2) AS freight_pct,
    CASE
        WHEN SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0) * 100 < 15 THEN 'Efficient'
        WHEN SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0) * 100 <= 25 THEN 'Acceptable'
        ELSE 'Inefficient'
    END AS freight_efficiency
FROM kaggle.olist_orders o
JOIN seller_orders os ON o.order_id = os.order_id
JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
JOIN kaggle.olist_order_items oi ON oi.order_id = o.order_id AND oi.seller_id = os.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.incentive_tier
HAVING COUNT(DISTINCT o.order_id) >= 5;