-- Olist delivery analysis: late rate by seller

-- ============================================================
-- Worst 20 sellers by late rate, among sellers with at least 30 delivered orders.
-- Step 1 (seller_orders): one row per order and seller, with a 1/0 late flag.
--   DISTINCT stops an order with several items from the same seller counting twice.
-- Step 2: join sellers for the seller's state, group by seller, same late-rate formula.
-- HAVING COUNT(*) >= 30 keeps tiny sellers from topping the list on a handful of orders.
-- Result: worst is 34.88% (15 of 43 orders), the 20th is 20.45%.
-- Most of the worst 20 are in SP, but SP also has the most sellers.
-- One high-volume seller in MA: 389 orders, 23.14% late.
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
)
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
ORDER BY late_rate_pct DESC
LIMIT 20;
