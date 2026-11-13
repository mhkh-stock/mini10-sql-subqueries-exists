# Mini #10 — SQL Subqueries & EXISTS Pack

**Status:** built, verified, and published on GitHub.

**SAMPLE / DEMO data only.** Fictional shop, fictional people, fictional orders.
Never claimed as real client or real business data.

The third pack in the entry-level SQL series, after Mini #1's window
functions and Mini #3's CTEs & joins: subqueries in every position
they can appear — scalar, correlated, `NOT EXISTS`, and in `FROM`.
One business question per file, one pattern named per file.

## Demo dataset

The exact same shop as Mini #1 and Mini #3 — no new rows invented:
12 customers (2 never ordered) · 9 products (1 never sold) · 32 orders ·
52 order lines · Jan–Jun 2026 · PKR 346,800 total revenue, identical
to both earlier packs, so all three reconcile with each other.
Schema: `data/schema.sql` · Seed: `data/seed.sql` · Dictionary:
`data/README.md` · Built database: `data/demo.db` (rebuild any time
with `python3 run_queries.py`, which also verifies every query).

## What the pack teaches

| Subquery type | Where it appears | Queries |
|---|---|---|
| Scalar subquery (one value) | `WHERE` | 01, 08 |
| Correlated subquery (re-runs per outer row) | `WHERE` / `SELECT` | 03, 05, 07 |
| `NOT EXISTS` anti-join | `WHERE` | 02, 06 |
| `NOT EXISTS` twice ("for all") | `WHERE` | 04 |
| Subquery as a threshold | `WHERE` | 09 |
| Subquery in `FROM` (derived table) | `FROM` | 10 |

## How to run (3 steps)

1. `cd mini10-sql-subqueries-exists`
2. `python3 run_queries.py` — builds `data/demo.db`, runs all 10
   queries, writes `outputs/*.txt` and `outputs/SUMMARY.md`, and
   asserts the checks below
3. Run any query by hand, e.g.
   `sqlite3 -header -column data/demo.db < sql/02_products_never_sold.sql`

Requires Python 3 + SQLite (standard library only). Verified on
SQLite 3.45.1.

## Queries

| File | Business question | Teaches | Verified output |
|---|---|---|---|
| `sql/01_customers_above_avg_order.sql` | Which customers placed an order above the average order value? | Scalar subquery in `WHERE` | 10 rows — every ordering customer clears the PKR 10,837.50 bar at least once; 16 such orders in total |
| `sql/02_products_never_sold.sql` | Which catalogue items earn nothing? | `NOT EXISTS` anti-join | 1 row: Bluetooth Speaker — agrees with Mini #3 query 02 |
| `sql/03_orders_above_customer_avg.sql` | Which orders beat their own customer's average? | Correlated subquery | 14 orders; biggest: Usman Tariq, order 11, PKR 20,400 vs his avg PKR 11,600 |
| `sql/04_customers_all_categories.sql` | Who bought from every category? | Double `NOT EXISTS` ("for all") | 5 rows: Ayesha Khan, Usman Tariq, Hassan Raza, Omar Sheikh, Sana Malik |
| `sql/05_top_product_per_category.sql` | What is the top-earning product in each category? | Correlated `MAX` subquery | 4 rows; Office Chair PKR 72,000, Dinner Set PKR 58,000, Mechanical Keyboard PKR 51,000, Notebook Set PKR 31,200 |
| `sql/06_customers_no_orders_last_90_days.sql` | Who has gone quiet in the last 90 days? | `NOT EXISTS` + date window | 2 rows: Hira Shah, Danish Iqbal — both never ordered; no existing buyer has lapsed |
| `sql/07_orders_above_month_avg.sql` | Which orders beat their own month's average? | Correlated subquery on time | 14 orders; Feb avg PKR 8,333.33 vs May avg PKR 14,580 |
| `sql/08_products_above_category_avg_price.sql` | Which products are priced above their category average? | Scalar subquery, correlated on category | 4 rows: Mechanical Keyboard, Bluetooth Speaker, Office Chair, Dinner Set 24pc |
| `sql/09_customers_above_median_spend.sql` | Whose total spend beats the median customer? | Subquery threshold in `WHERE` | 5 rows above the PKR 34,450 median; combined spend PKR 219,600 |
| `sql/10_month_over_month_revenue.sql` | How did revenue change month to month? | Subquery in `FROM` (derived table self-join) | 6 rows; Jan 37,100 → Jun 94,200; March the only fall (−39.00%) |

## Verification (done before delivery)

- All 10 files execute against `data/demo.db` with no errors;
  `run_queries.py` re-asserts 30 checks on every run, all passing.
- Reconciliation: monthly revenue (query 10) sums to 346,800 =
  order_items total = Mini #1 / Mini #3 verified total.
- Cross-pack agreement: query 02's never-sold product (Bluetooth
  Speaker) matches Mini #3 query 02; query 06's two quiet customers
  (Hira Shah, Danish Iqbal) match Mini #3 query 01's never-ordered pair.
- Median (query 09) is computed two independent ways — the SQL
  subquery and a Python calculation in `run_queries.py` — and both
  give PKR 34,450.
- Query 04's double-`NOT EXISTS` answer is independently re-checked
  in `run_queries.py` with a plain `GROUP BY`, and query 05's winners
  are re-checked against a per-category `MAX` — both agree.
- No `COUNT(*)` on a `LEFT JOIN` anywhere in this pack (the bug
  Mini #3 fixed); the only `COUNT(*)` is query 09's median offset,
  over an aggregated CTE with no join.
- Verified outputs are saved in `outputs/` (one `.txt` per query
  plus `SUMMARY.md`); `run_queries.py` regenerates them on every run.

## Limits

- SAMPLE / DEMO data only — fictional shop, Jan–Jun 2026, SQLite only.
- Query 06's "last 90 days" ends on the latest order in the data
  (2026-06-28), so the window is 2026-03-30 onward; re-run with a
  later dataset and the window moves with it.
- Query 09's median is over the 10 customers who ordered; the two
  never-ordered customers (PKR 0) are excluded on purpose — the
  question is "beats the median buyer", not "beats the median signup".
  Including the zeros would give a median of PKR 30,050 and 6 customers.
- Query 10's January change is NULL (no previous month), not zero.
- Query 05 returns both products on a tie; this data has no ties, so
  each category returns exactly one winner.

## Published

Published on GitHub: https://github.com/mhkh-stock/mini10-sql-subqueries-exists. The built
`data/demo.db` is intentionally not uploaded — rebuild it any time
with `python3 run_queries.py`.
