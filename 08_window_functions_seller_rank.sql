-- Olist delivery analysis: window functions

-- ============================================================
-- Simple ranking: sellers by items sold (RANK over all sellers)
-- Top seller sold 2,033 items. Ties share a rank and the next rank is skipped.
-- ============================================================
SELECT seller_id,
       COUNT(*) AS items_sold,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS sales_rank
FROM order_items
GROUP BY seller_id
ORDER BY sales_rank
LIMIT 5;

-- ============================================================
-- Worst 3 sellers in each state by late rate (PARTITION BY restarts the rank per state)
-- You cannot filter on a window function in WHERE, so the rank is computed in a CTE
-- and filtered in the final SELECT.
-- Only sellers with at least 30 delivered orders are ranked.
-- Result: 13 states appear. The worst seller per state ranges from 6.67% (ES) to 34.88% (SP).
-- ============================================================
WITH seller_orders AS (
    SELECT DISTINCT
           o.order_id,
           oi.seller_id,
           CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1 ELSE 0 END AS is_late
    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),
seller_stats AS (
    SELECT so.seller_id,
           s.seller_state,
           COUNT(*) AS orders,
           SUM(so.is_late) AS late_orders,
           ROUND(100.0 * SUM(so.is_late) / COUNT(*), 2) AS late_rate_pct
    FROM seller_orders AS so
    INNER JOIN sellers AS s
        ON so.seller_id = s.seller_id
    GROUP BY so.seller_id, s.seller_state
    HAVING COUNT(*) >= 30
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY seller_state ORDER BY late_rate_pct DESC) AS rank_in_state
    FROM seller_stats
)
SELECT *
FROM ranked
WHERE rank_in_state <= 3
ORDER BY seller_state, rank_in_state;
