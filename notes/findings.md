# Findings log

Running notes on the Olist data. These feed the README later.

## Data quality

- **775 orders (0.8%) have no items.** 603 are `unavailable`, 164 are `canceled`, and 8 are `created` (5), `invoiced` (2) or `shipped` (1). The first two groups never became real sales. The last 8 are odd and not worth chasing. Found with a LEFT JOIN from `orders` to `order_items`, filtered to `oi.order_id IS NULL`.
- **2,965 orders have no delivery date** (`order_delivered_customer_date IS NULL`). They can't be measured for lateness, so they are excluded from the delivery analysis.
- **`order_items` has more rows than `orders`** (112,650 vs 99,441) because one order can have several items. A join to `order_items` returns one row per item, so count `DISTINCT order_id` when counting orders.
- **Every item has a matching product and seller.** The 5-table inner join (orders, customers, order_items, products, sellers) returned 112,650 rows, the same as `order_items`, so nothing was lost.
- **768 orders have no review.** Inner join `orders` to `order_reviews` returns 99,224 rows. The left join returns 99,992. The difference is the unreviewed orders.
- **Some orders have more than one review.** The left join returned more rows (99,992) than there are orders (99,441), so a join to `order_reviews` can repeat an order.
- **97.0% of orders are `delivered`** (96,478 of 99,441). The rest are `shipped` (1,107), `canceled` (625), `unavailable` (609), `invoiced` (314), `processing` (301), `created` (5) and `approved` (2).
- **8 orders are `delivered` but have no delivery date.** They can't be measured for lateness and are excluded.
- **About 6 orders have a delivery date but are not `delivered`** (96,476 orders have a date; 96,478 - 8 = 96,470 delivered with a date). For the delay metric, filter on both `order_status = 'delivered'` and a non-empty delivery date.

## Results

- **Overall late rate is 8.11%.** Of 96,470 delivered orders with a delivery date, 7,826 arrived after the estimated date (delivered date greater than estimated date). Orders in scope: `order_status = 'delivered'` and a non-empty delivery date.
- **Headline: late orders get much lower review scores.** On-time orders average 4.29 (88,653 review rows), late orders average 2.57 (7,700 review rows), a gap of about 1.7 points. First-pass result using an inner join to `order_reviews`, so it excludes delivered orders with no review and counts orders with several reviews more than once. Re-run with one review per order (CTE) in Week 2. This shows a link, not proof of cause.

## Things to check later

- Decide how to handle orders with more than one review (for example, keep only the latest review per order) before averaging scores. Plan to do this with a CTE in Week 2.

## Checks that came back clean

- No delivered order has a delivery date earlier than its purchase date.

## More data quality

- **`order_reviews.review_id` is not unique.** 99,224 rows but only 98,410 distinct review IDs, so 814 rows repeat an ID. That is why the table has no primary key.
