-- 05 — Top-earning product in each category (CORRELATED MAX subquery).
-- The pattern to learn: for each product row, the subquery asks for
-- the biggest revenue inside that row's own category only — the
-- correlation (pr2.category = pr.category) is what makes it
-- per-category instead of one global winner. Ties would return both
-- products; this data has no ties, so each category returns exactly one.
WITH product_revenue AS (
    SELECT p.product_id, p.name, p.category,
           SUM(oi.quantity * oi.unit_price_at_sale) AS revenue
    FROM products AS p
    JOIN order_items AS oi ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.name, p.category
)
SELECT pr.category, pr.name, pr.revenue AS revenue_pkr
FROM product_revenue AS pr
WHERE pr.revenue = (
    SELECT MAX(pr2.revenue)
    FROM product_revenue AS pr2
    WHERE pr2.category = pr.category
)
ORDER BY pr.revenue DESC;
