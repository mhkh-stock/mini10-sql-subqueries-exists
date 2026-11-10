-- 01 — Customers with at least one order above the average order value.
-- The pattern to learn: a SCALAR subquery — one value, one row —
-- used like a number in WHERE. The average (PKR 10,837.50) is computed
-- once by the subquery; every order total is compared against it.
-- Note: all 10 ordering customers clear the bar at least once, which
-- is itself the finding — the shop has no buyer whose every order is
-- small. The two never-ordered customers have no order to compare,
-- so they correctly do not appear.
WITH order_totals AS (
    SELECT order_id,
           SUM(quantity * unit_price_at_sale) AS order_total
    FROM order_items
    GROUP BY order_id
)
SELECT c.customer_id, c.name,
       COUNT(o.order_id) AS above_avg_orders,
       MAX(ot.order_total) AS biggest_order_pkr
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.customer_id
JOIN order_totals AS ot ON ot.order_id = o.order_id
WHERE ot.order_total > (SELECT AVG(order_total) FROM order_totals)
GROUP BY c.customer_id, c.name
ORDER BY above_avg_orders DESC, biggest_order_pkr DESC;
