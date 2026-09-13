-- Revenue Definition:
-- Product Revenue = SUM(order_items.price)
-- Freight is excluded from product revenue.
--
-- Completed Order Definition:
-- order_status = 'delivered'


-- ============================================================
-- 1. Monthly Revenue, Orders, and Average Order Value
-- Business Question:
-- How did completed-order sales performance change over time?

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- ============================================================
-- 2. Top Product Categories by Revenue
-- Business Question:
-- Which product categories generate the most revenue,
-- and what share of total categorized revenue do they represent?

WITH category_sales AS (
    SELECT
        p.product_category_name_english AS product_category,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.price) AS product_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name_english IS NOT NULL
    GROUP BY p.product_category_name_english
)

SELECT
    product_category,
    completed_orders,
    ROUND(product_revenue, 2) AS product_revenue,
    ROUND(
        100.0 * product_revenue / SUM(product_revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM category_sales
ORDER BY product_revenue DESC
LIMIT 10;

-- ============================================================
-- 3. Top Sellers by Revenue
-- Business Question:
-- Which sellers generate the most product revenue from completed orders?

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY product_revenue DESC
LIMIT 10;

-- ============================================================
-- 4. One-Time vs Repeat Customers
-- Business Question:
-- How do one-time and repeat customers differ in customer count, order contribution, and product revenue?

WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.price) AS product_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        completed_orders,
        product_revenue,
        CASE
            WHEN completed_orders = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS customer_type
    FROM customer_metrics
)

SELECT
    customer_type,
    COUNT(*) AS customers,
    SUM(completed_orders) AS completed_orders,
    ROUND(SUM(product_revenue), 2) AS product_revenue,
    ROUND(
        100.0 * SUM(product_revenue)
        / SUM(SUM(product_revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM customer_segments
GROUP BY customer_type
ORDER BY product_revenue DESC;

-- ============================================================
-- 5A. Highest-Value Customers
-- Business Question:
-- Which customers generate the highest product revenue from completed orders?

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(oi.price) AS product_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    completed_orders,
    ROUND(product_revenue, 2) AS product_revenue,
    RANK() OVER (
        ORDER BY product_revenue DESC
    ) AS revenue_rank
FROM customer_value
ORDER BY revenue_rank
LIMIT 10;

-- 5B. Customer Revenue Concentration
-- Business Question:
-- How concentrated is product revenue among the highest-value customers?

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS product_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

customer_ranking AS (
    SELECT
        customer_unique_id,
        product_revenue,
        NTILE(10) OVER (
            ORDER BY product_revenue DESC
        ) AS revenue_decile
    FROM customer_value
)

SELECT
    revenue_decile,
    COUNT(*) AS customers,
    ROUND(SUM(product_revenue), 2) AS product_revenue,
    ROUND(
        100.0 * SUM(product_revenue)
        / SUM(SUM(product_revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM customer_ranking
GROUP BY revenue_decile
ORDER BY revenue_decile;

-- ============================================================
-- 6A. Delivery Status
-- Business Question:
-- What proportion of completed orders are delivered early, on the estimated date, or late?

WITH delivery_status AS (
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date::date
                 < order_estimated_delivery_date::date
                THEN 'Early'

            WHEN order_delivered_customer_date::date
                 = order_estimated_delivery_date::date
                THEN 'On Estimated Date'

            ELSE 'Late'
        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    delivery_status,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct
FROM delivery_status
GROUP BY delivery_status
ORDER BY
    CASE delivery_status
        WHEN 'Early' THEN 1
        WHEN 'On Estimated Date' THEN 2
        WHEN 'Late' THEN 3
    END;

-- 6B. Delivery Duration and Schedule Variance
-- Business Question:
-- How long does delivery take, and how early or late are completed orders relative to the estimated date?

SELECT
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )) / 86400
        )::numeric,
        2
    ) AS avg_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN order_delivered_customer_date::date
                     < order_estimated_delivery_date::date
                THEN
                    order_estimated_delivery_date::date
                    - order_delivered_customer_date::date
            END
        ),
        2
    ) AS avg_days_early,

    ROUND(
        AVG(
            CASE
                WHEN order_delivered_customer_date::date
                     > order_estimated_delivery_date::date
                THEN
                    order_delivered_customer_date::date
                    - order_estimated_delivery_date::date
            END
        ),
        2
    ) AS avg_days_late

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;