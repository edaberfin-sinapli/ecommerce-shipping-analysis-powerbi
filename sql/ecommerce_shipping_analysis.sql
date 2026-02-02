/* =========================================================
   01) RAW DATA & CLEANING (shipping_analysis)
   ========================================================= */

CREATE DATABASE IF NOT EXISTS shipping_analysis;
USE shipping_analysis;

DROP TABLE IF EXISTS shipments;

CREATE TABLE IF NOT EXISTS shipments (
  ID INT NOT NULL,
  Warehouse_block VARCHAR(1),
  Mode_of_Shipment VARCHAR(20),
  Customer_care_calls TINYINT,
  Customer_rating TINYINT,
  Cost_of_the_Product INT,
  Prior_purchases TINYINT,
  Product_importance VARCHAR(10),
  Gender CHAR(1),
  Discount_offered INT,
  Weight_in_gms INT,
  Reached_on_Time_Y_N TINYINT,
  PRIMARY KEY (ID)
);

TRUNCATE TABLE shipments;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ecommerce_shipping.csv'
INTO TABLE shipments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  ID,
  Warehouse_block,
  Mode_of_Shipment,
  Customer_care_calls,
  Customer_rating,
  Cost_of_the_Product,
  Prior_purchases,
  Product_importance,
  Gender,
  Discount_offered,
  Weight_in_gms,
  Reached_on_Time_Y_N
);

-- =========================================================
-- BASIC VALIDATIONS
-- =========================================================

SELECT COUNT(*) AS row_count FROM shipments;

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ID) AS distinct_id,
  (COUNT(*) - COUNT(DISTINCT ID)) AS duplicate_id_rows
FROM shipments;

SELECT
  SUM(Warehouse_block IS NULL) AS null_warehouse_block,
  SUM(Mode_of_Shipment IS NULL) AS null_mode_of_shipment,
  SUM(Customer_care_calls IS NULL) AS null_customer_care_calls,
  SUM(Customer_rating IS NULL) AS null_customer_rating,
  SUM(Cost_of_the_Product IS NULL) AS null_cost_of_the_product,
  SUM(Prior_purchases IS NULL) AS null_prior_purchases,
  SUM(Product_importance IS NULL) AS null_product_importance,
  SUM(Gender IS NULL) AS null_gender,
  SUM(Discount_offered IS NULL) AS null_discount_offered,
  SUM(Weight_in_gms IS NULL) AS null_weight_in_gms,
  SUM(Reached_on_Time_Y_N IS NULL) AS null_reached
FROM shipments;

SELECT * FROM shipments LIMIT 10;



/* =========================================================
   02) ANALYSIS VIEWS (shipping_analysis)
   ========================================================= */

-- TR: Genel KPI özeti (toplam sipariş, on-time, late, on-time rate)
-- EN: Overall KPI summary (total orders, on-time, late, on-time rate)
CREATE OR REPLACE VIEW v_kpi_overall AS
SELECT
  COUNT(*) AS total_orders,
  SUM(Reached_on_Time_Y_N = 1) AS on_time_orders,
  SUM(Reached_on_Time_Y_N = 0) AS late_orders,
  ROUND(SUM(Reached_on_Time_Y_N = 1) / NULLIF(COUNT(*), 0), 4) AS on_time_rate
FROM shipments;


-- TR: Gönderim moduna göre teslimat performansı
-- EN: Delivery performance by shipment mode
CREATE OR REPLACE VIEW v_delivery_by_mode AS
SELECT
  Mode_of_Shipment,
  COUNT(*) AS total_orders,
  SUM(Reached_on_Time_Y_N = 1) AS on_time_orders,
  SUM(Reached_on_Time_Y_N = 0) AS late_orders,
  ROUND(SUM(Reached_on_Time_Y_N = 1) / NULLIF(COUNT(*), 0), 4) AS on_time_rate
FROM shipments
GROUP BY Mode_of_Shipment;


-- TR: Depo bloğuna göre teslimat performansı
-- EN: Delivery performance by warehouse block
CREATE OR REPLACE VIEW v_delivery_by_warehouse AS
SELECT
  Warehouse_block,
  COUNT(*) AS total_orders,
  SUM(Reached_on_Time_Y_N = 1) AS on_time_orders,
  SUM(Reached_on_Time_Y_N = 0) AS late_orders,
  ROUND(SUM(Reached_on_Time_Y_N = 1) / NULLIF(COUNT(*), 0), 4) AS on_time_rate
FROM shipments
GROUP BY Warehouse_block;


-- TR: Ürün önemine göre teslimat performansı
-- EN: Delivery performance by product importance
CREATE OR REPLACE VIEW v_delivery_by_importance AS
SELECT
  Product_importance,
  COUNT(*) AS total_orders,
  SUM(Reached_on_Time_Y_N = 1) AS on_time_orders,
  SUM(Reached_on_Time_Y_N = 0) AS late_orders,
  ROUND(SUM(Reached_on_Time_Y_N = 1) / NULLIF(COUNT(*), 0), 4) AS on_time_rate
