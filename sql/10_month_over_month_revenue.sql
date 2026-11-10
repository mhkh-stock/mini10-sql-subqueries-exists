-- 10 — Month-over-month revenue change (SUBQUERY IN FROM).
-- The pattern to learn: a subquery in FROM is a derived table — a
-- query used as if it were a table. Here the same monthly-revenue
-- subquery appears twice, once as "this month" and once joined back
-- to itself as "last month" (month shifted back by one with date()).
-- January has no previous month, so its change is NULL, not zero.
SELECT m.month, m.revenue_pkr,
       prev.revenue_pkr AS prev_month_revenue_pkr,
       m.revenue_pkr - prev.revenue_pkr AS change_pkr,
       ROUND(100.0 * (m.revenue_pkr - prev.revenue_pkr) / prev.revenue_pkr, 2) AS change_pct
FROM (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price_at_sale) AS revenue_pkr
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    GROUP BY month
) AS m
LEFT JOIN (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.quantity * oi.unit_price_at_sale) AS revenue_pkr
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    GROUP BY month
) AS prev
  ON prev.month = strftime('%Y-%m', date(m.month || '-01', '-1 month'))
ORDER BY m.month;
