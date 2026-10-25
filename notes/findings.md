# Findings log

Running notes on the Olist data. These feed the README later.

## Data quality

- **775 orders (0.8%) have no items.** 603 are `unavailable`, 164 are `canceled`, and 8 are `created` (5), `invoiced` (2) or `shipped` (1). The first two groups never became real sales. The last 8 are odd and not worth chasing. Found with a LEFT JOIN from `orders` to `order_items`, filtered to `oi.order_id IS NULL`.
- **2,965 orders have no delivery date** (`order_delivered_customer_date IS NULL`). They can't be measured for lateness, so they are excluded from the delivery analysis.
- **`order_items` has more rows than `orders`** (112,650 vs 99,441) because one order can have several items. A join to `order_items` returns one row per item, so count `DISTINCT order_id` when counting orders.
- **Every item has a matching product and seller.** The 5-table inner join (orders, customers, order_items, products, sellers) returned 112,650 rows, the same as `order_items`, so nothing was lost.
- **768 orders have no review.** Inner join `orders` to `order_reviews` returns 99,224 rows. The left join returns 99,992. The difference is the unreviewed orders.
- **Some orders have more than one review.** The left join returned more rows (99,992) than there are orders (99,441), so a join to `order_reviews` can repeat an order.

## Things to check later

- `order_reviews.review_id` is expected to be unique but may contain duplicates.
