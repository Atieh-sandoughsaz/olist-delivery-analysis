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
- **Headline: late orders get much lower review scores.** On-time orders average 4.29 (88,653 review rows), late orders average 2.57 (7,700 review rows), a gap of about 1.7 points. First-pass result used an inner join to `order_reviews`. **Confirmed with a CTE** that averages the reviews to one score per order and left joins from delivered orders: on time 4.29 (88,163 of 88,644 orders have a review), late 2.57 (7,661 of 7,826). The result did not change, so it is robust. 646 delivered orders have no review. This shows a link, not proof of cause.
- **Late rate varies a lot by customer state.** Worst: AL 23.93%, MA 19.67%, PI 15.97%, CE 15.32%, SE 15.22%, all in the north-east. RJ is 13.47% on 12,350 orders. SP, the biggest state, is 5.89% on 40,494 orders. Best: RO 2.88%, AC 3.75%, AM 4.14%, AP 4.48%, but these have few orders (AP 67, AC 80), so apply a minimum order count (for example 100) in rankings.
- **Late rate by product category is much more even than by state.** Categories with at least 100 orders range from 4.07% (air_conditioning) to 12.93% (audio). Next worst: fashion_underwear_beach 12.82%, books_technical 10.94%, home_confort 10.46%. The biggest categories sit near the average: health_beauty 8.96% (8,647 orders), bed_bath_table 8.75% (9,272), sports_leisure 7.76% (7,529). Region explains late delivery better than category. 1,412 orders (9.07% late) have no category or no English translation. An order with items in several categories counts once per category, so category order counts add up to more than 96,470.
- **Some sellers have very high late rates.** Among sellers with at least 30 delivered orders, the worst 20 range from 20.45% to 34.88% (worst: seller `ede0c036...`, SP, 15 of 43 orders late). Most of the worst 20 are in SP, but SP also has most sellers, so compare share of sellers with share of worst sellers before drawing a conclusion. One seller stands out for volume: `06a2c3af...` in MA, 389 orders, 23.14% late. Rates on 30 to 50 orders are noisy.
- **Worst sellers within each state (window function).** Ranking sellers with at least 30 orders inside each state (`RANK() OVER (PARTITION BY seller_state ...)`) covers 13 states. The worst seller per state ranges from 6.67% (ES) to 34.88% (SP); the three worst SP sellers are all above 30%. MA has a single qualifying seller (389 orders, 23.14% late). Some large sellers are reliable: BA 348 orders at 4.31%, PE 337 orders at 4.45%.
- **Late orders are concentrated in a small group of sellers.** Ranking sellers by number of late orders and adding a running total (`SUM() OVER`): the top 20 sellers account for 23.97% of late orders, the top 50 for 37.26%, and the top 100 (about 3% of roughly 3,000 sellers) for 49.67%. Caution: this ranks by count, so big sellers rank high simply because they ship a lot. Their own late rates are near the average (rank 1: 195 of 1,772 = 11.0%; rank 5: 6.4%; rank 10: 10.4%; rank 100: 5.7%). Compare the top 100's share of late orders with their share of all orders before calling them the problem.

## Things to check later

- Compare the top 100 sellers' share of all orders with their 49.67% share of late orders (optional query in 09_seller_concentration.sql).

- Why do remote northern states (AM, AC, RO) have low late rates? Possible hypothesis: Olist sets longer estimated delivery dates there. Check the average gap between purchase and estimated date by state.

- Decide how to handle orders with more than one review (for example, keep only the latest review per order) before averaging scores. Plan to do this with a CTE in Week 2.

## Checks that came back clean

- No delivered order has a delivery date earlier than its purchase date.

## More data quality

- **`order_reviews.review_id` is not unique.** 99,224 rows but only 98,410 distinct review IDs, so 814 rows repeat an ID. That is why the table has no primary key.
