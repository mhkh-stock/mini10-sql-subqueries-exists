-- 07 — Orders larger than the average order in their own month.
-- The pattern to learn: same correlated-subquery shape as query 03,
-- but the correlation is on time instead of on a person — each order
-- is judged against its own month's average, so a PKR 9,600 order
-- counts as big in February (avg PKR 8,333.33) but small in May
-- (avg PKR 14,580). A global average would misjudge both.
WITH order_totals AS (
    SELECT order_id,
           SUM(quantity * unit_price_at_sale) AS order_total
    FROM order_items
    GROUP BY order_id
)
SELECT o.order_id, c.name AS customer, o.order_date,
       ot.order_total AS order_total_pkr,
       (SELECT ROUND(AVG(ot2.order_total), 2)
        FROM orders AS o2
        JOIN order_totals AS ot2 ON ot2.order_id = o2.order_id
        WHERE strftime('%Y-%m', o2.order_date) = strftime('%Y-%m', o.order_date)
       ) AS month_avg_pkr
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
JOIN order_totals AS ot ON ot.order_id = o.order_id
WHERE ot.order_total > (
    SELECT AVG(ot2.order_total)
    FROM orders AS o2
    JOIN order_totals AS ot2 ON ot2.order_id = o2.order_id
    WHERE strftime('%Y-%m', o2.order_date) = strftime('%Y-%m', o.order_date)
)
ORDER BY o.order_date;
