-- 08 — Products priced above their category's average list price.
-- The pattern to learn: a SCALAR subquery in WHERE, correlated on
-- category — the average is recomputed per category, so a PKR 6,500
-- speaker is expensive for Electronics (avg PKR 5,500) while a
-- PKR 4,200 lamp is cheap for Furniture (avg PKR 11,100). Note this
-- uses the catalogue list price, not what customers actually paid.
SELECT p.product_id, p.name, p.category, p.unit_price AS list_price_pkr,
       (SELECT ROUND(AVG(p2.unit_price), 2)
        FROM products AS p2
        WHERE p2.category = p.category) AS category_avg_price_pkr
FROM products AS p
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products AS p2
    WHERE p2.category = p.category
)
ORDER BY p.category, p.unit_price DESC;
