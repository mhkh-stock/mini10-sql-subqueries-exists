-- 04 — Customers who bought from EVERY category (NOT EXISTS, twice).
-- The pattern to learn: "for all" has no direct SQL keyword, so say
-- it as a double negative — there is NO category for which there is
-- NO order by this customer. The inner NOT EXISTS checks one
-- category; the outer NOT EXISTS checks that no category fails.
-- The category list comes from the products table itself, so the
-- query still works if a fifth category is added later.
SELECT c.customer_id, c.name,
       (SELECT COUNT(DISTINCT p.category)
        FROM orders AS o
        JOIN order_items AS oi ON oi.order_id = o.order_id
        JOIN products AS p ON p.product_id = oi.product_id
        WHERE o.customer_id = c.customer_id) AS categories_bought
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM (SELECT DISTINCT category FROM products) AS cat
    WHERE NOT EXISTS (
        SELECT 1
        FROM orders AS o
        JOIN order_items AS oi ON oi.order_id = o.order_id
        JOIN products AS p ON p.product_id = oi.product_id
        WHERE o.customer_id = c.customer_id
          AND p.category = cat.category
    )
)
ORDER BY c.customer_id;
