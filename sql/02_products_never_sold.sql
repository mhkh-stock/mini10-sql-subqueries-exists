-- 02 — Products never sold (NOT EXISTS anti-join).
-- The pattern to learn: NOT EXISTS asks "is there no matching row?"
-- for each product, one row at a time. Unlike NOT IN, it is safe
-- when the tested column can hold NULLs. Answer must agree with
-- Mini #3 query 02, which found the same product with a LEFT JOIN.
SELECT p.product_id, p.name, p.category, p.unit_price
FROM products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items AS oi
    WHERE oi.product_id = p.product_id
)
ORDER BY p.product_id;
