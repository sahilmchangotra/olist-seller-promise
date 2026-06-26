-- ==============================================================================
-- OLIST Seller Promise — SP6: Financial Analytics
-- Sahil Changotra | June 2026
-- Questions:
--   Q1: Seller revenue, freight cost and efficiency analysis
--   Q2: Pareto revenue concentration by seller rank
-- ==============================================================================


-- SP6 Q1 — Seller Financial Analytics

WITH seller_orders AS (
    SELECT
        DISTINCT order_id,
        seller_id,
        SUM(price) AS order_value,
        SUM(freight_value) AS freight_cost
    FROM kaggle.olist_order_items
    GROUP BY order_id, seller_id
)
SELECT
    s.seller_id,
    s.incentive_tier,
    ROUND(SUM(os.order_value), 2) AS total_revenue,
    ROUND(SUM(os.freight_cost), 2) AS total_freight,
    ROUND(SUM(os.freight_cost) * 100.0 / NULLIF(SUM(os.order_value), 0), 2) AS freight_pct,
    ROUND(SUM(os.order_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    CASE
        WHEN SUM(os.freight_cost) * 100.0 / NULLIF(SUM(os.order_value), 0) > 30
        THEN 'Inefficient'
        ELSE 'Efficient'
    END AS freight_efficiency
FROM kaggle.olist_orders o
JOIN seller_orders os ON o.order_id = os.order_id
JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.incentive_tier
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY freight_pct DESC;


-- SP6 Q2 — Pareto Revenue Concentration


WITH seller_orders AS (
    SELECT DISTINCT order_id, seller_id,
        SUM(price) AS order_value
    FROM kaggle.olist_order_items
    GROUP BY order_id, seller_id
),
seller_base AS (
    SELECT
        os.seller_id,
        SUM(os.order_value) AS total_revenue,
        SUM(os.order_value) * 100.0 / SUM(SUM(os.order_value)) OVER () AS revenue_pct
    FROM kaggle.olist_orders o
    JOIN seller_orders os ON o.order_id = os.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY os.seller_id
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC) AS seller_rank,
    seller_id,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(revenue_pct, 2) AS revenue_pct,
    ROUND(SUM(revenue_pct) OVER (
        ORDER BY total_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue_pct
FROM seller_base
ORDER BY seller_rank;