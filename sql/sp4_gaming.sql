-- ========================================================================================
-- OLIST Seller Promise — SP4: Gaming Detection & Incentives
-- Sahil Changotra | June 2026
-- Questions:
--   Q1: Sellers earning incentives with low on-time rate
--   Q2: Zero delivery sellers with incentive earned
--   Q3: Freight subsidy vs on-time rate correlation
-- ========================================================================================

-- SP4 Q1 — Gaming Detection

WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
seller_incentives AS (
    SELECT
        s.seller_id,
        s.incentive_tier,
        s.incentive_earned,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE s.incentive_earned = TRUE
    AND o.order_status = 'delivered'
    GROUP BY s.seller_id, s.incentive_tier, s.incentive_earned
)
SELECT
    seller_id,
    incentive_tier,
    on_time_rate,
    total_orders,
    ROUND(AVG(on_time_rate) OVER (PARTITION BY incentive_tier), 2) AS tier_avg_on_time_rate,
    ROUND(on_time_rate - AVG(on_time_rate) OVER (PARTITION BY incentive_tier), 2) AS gap_vs_tier_avg
FROM seller_incentives
ORDER BY on_time_rate ASC;


-- Q2: Zero Delivery Sellers with Incentive Earned


WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
seller_base AS (
    SELECT
        s.seller_id,
        s.incentive_tier,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_status = 'delivered'
        ) AS total_delivered,
        ROUND(s.freight_subsidy_pct, 2) AS freight_subsidy_pct,
        ROUND(s.freight_subsidy_pct, 2) * COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_status = 'delivered'
        ) AS estimated_payout_risk
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE s.incentive_earned = TRUE
    GROUP BY s.seller_id, s.incentive_tier, s.freight_subsidy_pct
)
SELECT *
FROM seller_base
WHERE on_time_rate = 0
ORDER BY estimated_payout_risk DESC;


-- Q3: Freight Subsidy Tier vs On-Time Rate Correlation


WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
seller_base AS (
    SELECT
        s.seller_id,
        ROUND(COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date <= o.order_estimated_delivery_date
        ) * 100.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS on_time_rate,
        ROUND(s.freight_subsidy_pct, 2) AS freight_subsidy_pct
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE o.order_status = 'delivered'
    AND s.incentive_earned = TRUE
    GROUP BY s.seller_id, s.freight_subsidy_pct
)
SELECT
    CASE
        WHEN freight_subsidy_pct > 14 THEN 'High'
        WHEN freight_subsidy_pct BETWEEN 7 AND 14 THEN 'Medium'
        WHEN freight_subsidy_pct < 7 THEN 'Low'
    END AS subsidy_tier,
    COUNT(DISTINCT seller_id) AS seller_count,
    ROUND(AVG(on_time_rate), 2) AS avg_on_time_rate,
    ROUND(AVG(freight_subsidy_pct), 2) AS avg_freight_subsidy_pct
FROM seller_base
GROUP BY 1
ORDER BY avg_freight_subsidy_pct DESC;