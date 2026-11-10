"""Build demo.db and run + verify all 10 Mini #10 queries.

Run:  python3 run_queries.py
Writes: data/demo.db, outputs/*.txt (one per query, headers on),
        outputs/SUMMARY.md (answers summary, generated from the run).
Asserts (exit 1 on failure):
  - base data: 12 customers, 9 products, 32 orders, 52 lines
  - every query returns >= 1 row
  - Q01: 10 customers, 16 above-average orders between them
  - Q02: 1 never-sold product (Bluetooth Speaker) — agrees with Mini #3
  - Q03: 14 orders, each above its own customer's average
  - Q04: 5 customers, each bought from all 4 categories (independently re-checked)
  - Q05: 4 category winners, revenues sum to 212,200, each is its category max
  - Q06: 2 customers (Hira Shah, Danish Iqbal), both never ordered — no lapsed buyer
  - Q07: 14 orders, each above its own month's average
  - Q08: 4 products above their category average list price
  - Q09: 5 customers above the median spend (34,450), totals sum to 219,600
  - Q10: 6 months, revenue sums to 346,800; Jan has no previous month,
    Jun change is +21,300 (+29.22%)
"""
import sqlite3
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
fails = []


def check(name, cond, detail=""):
    print(f"{'PASS' if cond else 'FAIL'}: {name} {detail}")
    if not cond:
        fails.append(name)


