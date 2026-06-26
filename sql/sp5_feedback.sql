-- =========================================================================================================
-- OLIST Seller Promise — SP5: Customer Feedback & Returns
-- Sahil Changotra | June 2026
-- Questions:
--   Q1: Review score by delivery outcome (Early/On-time/Late)
--   Q2: Seller delivery gap deterioration — early warning signal
--   Q3: Product category review scores & quick review analysis
-- =========================================================================================================

-- SP5 Q1 — Delivery Outcome vs Review Score

SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date) < DATE(o.order_estimated_delivery_date) THEN 'Early'
        WHEN DATE(o.order_delivered_customer_date) = DATE(o.order_estimated_delivery_date) THEN 'On-time'
        WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 'Late'
    END AS delivery_outcome,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM kaggle.olist_orders o
JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM kaggle.olist_order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 1
ORDER BY avg_review_score DESC;


-- Q2: Seller Delivery Gap Deterioration — Early Warning Signal


WITH ref AS (
    SELECT MAX(DATE(order_purchase_timestamp)) AS max_order_date
    FROM kaggle.olist_orders
),
seller_orders AS (
    SELECT DISTINCT order_id, seller_id
    FROM kaggle.olist_order_items
),
seller_base AS (
    SELECT
        s.seller_id,
        DATE(o.order_delivered_customer_date) -
        DATE(o.order_estimated_delivery_date) AS days_gap,
        CASE
            WHEN o.order_purchase_timestamp >= r.max_order_date - INTERVAL '90 days'
                THEN 'recent'
            WHEN o.order_purchase_timestamp >= r.max_order_date - INTERVAL '180 days'
            AND o.order_purchase_timestamp < r.max_order_date - INTERVAL '90 days'
                THEN 'prior'
        END AS period
    FROM kaggle.olist_orders o
    CROSS JOIN ref r
    JOIN seller_orders os ON o.order_id = os.order_id
    JOIN kaggle.olist_seller_promise s ON s.seller_id = os.seller_id
    WHERE o.order_status = 'delivered'
),
aggregate AS (
    SELECT
        seller_id,
        AVG(days_gap) FILTER (WHERE period = 'recent') AS avg_gap_recent,
        AVG(days_gap) FILTER (WHERE period = 'prior') AS avg_gap_prior,
        AVG(days_gap) FILTER (WHERE period = 'recent') -
        AVG(days_gap) FILTER (WHERE period = 'prior') AS gap_change
    FROM seller_base
    GROUP BY seller_id
    HAVING AVG(days_gap) FILTER (WHERE period = 'recent') IS NOT NULL
    AND AVG(days_gap) FILTER (WHERE period = 'prior') IS NOT NULL
)
SELECT
    seller_id,
    ROUND(avg_gap_recent::NUMERIC, 2) AS avg_gap_recent,
    ROUND(avg_gap_prior::NUMERIC, 2) AS avg_gap_prior,
    ROUND(gap_change::NUMERIC, 2) AS gap_change,
    CASE
        WHEN gap_change > 0 THEN 'At Risk'
        ELSE 'Stable'
    END AS risk_flag
FROM aggregate
ORDER BY gap_change DESC;


-- SP5 Q3 — Product Category Review Scores


WITH product_orders AS (
    SELECT DISTINCT order_id, product_id
    FROM kaggle.olist_order_items
)
SELECT
    t.product_category_name_english AS product_category,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(COUNT(*) FILTER (
        WHERE DATE(r.review_creation_date) - DATE(o.order_delivered_customer_date) <= 3
    ) * 100.0 / COUNT(*), 2) AS pct_quick_reviews
FROM kaggle.olist_orders o
JOIN product_orders op ON o.order_id = op.order_id
JOIN (
    SELECT order_id, review_creation_date, AVG(review_score) AS review_score
    FROM kaggle.olist_order_reviews
    GROUP BY order_id, review_creation_date
) r ON o.order_id = r.order_id
JOIN kaggle.olist_products p ON p.product_id = op.product_id
JOIN kaggle.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY t.product_category_name_english
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY avg_review_score ASC;