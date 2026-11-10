-- 06 — Customers with no order in the last 90 days (NOT EXISTS).
-- The pattern to learn: NOT EXISTS with a date window is the standard
-- "gone quiet" check. The window ends on the latest order in the data
-- (2026-06-28), so "last 90 days" means on or after 2026-03-30.
-- The ever_ordered flag separates the two cases in the answer: both
-- rows are customers who never ordered at all — no existing buyer
-- has gone quiet, every buyer ordered inside the 90-day window.
SELECT c.customer_id, c.name, c.city,
       CASE WHEN EXISTS (
           SELECT 1 FROM orders AS o
           WHERE o.customer_id = c.customer_id
       ) THEN 1 ELSE 0 END AS ever_ordered,
       (SELECT MAX(o.order_date)
        FROM orders AS o
        WHERE o.customer_id = c.customer_id) AS last_order_date
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.customer_id
      AND o.order_date >= date((SELECT MAX(order_date) FROM orders), '-90 days')
)
ORDER BY c.customer_id;