FROM shipments
GROUP BY Product_importance;


-- TR: Müşteri hizmetleri arama sayısına göre gecikme oranı
-- EN: Late rate by customer care calls
CREATE OR REPLACE VIEW v_delivery_by_calls AS
SELECT
  Customer_care_calls,
  COUNT(*) AS total_orders,
  SUM(Reached_on_Time_Y_N = 0) AS late_orders,
  ROUND(SUM(Reached_on_Time_Y_N = 0) / NULLIF(COUNT(*), 0), 4) AS late_rate
FROM shipments
GROUP BY Customer_care_calls
ORDER BY Customer_care_calls;


-- TR: İndirim bandı ve ağırlık bandı oluşturarak “ürün profili” proxy’si çıkarırız.
-- EN: Create discount/weight/cost bands to build a “product profile” proxy.
CREATE OR REPLACE VIEW v_product_profile_base AS
SELECT
  ID,
  Product_importance,
  Cost_of_the_Product,
  Weight_in_gms,
  Discount_offered,
  Reached_on_Time_Y_N,

  CASE
    WHEN Cost_of_the_Product < 150 THEN 'Low'
    WHEN Cost_of_the_Product BETWEEN 150 AND 220 THEN 'Mid'
    ELSE 'High'
  END AS cost_band,

  CASE
    WHEN Weight_in_gms < 2500 THEN 'Light'
    WHEN Weight_in_gms BETWEEN 2500 AND 5000 THEN 'Medium'
    ELSE 'Heavy'
  END AS weight_band,

  CASE
    WHEN Discount_offered < 10 THEN '0-9'
    WHEN Discount_offered BETWEEN 10 AND 25 THEN '10-25'
    WHEN Discount_offered BETWEEN 26 AND 40 THEN '26-40'
    ELSE '41+'
  END AS discount_band
FROM shipments;


-- TR: “En çok satılan ürün” yerine: En çok sipariş alan ürün profilleri (Top 10)
-- EN: Instead of product_name: Top 10 most frequent product profiles (by order count)
CREATE OR REPLACE VIEW v_top10_product_profiles AS
SELECT
  Product_importance,
  cost_band,
  weight_band,
  discount_band,
  COUNT(*) AS total_orders,
  SUM(Reached_on_Time_Y_N = 1) AS on_time_orders,
  SUM(Reached_on_Time_Y_N = 0) AS late_orders,
  ROUND(SUM(Reached_on_Time_Y_N = 1) / NULLIF(COUNT(*), 0), 4) AS on_time_rate
FROM v_product_profile_base
GROUP BY Product_importance, cost_band, weight_band, discount_band
ORDER BY total_orders DESC
LIMIT 10;



/* =========================================================
   03) REPORTING LAYER (POWER BI)
   ========================================================= */

CREATE DATABASE IF NOT EXISTS shipping_reporting;
USE shipping_reporting;


-- 1) OVERALL DELIVERY PERFORMANCE (KPI OVERVIEW)
CREATE OR REPLACE VIEW v_kpi_cards AS
SELECT
  total_orders,
  on_time_orders,
  late_orders,
  on_time_rate
FROM shipping_analysis.v_kpi_overall;


-- 2) TOP 10 PRODUCT PROFILES (MOST ORDERED)
CREATE OR REPLACE VIEW v_bar_top10_product_profiles AS
SELECT
  CONCAT(Product_importance, ' | ', cost_band, ' | ', weight_band, ' | ', discount_band) AS product_profile,
  total_orders
FROM shipping_analysis.v_top10_product_profiles
ORDER BY total_orders DESC;


-- 3) DELIVERY PERFORMANCE BY SHIPMENT MODE
CREATE OR REPLACE VIEW v_bar_delivery_by_mode AS
SELECT Mode_of_Shipment, total_orders, on_time_rate
FROM shipping_analysis.v_delivery_by_mode;


-- 4) DELIVERY PERFORMANCE BY WAREHOUSE BLOCK
CREATE OR REPLACE VIEW v_bar_delivery_by_warehouse AS
SELECT Warehouse_block, total_orders, on_time_rate
FROM shipping_analysis.v_delivery_by_warehouse;


-- 5) DELIVERY PERFORMANCE BY PRODUCT IMPORTANCE
CREATE OR REPLACE VIEW v_bar_delivery_by_importance AS
SELECT Product_importance, total_orders, on_time_rate
FROM shipping_analysis.v_delivery_by_importance;


/* =========================================================
   VALIDATION QUERIES (OPTIONAL)
   ========================================================= */

SELECT * FROM shipping_reporting.v_kpi_cards;
SELECT * FROM shipping_reporting.v_bar_top10_product_profiles LIMIT 10;
SELECT * FROM shipping_reporting.v_bar_delivery_by_mode;
SELECT * FROM shipping_reporting.v_bar_delivery_by_warehouse;
SELECT * FROM shipping_reporting.v_bar_delivery_by_importance;
