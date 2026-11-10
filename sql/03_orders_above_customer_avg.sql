-- 03 — Orders above their own customer's average order (CORRELATED subquery).
-- The pattern to learn: the subquery references the outer query's
-- row (o.customer_id), so it runs once per order, each time with a
-- different customer — "above average" means something different
-- for Ayesha Khan (avg PKR 14,175) than for Ali Nawaz (avg PKR 9,050).
-- A plain scalar subquery could only compare against one global average.
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
        WHERE o2.customer_id = o.customer_id) AS customer_avg_pkr
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
JOIN order_totals AS ot ON ot.order_id = o.order_id
WHERE ot.order_total > (
    SELECT AVG(ot2.order_total)
    FROM orders AS o2
    JOIN order_totals AS ot2 ON ot2.order_id = o2.order_id
    WHERE o2.customer_id = o.customer_id
)
ORDER BY ot.order_total DESC;
