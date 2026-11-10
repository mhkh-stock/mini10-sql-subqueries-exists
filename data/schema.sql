-- Mini #10 — SQL Subqueries & EXISTS Pack
-- SAMPLE / DEMO data only. Fictional shop, fictional people, fictional orders.
-- Never claimed as real client or real business data.
-- Same shop as Mini #1 / Mini #3 (12 customers, 9 products, 32 orders,
-- 52 order lines, Jan–Jun 2026, PKR 346,800 total).
-- SQLite 3.8.3+ (subqueries required). Run: sqlite3 demo.db < data/schema.sql
-- then: sqlite3 demo.db < data/seed.sql

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    city          TEXT NOT NULL,
    signup_date   TEXT NOT NULL  -- ISO date YYYY-MM-DD
);

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    category      TEXT NOT NULL,
    unit_price    INTEGER NOT NULL CHECK (unit_price > 0)  -- PKR, list price
);

CREATE TABLE orders (
    order_id      INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES customers (customer_id),
    order_date    TEXT NOT NULL  -- ISO date YYYY-MM-DD
);

CREATE TABLE order_items (
    order_item_id       INTEGER PRIMARY KEY,
    order_id            INTEGER NOT NULL REFERENCES orders (order_id),
    product_id          INTEGER NOT NULL REFERENCES products (product_id),
    quantity            INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_at_sale  INTEGER NOT NULL CHECK (unit_price_at_sale > 0)  -- PKR, price actually charged
);