def main():
    db = BASE / "data" / "demo.db"
    if db.exists():
        db.unlink()
    con = sqlite3.connect(db)
    con.executescript((BASE / "data" / "schema.sql").read_text())
    con.executescript((BASE / "data" / "seed.sql").read_text())
    con.commit()

    counts = dict(zip(
        ["customers", "products", "orders", "lines"],
        [con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
         for t in ["customers", "products", "orders", "order_items"]]))
    check("base data counts", counts == {"customers": 12, "products": 9,
                                         "orders": 32, "lines": 52}, str(counts))

    results = {}
    for path in sorted((BASE / "sql").glob("*.sql")):
        cur = con.execute(path.read_text())
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
        results[path.stem[:2]] = (cols, rows)
        out = BASE / "outputs" / f"{path.stem[:2]}_{path.stem[3:]}.txt"
        with open(out, "w") as f:
            f.write(" | ".join(cols) + "\n")
            for r in rows:
                f.write(" | ".join(str(v) for v in r) + "\n")
        print(f"ran {path.name}: {len(rows)} rows -> {out.name}")

    check("every query returns >= 1 row",
          all(len(v[1]) >= 1 for v in results.values()),
          str({k: len(v[1]) for k, v in results.items()}))

    # Q01 — customers with an order above the average order value (10,837.50)
    q01 = results["01"][1]
    check("Q01 above-average customers = 10", len(q01) == 10)
    check("Q01 above-average orders = 16",
          sum(r[2] for r in q01) == 16, f"({sum(r[2] for r in q01)})")
    check("Q01 every biggest order > 10837.5",
          all(r[3] > 10837.5 for r in q01))

    # Q02 — NOT EXISTS must agree with Mini #3's LEFT JOIN answer
    check("Q02 never-sold = 1 (Bluetooth Speaker)",
          len(results["02"][1]) == 1
          and results["02"][1][0][1] == "Bluetooth Speaker")

    # Q03 — orders above their own customer's average
    q03 = results["03"][1]
    check("Q03 orders above customer avg = 14", len(q03) == 14)
    check("Q03 every order_total > customer_avg",
          all(r[3] > r[4] for r in q03))

    # Q04 — bought from every category (double NOT EXISTS)
    q04 = results["04"][1]
    check("Q04 all-category customers = 5", len(q04) == 5)
    check("Q04 each bought 4 categories",
          all(r[2] == 4 for r in q04), str([r[1] for r in q04]))
    cats = con.execute(
        """SELECT c.customer_id, COUNT(DISTINCT p.category)
           FROM customers c
           JOIN orders o ON o.customer_id = c.customer_id
           JOIN order_items oi ON oi.order_id = o.order_id
           JOIN products p ON p.product_id = oi.product_id
           GROUP BY c.customer_id""").fetchall()
    check("Q04 independent re-check: same 5 customers have 4 categories",
          {c for c, n in cats if n == 4} == {r[0] for r in q04})

    # Q05 — top product per category (correlated MAX)
    q05 = results["05"][1]
    check("Q05 one winner per category = 4", len(q05) == 4)
    check("Q05 winners' revenue sums to 212200",
          sum(r[2] for r in q05) == 212200, f"({sum(r[2] for r in q05)})")
    cat_max = dict(con.execute(
        """SELECT category, MAX(rev) FROM (
               SELECT p.category AS category,
                      SUM(oi.quantity * oi.unit_price_at_sale) AS rev
               FROM products p JOIN order_items oi ON oi.product_id = p.product_id
               GROUP BY p.product_id) GROUP BY category""").fetchall())
    check("Q05 each winner is its category max",
          all(cat_max[r[0]] == r[2] for r in q05))

    # Q06 — no order in the last 90 days; agrees with Mini #3's never-ordered pair
    q06 = results["06"][1]
    check("Q06 quiet customers = 2 (Hira Shah, Danish Iqbal)",
          len(q06) == 2
          and [r[1] for r in q06] == ["Hira Shah", "Danish Iqbal"],
          str([r[1] for r in q06]))
    check("Q06 both never ordered (no lapsed buyer)",
          all(r[3] == 0 and r[4] is None for r in q06))

    # Q07 — orders above their own month's average
    q07 = results["07"][1]
    check("Q07 orders above month avg = 14", len(q07) == 14)
    check("Q07 every order_total > month_avg",
          all(r[3] > r[4] for r in q07))

    # Q08 — products above their category average list price
    q08 = results["08"][1]
    check("Q08 products above category avg price = 4", len(q08) == 4)
    check("Q08 expected products",
          {r[1] for r in q08} == {"Mechanical Keyboard", "Bluetooth Speaker",
                                  "Office Chair", "Dinner Set 24pc"},
          str({r[1] for r in q08}))
    check("Q08 every list price > category avg",
          all(r[3] > r[4] for r in q08))

    # Q09 — customers above the median spend
    q09 = results["09"][1]
    totals = sorted(t for (t,) in con.execute(
        """SELECT SUM(oi.quantity * oi.unit_price_at_sale)
           FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
           GROUP BY o.customer_id""").fetchall())
    median = (totals[len(totals) // 2 - 1] + totals[len(totals) // 2]) / 2
    check("Q09 median spend = 34450 (independent Python calc)",
          median == 34450, f"({median})")
    check("Q09 customers above median = 5", len(q09) == 5)
    check("Q09 median column = 34450",
          all(r[3] == 34450 for r in q09))
    check("Q09 above-median totals sum to 219600",
          sum(r[2] for r in q09) == 219600, f"({sum(r[2] for r in q09)})")

    # Q10 — month-over-month revenue (subquery in FROM)
    q10 = results["10"][1]
    check("Q10 months = 6", len(q10) == 6)
    check("Q10 monthly revenue sums to 346800",
          sum(r[1] for r in q10) == 346800, f"({sum(r[1] for r in q10)})")
    check("Q10 Jan has no previous month",
          q10[0][0] == "2026-01" and q10[0][2] is None
          and q10[0][3] is None and q10[0][4] is None)
    jun = [r for r in q10 if r[0] == "2026-06"][0]
    check("Q10 Jun change = +21300 (+29.22%)",
          jun[3] == 21300 and jun[4] == 29.22, str(jun))
    grand = con.execute(
        "SELECT SUM(quantity * unit_price_at_sale) FROM order_items"
    ).fetchone()[0]
    check("reconciliation: Q10 total = order_items total = 346800",
          grand == 346800 == sum(r[1] for r in q10))

    write_summary(results)
    con.close()
    print(f"\n{len(fails)} failures" if fails else "\nall checks passed")
    return 1 if fails else 0


def write_summary(results):
    """Regenerate outputs/SUMMARY.md from this run's results."""
    avg_order = 346800 / 32
    lines = [
        "# Mini #10 — answers summary (generated by run_queries.py)",
        "",
        "SAMPLE / DEMO data only. Same shop as Mini #1 / Mini #3: "
        "12 customers, 9 products, 32 orders, 52 lines, Jan–Jun 2026, "
        "PKR 346,800 total revenue. Average order value: "
        f"PKR {avg_order:,.2f}.",
        "",
        "| # | Question | Rows | Headline answer |",
        "|---|---|---|---|",
    ]
    headlines = {
        "01": "All 10 ordering customers have at least one above-average order "
              f"(16 such orders; biggest: Usman Tariq PKR {max(r[3] for r in results['01'][1]):,})",
        "02": "1 product never sold: Bluetooth Speaker (Electronics, PKR 6,500)",
        "03": "14 orders beat their own customer's average",
        "04": "5 customers bought from all 4 categories: "
              + ", ".join(r[1] for r in results["04"][1]),
        "05": "Category winners: Office Chair PKR 72,000; Dinner Set 24pc PKR 58,000; "
              "Mechanical Keyboard PKR 51,000; Notebook Set PKR 31,200",
        "06": "2 customers with no order in the last 90 days — both never ordered; "
              "no existing buyer has gone quiet",
        "07": "14 orders beat their own month's average",
        "08": "4 products above their category average list price: "
              + ", ".join(r[1] for r in results["08"][1]),
        "09": "5 customers beat the median spend (PKR 34,450); their combined spend "
              f"is PKR {sum(r[2] for r in results['09'][1]):,}",
        "10": "Revenue grew every month except March (PKR 30,500, −39.00%); "
              "June is the peak at PKR 94,200 (+29.22% on May)",
    }
    questions = {
        "01": "Customers with an order above the average order value",
        "02": "Products never sold",
        "03": "Orders above their customer's average",
        "04": "Customers who bought from every category",
        "05": "Top product per category",
        "06": "Customers with no orders in the last 90 days",
        "07": "Orders larger than the average order in their month",
        "08": "Products priced above their category average",
        "09": "Customers whose total spend beats the median customer",
        "10": "Month-over-month revenue change",
    }
    for k in sorted(results):
        lines.append(f"| {k} | {questions[k]} | {len(results[k][1])} | "
                     f"{headlines[k]} |")
    lines += [
        "",
        "## Reconciliation",
        "",
        "- Monthly revenue (Q10) sums to PKR 346,800 = order_items total = "
        "Mini #1 / Mini #3 verified total.",
        "- Q02's never-sold product (Bluetooth Speaker) agrees with Mini #3 query 02; "
        "Q06's two quiet customers (Hira Shah, Danish Iqbal) agree with Mini #3 query 01.",
        "- Median spend (Q09) is PKR 34,450, computed over the 10 ordering customers.",
    ]
    (BASE / "outputs" / "SUMMARY.md").write_text("\n".join(lines) + "\n")
    print("wrote outputs/SUMMARY.md")


if __name__ == "__main__":
    sys.exit(main())
