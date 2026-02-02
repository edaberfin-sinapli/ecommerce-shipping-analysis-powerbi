# E-Commerce Shipping Analysis (Power BI)

This project analyzes order-level shipping performance in an e-commerce context,
with a focus on on-time delivery rates and late delivery drivers.
The analysis is presented through interactive Power BI dashboards.

---

## Project Overview
The goal of this project is to understand delivery performance across different
shipping modes, warehouse blocks, and product characteristics, and to identify
key factors contributing to late deliveries.

---

## Analysis Workflow
1. Raw e-commerce shipping data was explored and validated
2. Delivery performance metrics were calculated at the order level
3. Key dimensions such as shipment mode, warehouse block, and product importance
   were analyzed
4. Two Power BI dashboards were created to summarize performance and drivers of delays

---

## Power BI Dashboards

### 1️) E-Commerce Shipping Performance Overview
This dashboard provides a high-level view of overall delivery performance.

**Key Insights:**
- Out of **10,999 total orders**, **59.7%** were delivered on time, while **40.3%** were late.
- On-time delivery rates are relatively similar across shipment modes
  (Flight, Ship, and Road), indicating no single dominant mode advantage.
- Warehouse blocks show minor variation in on-time delivery performance,
  suggesting operational consistency across locations.
- Products with **high importance** have a noticeably higher on-time delivery rate,
  indicating prioritization in the shipping process.

**Included Visuals:**
- Total orders, on-time orders, and late orders (KPI cards)
- On-time delivery rate by shipment mode
- On-time delivery rate by warehouse block
- On-time delivery rate by product importance

---

### 2️) Shipping Breakdown Overview – Late Delivery Drivers
This dashboard focuses on identifying factors associated with late deliveries.

**Key Insights:**
- Shipment volume is highest for the **Ship** mode, which may contribute to
  congestion-related delays.
- Warehouse block **F** handles the largest number of orders, making it a key
  area for monitoring delivery performance.
- Late deliveries are more frequent for products with **low** and **medium**
  importance compared to high-importance products.
- Certain shipping profiles (combining product importance, shipment mode,
  and weight group) account for a disproportionate share of late orders,
  indicating opportunities for targeted process improvements.

**Included Visuals:**
- Orders by shipment mode
- Orders by warehouse block
- Orders by product importance
- Top shipping profiles contributing to late deliveries
- Interactive filters for shipment mode, warehouse block, and product importance

---

## Data Source
- Dataset: E-Commerce Shipping Dataset
- Source: Kaggle
- Data type: Order-level shipping and delivery performance data

---

## Project Structure

<pre>
ecommerce-shipping-analysis-powerbi/
│
├── data/
│ └── Ecommerce Shipping Data.csv
│
├── sql/
│ └── ecommerce_shipping_analysis.sql
│
├── powerbi/
│ ├── shipping_performance_overview.png
│ └── shipping_breakdown_late_delivery_drivers.png
│
└── README.md
</pre> 

---

## Key Takeaway
While overall delivery performance is moderately strong, late deliveries remain
significant. The analysis suggests that shipment volume concentration, warehouse
load, and product prioritization play a key role in delivery outcomes, providing
clear opportunities for operational optimization.
