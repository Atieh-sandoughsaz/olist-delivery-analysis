-- Olist delivery analysis: CTEs and the corrected review headline

-- ============================================================
-- Headline: average review score, on time vs late
-- Step 1 (delivered): one row per measurable order, with its late/on time label
-- Step 2 (order_score): one score per order. AVG collapses orders with several reviews
-- Final: LEFT JOIN from delivered orders, so orders with no review are not lost
--
-- Result:
--   late     7,826 orders, 7,661 with a review, avg 2.57
--   on time 88,644 orders, 88,163 with a review, avg 4.29
-- 646 delivered orders have no review.
-- COUNT(s.score) skips NULLs, so it counts only orders that have a score.
-- ============================================================
WITH delivered AS (
    SELECT order_id,
           CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 'late' ELSE 'on time' END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
),
order_score AS (
    SELECT order_id,
           AVG(review_score) AS score
    FROM order_reviews
    GROUP BY order_id
)
SELECT d.delivery_status,
       COUNT(*) AS orders,
       COUNT(s.score) AS orders_with_review,
       ROUND(AVG(s.score), 2) AS avg_review_score
FROM delivered AS d
LEFT JOIN order_score AS s
    ON d.order_id = s.order_id
GROUP BY d.delivery_status;
