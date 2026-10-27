-- Olist delivery analysis: delay metric and first headline result

-- ============================================================
-- Delay per order: delivered date minus estimated date
-- Positive = late, negative = early. Only delivered orders with a delivery date.
-- ============================================================
SELECT order_id,
       order_estimated_delivery_date,
       order_delivered_customer_date,
       order_delivered_customer_date - order_estimated_delivery_date AS delay
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
LIMIT 10;

-- ============================================================
-- Overall late rate: 96,470 delivered orders, 7,826 late, 8.11%
-- CASE makes a 1/0 flag per order, SUM adds the flags
-- ============================================================
SELECT COUNT(*) AS delivered_orders,
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1 ELSE 0 END) AS late_orders,
       ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                              THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- ============================================================
-- Headline (first pass): average review score, on time vs late
-- on time = 4.29 (88,653 rows), late = 2.57 (7,700 rows)
-- Caveat: inner join drops orders with no review and counts
-- orders with several reviews more than once. Fix with a CTE.
-- ============================================================
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'late' ELSE 'on time' END AS delivery_status,
       COUNT(*) AS review_rows,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders AS o
INNER JOIN order_reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;
