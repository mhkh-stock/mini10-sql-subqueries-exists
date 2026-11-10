-- 09 — Customers whose total spend beats the median customer.
-- The pattern to learn: a SUBQUERY IN WHERE that first computes a
-- threshold (here the median) and then filters on it. The median is
-- the average of the two middle totals: with 10 ordering customers
-- the middle rows are #5 and #6, so OFFSET is COUNT(*)/2 - 1 = 4.
-- Median is taken over the 10 customers who ordered — the two
-- never-ordered customers (PKR 0) are excluded, because the question
-- is "beats the median buyer", not "beats the median signup".
-- Median = (34,100 + 34,800) / 2 = PKR 34,450.
WITH order_totals AS (
    SELECT order_id,
           SUM(quantity * unit_price_at_sale) AS order_total
    FROM order_items
    GROUP BY order_id
),
customer_totals AS (
    SELECT o.customer_id,
           SUM(ot.order_total) AS total_spent
    FROM orders AS o
    JOIN order_totals AS ot ON ot.order_id = o.order_id
    GROUP BY o.customer_id
),
median_calc AS (
    SELECT AVG(total_spent) AS median_spend
    FROM (
        SELECT total_spent
        FROM customer_totals
        ORDER BY total_spent
        LIMIT 2 OFFSET (SELECT COUNT(*) / 2 - 1 FROM customer_totals)
    )
)
SELECT c.customer_id, c.name, ct.total_spent AS total_spent_pkr,
       (SELECT median_spend FROM median_calc) AS median_spend_pkr
FROM customers AS c
JOIN customer_totals AS ct ON ct.customer_id = c.customer_id
WHERE ct.total_spent > (SELECT median_spend FROM median_calc)
ORDER BY ct.total_spent DESC;
