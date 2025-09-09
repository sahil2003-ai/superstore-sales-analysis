/********************************************************************
 Superstore Professional SQL Analysis
 Author: ChatGPT (for Sahil)
 Date: 2025-08-25

 HOW TO USE
 ----------
 1) Ensure your source table is named "Superstore" and has the original
    CSV column headers. If your table name is different, FIND+REPLACE
    "Superstore" with your table name before running.
 2) Run this script from top to bottom. It creates helper views and then
    provides step-by-step analysis queries you can execute independently.
 3) Dialect notes:
    - The script uses standard SQL and includes commented alternates for
      Postgres, MySQL, and SQL Server where needed (mainly date parsing
      and monthly bucketing). Use whichever block fits your database.
********************************************************************/

/*===============================================================
=            0) OPTIONAL: Row count & quick sanity               =
===============================================================*/
-- How many rows are in the raw table?
SELECT COUNT(*) AS row_count FROM "Superstore";

-- Peek a few rows (may require LIMIT/TOP depending on your DB):
-- Postgres / MySQL / SQLite
SELECT * FROM "Superstore" LIMIT 5;
-- SQL Server
-- SELECT TOP 5 * FROM "Superstore";

/*===============================================================
=            1) Helper View: clean names (no spaces)             =
===============================================================*/
-- Drops may fail harmlessly on some engines if the object doesn't exist.
-- Postgres / MySQL / SQL Server (adjust syntax if needed):
DROP VIEW IF EXISTS ss;
DROP VIEW IF EXISTS ss_dates;

-- Create a view with snake_case column aliases for easier querying.
CREATE OR REPLACE VIEW ss AS
SELECT
  "Row ID"        AS row_id,
  "Order ID"      AS order_id,
  "Order Date"    AS order_date_str,
  "Ship Date"     AS ship_date_str,
  "Ship Mode"     AS ship_mode,
  "Customer ID"   AS customer_id,
  "Customer Name" AS customer_name,
  "Segment"       AS segment,
  "Country"       AS country,
  "City"          AS city,
  "State"         AS state,
  "Postal Code"   AS postal_code,
  "Region"        AS region,
  "Product ID"    AS product_id,
  "Category"      AS category,
  "Sub-Category"  AS sub_category,
  "Product Name"  AS product_name,
  "Sales"         AS sales,
  "Quantity"      AS quantity,
  "Discount"      AS discount,
  "Profit"        AS profit
FROM "Superstore";

/*===============================================================
=            2) Helper View: parsed dates                       =
===============================================================*/
-- Use ONE of the following blocks for your database.

-- (A) Postgres / Redshift / Snowflake / Oracle style
CREATE OR REPLACE VIEW ss_dates AS
SELECT
  s.*,
  TO_DATE(order_date_str, 'MM/DD/YYYY') AS order_date,
  TO_DATE(ship_date_str,  'MM/DD/YYYY') AS ship_date
FROM ss s;

-- (B) MySQL / MariaDB style  (UNCOMMENT if you use MySQL/MariaDB)
-- CREATE OR REPLACE VIEW ss_dates AS
-- SELECT
--   s.*,
--   STR_TO_DATE(order_date_str, '%m/%d/%Y') AS order_date,
--   STR_TO_DATE(ship_date_str,  '%m/%d/%Y') AS ship_date
-- FROM ss s;

-- (C) SQL Server style (UNCOMMENT if you use SQL Server)
-- CREATE VIEW ss_dates AS
-- SELECT
--   s.*,
--   TRY_CONVERT(date, order_date_str, 101) AS order_date,  -- 101 = mm/dd/yyyy
--   TRY_CONVERT(date, ship_date_str,  101) AS ship_date
-- FROM ss s;

/*===============================================================
=            3) Global KPIs                                     =
===============================================================*/
-- Total Sales, Profit, Quantity, Orders, Customers, Products
SELECT
  ROUND(SUM(sales), 2)   AS total_sales,
  ROUND(SUM(profit), 2)  AS total_profit,
  SUM(quantity)          AS total_quantity,
  COUNT(DISTINCT order_id)    AS total_orders,
  COUNT(DISTINCT customer_id) AS total_customers,
  COUNT(DISTINCT product_id)  AS unique_products,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss;

-- Profitability health check (how many rows/orders losing money?)
SELECT
  SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_rows,
  COUNT(*) AS total_rows,
  ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_rows_loss
FROM ss;

/*===============================================================
=            4) Region Performance                              =
===============================================================*/
-- Sales & Profit by Region
SELECT
  region,
  ROUND(SUM(sales), 2)   AS sales,
  ROUND(SUM(profit), 2)  AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY region
ORDER BY sales DESC;

/*===============================================================
=            5) Segment Performance                             =
===============================================================*/
SELECT
  segment,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY segment
ORDER BY sales DESC;

/*===============================================================
=            6) Category & Sub-Category                         =
===============================================================*/
-- Category-level
SELECT
  category,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY category
ORDER BY sales DESC;

-- Sub-Category-level
SELECT
  category,
  sub_category,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY category, sub_category
ORDER BY category, sales DESC;

/*===============================================================
=            7) Product Analysis (Top/Bottom)                    =
===============================================================*/
-- Top 10 products by total profit
SELECT
  product_id,
  product_name,
  ROUND(SUM(sales), 2)  AS sales,
  SUM(quantity)         AS quantity,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY product_id, product_name
