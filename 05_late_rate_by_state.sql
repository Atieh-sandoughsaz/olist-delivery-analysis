-- Olist delivery analysis: late rate by customer state

-- ============================================================
-- Late rate per customer state, worst first.
-- Same late-rate logic as the overall query, grouped by state.
-- INNER JOIN to customers is safe: every order has a customer.
-- Worst: AL 23.93%, MA 19.67%, PI 15.97%, CE 15.32%, SE 15.22%
-- Biggest state SP: 5.89% on 40,494 orders
-- Small states (AP, AC, RR) have very few orders, so their rates are noisy.
-- ============================================================
SELECT c.customer_state,
       COUNT(*) AS delivered_orders,
       SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1 ELSE 0 END) AS late_orders,
       ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                              THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_rate_pct
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_rate_pct DESC;
