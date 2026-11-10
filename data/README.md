# Mini #10 — data dictionary (SAMPLE / DEMO only)

Identical to the Mini #3 dataset: same shop as Mini #1, so all three
packs reconcile on the same numbers. No new rows were invented for
this pack — the subquery questions are answered from the same shop.

## customers (12 rows)
- `customer_id` — PK, 1–12
- `name` — fictional person
- `city` — Lahore, Karachi, Islamabad, Faisalabad, Multan,
  Peshawar (11, never ordered), Quetta (12, never ordered)
- `signup_date` — ISO date

## products (9 rows)
- `product_id` — PK, 1–9
- `name`, `category` — Electronics / Furniture / Stationery / Kitchen
- `unit_price` — PKR list price; product 9 (Bluetooth Speaker,
  6,500) never appears in order_items

## orders (32 rows)
- `order_id` — PK, 1–32; `customer_id` → customers
- `order_date` — ISO date, Jan–Jun 2026

## order_items (52 rows)
- `order_item_id` — PK; `order_id` → orders;
  `product_id` → products
- `quantity`, `unit_price_at_sale` — PKR actually charged
  (may differ from list price; totals use the sale price)

## Totals (verified)
- 32 orders, 52 lines, PKR 346,800 — same as Mini #1 and Mini #3.
- Average order value: PKR 10,837.50 (346,800 / 32).
- Median customer spend (10 ordering customers): PKR 34,450.
- Monthly revenue: Jan 37,100 · Feb 50,000 · Mar 30,500 ·
  Apr 62,100 · May 72,900 · Jun 94,200.