ORDER BY profit DESC
LIMIT 10;

-- Bottom 10 products by total profit (biggest loss-makers first)
SELECT
  product_id,
  product_name,
  ROUND(SUM(sales), 2)  AS sales,
  SUM(quantity)         AS quantity,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY product_id, product_name
ORDER BY profit ASC
LIMIT 10;

/*===============================================================
=            8) Customer Analysis (Top/Bottom)                   =
===============================================================*/
-- Top 10 customers by profit
SELECT
  customer_id,
  customer_name,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY customer_id, customer_name
ORDER BY profit DESC
LIMIT 10;

-- Bottom 10 customers by profit (least profitable / loss-heavy)
SELECT
  customer_id,
  customer_name,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY customer_id, customer_name
ORDER BY profit ASC
LIMIT 10;

/*===============================================================
=            9) Ship Mode Performance                            =
===============================================================*/
SELECT
  ship_mode,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  COUNT(DISTINCT order_id) AS orders,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY ship_mode
ORDER BY sales DESC;

/*===============================================================
=            10) Geography: Top States & Cities                  =
===============================================================*/
-- Top 10 States by Sales
SELECT
  state,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY state
ORDER BY sales DESC
LIMIT 10;

-- Top 10 Cities by Sales
SELECT
  city,
  state,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY city, state
ORDER BY sales DESC
LIMIT 10;

/*===============================================================
=            11) Discount Impact                                 =
===============================================================*/
-- Bucket discounts and evaluate profitability
WITH buckets AS (
  SELECT
    CASE
      WHEN discount = 0 THEN '0%'
      WHEN discount > 0 AND discount <= 0.20 THEN '0-20%'
      WHEN discount > 0.20 AND discount <= 0.40 THEN '20-40%'
      ELSE '>40%'
    END AS discount_band,
    sales,
    profit
  FROM ss
)
SELECT
  discount_band,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin,
  COUNT(*) AS row_count
FROM buckets
GROUP BY discount_band
ORDER BY discount_band;

/*===============================================================
=            12) Loss-making Lines & Orders                      =
===============================================================*/
-- Loss-making order lines (most negative first)
SELECT
  order_id,
  product_name,
  discount,
  ROUND(sales, 2)  AS sales,
  ROUND(profit, 2) AS profit
FROM ss
WHERE profit < 0
ORDER BY profit ASC
LIMIT 20;

-- Loss-making orders aggregated
SELECT
  order_id,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  COUNT(*) AS line_items
FROM ss
GROUP BY order_id
HAVING SUM(profit) < 0
ORDER BY profit ASC
LIMIT 20;

/*===============================================================
=            13) Time Series (Monthly Trend)                     =
===============================================================*/
-- Postgres / Redshift / Snowflake (DATE_TRUNC)
SELECT
  DATE_TRUNC('month', sd.order_date) AS month,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss_dates sd
GROUP BY 1
ORDER BY 1;

-- MySQL / MariaDB (DATE_FORMAT to first of month)
-- SELECT
--   DATE_FORMAT(sd.order_date, '%Y-%m-01') AS month,
--   ROUND(SUM(sales), 2)  AS sales,
--   ROUND(SUM(profit), 2) AS profit,
--   CASE WHEN SUM(sales) = 0 THEN NULL
--        ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
-- FROM ss_dates sd
-- GROUP BY 1
-- ORDER BY 1;

-- SQL Server (EOMONTH trick to get first day of month)
-- SELECT
--   DATEADD(month, DATEDIFF(month, 0, sd.order_date), 0) AS month,
--   ROUND(SUM(sales), 2)  AS sales,
--   ROUND(SUM(profit), 2) AS profit,
--   CASE WHEN SUM(sales) = 0 THEN NULL
--        ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
-- FROM ss_dates sd
-- GROUP BY DATEADD(month, DATEDIFF(month, 0, sd.order_date), 0)
-- ORDER BY month;

/*===============================================================
=            14) Extras: Category/Sub-Category Pivot Prep        =
===============================================================*/
-- Use this as a source for pivot tables in BI tools or spreadsheet.
SELECT
  category,
  sub_category,
  ROUND(SUM(sales), 2)  AS sales,
  ROUND(SUM(profit), 2) AS profit,
  CASE WHEN SUM(sales) = 0 THEN NULL
       ELSE ROUND(SUM(profit) / SUM(sales), 4) END AS profit_margin
FROM ss
GROUP BY category, sub_category
ORDER BY category, sub_category;

/*===============================================================
=            15) Suggested Indexes (optional)                    =
===============================================================*/
-- Adjust syntax to your DB; these are typical for analytics speed-ups.
-- CREATE INDEX idx_ss_region        ON "Superstore" ("Region");
-- CREATE INDEX idx_ss_category      ON "Superstore" ("Category", "Sub-Category");
-- CREATE INDEX idx_ss_customer      ON "Superstore" ("Customer ID");
-- CREATE INDEX idx_ss_product       ON "Superstore" ("Product ID");
-- For date-heavy analysis, index the raw text or materialize parsed dates:
-- CREATE INDEX idx_ss_order_date    ON ss_dates (order_date);

-- End of script.