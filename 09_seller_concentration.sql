-- Olist delivery analysis: how concentrated are late orders across sellers?

-- ============================================================
-- Running share of late orders, sellers ranked by number of late orders.
-- seller_stats: one row per seller. ROW_NUMBER numbers sellers from most late orders down
--   (seller_id breaks ties). SUM() OVER (ORDER BY ...) is a running total.
-- Only a few ranks are shown to keep the table short.
-- Result:
--   top 1   =  2.49% of late orders
--   top 5   =  9.03%
--   top 10  = 15.32%
--   top 20  = 23.97%
--   top 50  = 37.26%
--   top 100 = 49.67%  (about 3% of roughly 3,000 sellers)
-- An order with items from two sellers counts once per seller, so the total
-- across sellers is slightly above 7,826.
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
    SELECT seller_id,
           COUNT(*) AS orders,
           SUM(is_late) AS late_orders
    FROM seller_orders
    GROUP BY seller_id
),
ranked AS (
    SELECT seller_id,
           orders,
           late_orders,
           ROW_NUMBER() OVER (ORDER BY late_orders DESC, seller_id) AS seller_rank,
           SUM(late_orders) OVER (ORDER BY late_orders DESC, seller_id) AS cumulative_late
    FROM seller_stats
)
SELECT seller_rank,
       seller_id,
       orders,
       late_orders,
       cumulative_late,
       ROUND(100.0 * cumulative_late / (SELECT SUM(late_orders) FROM seller_stats), 2) AS cumulative_share_pct
FROM ranked
WHERE seller_rank IN (1, 5, 10, 20, 50, 100)
ORDER BY seller_rank;

-- ============================================================
-- OPTIONAL follow-up (not run yet): do the top sellers also have a big share of ALL orders?
-- If the top 100's share of all orders is also near 50%, they are not worse than the rest,
-- they are just big. Compare cumulative_order_share_pct with cumulative_share_pct above.
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
    SELECT seller_id,
           COUNT(*) AS orders,
           SUM(is_late) AS late_orders
    FROM seller_orders
    GROUP BY seller_id
),
ranked AS (
    SELECT seller_id,
           orders,
           late_orders,
           ROW_NUMBER() OVER (ORDER BY late_orders DESC, seller_id) AS seller_rank,
           SUM(orders) OVER (ORDER BY late_orders DESC, seller_id) AS cumulative_orders
    FROM seller_stats
)
SELECT seller_rank,
       cumulative_orders,
       ROUND(100.0 * cumulative_orders / (SELECT SUM(orders) FROM seller_stats), 2) AS cumulative_order_share_pct
FROM ranked
WHERE seller_rank IN (1, 5, 10, 20, 50, 100)
ORDER BY seller_rank;
