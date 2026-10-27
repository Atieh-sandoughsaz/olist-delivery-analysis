# Olist schema

Nine tables. Each line is a foreign key pointing to the primary key it references.

## Relationships

```
orders.customer_id             -> customers.customer_id
order_items.order_id           -> orders.order_id
order_items.product_id         -> products.product_id
order_items.seller_id          -> sellers.seller_id
order_reviews.order_id         -> orders.order_id
order_payments.order_id        -> orders.order_id
products.product_category_name -> product_category_translation.product_category_name
```

`customers` and `sellers` also connect loosely to `geolocation` by zip prefix. That link is many-to-many, because `geolocation` repeats each zip prefix.

## Primary keys

| Table | Primary key |
|---|---|
| customers | customer_id |
| orders | order_id |
| order_items | (order_id, order_item_id) |
| order_payments | (order_id, payment_sequential) |
| order_reviews | none (review_id repeats) |
| products | product_id |
| sellers | seller_id |
| geolocation | none |
| product_category_translation | product_category_name |

## How to read it

- `customer_id` is created for every order. `customer_unique_id` identifies the real person.
- One order has many items, payments and sometimes reviews, so those tables repeat `order_id`.
- `order_items` is the bridge that connects orders to products and sellers.
