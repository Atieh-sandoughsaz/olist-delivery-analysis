-- Olist delivery analysis: Week 1 joins and data quality checks

-- ============================================================
-- Row counts: confirm every table loaded
-- ============================================================
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'product_category_translation', COUNT(*) FROM product_category_translation;

-- ============================================================
-- Joins: from 2 tables up to 5
-- ============================================================

-- orders + customers (inner join): 99,441 rows, every order has a customer
SELECT COUNT(*)
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id;

-- orders + customers + order_items: 112,650 rows (one row per item, not per order)
SELECT COUNT(*)
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id;

-- 5 tables: adds products and sellers. Still 112,650 rows, so nothing is lost
SELECT o.order_id,
       c.customer_state,
       s.seller_state,
       p.product_category_name,
       oi.price
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
INNER JOIN products AS p
    ON oi.product_id = p.product_id
INNER JOIN sellers AS s
    ON oi.seller_id = s.seller_id
LIMIT 10;

-- ============================================================
-- Inner vs left join: orders and order_reviews
-- ============================================================

-- Inner join: only orders that have a review (99,224 rows)
SELECT COUNT(*)
FROM orders AS o
INNER JOIN order_reviews AS r
    ON o.order_id = r.order_id;

-- Left join: keeps all orders, including 768 with no review (99,992 rows)
-- More than 99,441 because some orders have more than one review
SELECT COUNT(*)
FROM orders AS o
LEFT JOIN order_reviews AS r
    ON o.order_id = r.order_id;

-- ============================================================
-- Data quality checks
-- ============================================================

-- Orders with no delivery date: 2,965
SELECT COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NULL;

-- Orders with a delivery date: 96,476
SELECT COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Orders with no items, found with a left join: 775
SELECT COUNT(*)
FROM orders AS o
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- ...and what status they have (unavailable 603, canceled 164, others 8)
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM orders AS o
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- Orders per status (97% are delivered)
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- Delivered orders that have no delivery date: 8
SELECT COUNT(*)
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Delivered before purchased (impossible): 0
SELECT COUNT(*)
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- Duplicate review IDs: 99,224 rows but 98,410 distinct IDs
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT review_id) AS distinct_review_ids
FROM order_reviews;
