# Olist E-Commerce Data Analysis

## Project Overview

This project analyzes the Brazilian E-Commerce Public Dataset by Olist to uncover insights into sales performance, customer behavior, seller performance, and delivery efficiency.

The analysis follows an end-to-end data analytics workflow, including data understanding, data cleaning, exploratory and business analysis with Python, SQL-based validation and querying in PostgreSQL, and interactive dashboard development in Power BI.

The project focuses on three core business areas:

- **Sales Performance** — Analyze revenue trends, product categories, geographic markets, and key revenue drivers.
- **Customer Analysis** — Evaluate customer retention, RFM-based customer segments, customer value, and revenue concentration.
- **Sales & Operations** — Examine seller performance, seller revenue drivers, delivery efficiency, and geographic differences in delivery performance.

The primary analysis period is **January 2017 to August 2018**, excluding sparse observations outside the main operating period.

## Business Questions

This project is structured around the following business questions:

### Sales Performance
1. How did product revenue, completed orders, and average order value change over time?
2. Which product categories generated the most product revenue?
3. Which customer states contributed the most revenue?
4. Is revenue growth driven more by order volume or by higher order value?

### Customer Analysis
5. What proportion of customers are one-time versus repeat customers?
6. How concentrated is revenue among high-value customers?
7. Which RFM customer segments generate the highest value per customer?
8. Which customer segment represents the strongest opportunity for second-purchase conversion?

### Seller & Operations Analysis
9. Which sellers generate the highest product revenue?
10. Is seller revenue primarily associated with completed-order volume or revenue per order?
11. Which customer states have the highest late-delivery rates?
12. How does average delivery time vary across customer states?

## Dataset & Data Model

### Dataset

This project uses the **Brazilian E-Commerce Public Dataset by Olist**, which contains transactional data from the Olist marketplace.

The original dataset consists of nine CSV files covering different aspects of the e-commerce process:

| Dataset | Description |
|---|---|
| Customers | Customer identifiers and geographic information |
| Orders | Order status and purchase, approval, shipping, and delivery timestamps |
| Order Items | Product, seller, price, and freight information at the order-item level |
| Products | Product attributes and product category information |
| Sellers | Seller identifiers and geographic information |
| Payments | Payment type, installments, and payment value |
| Reviews | Customer review scores and review information |
| Geolocation | ZIP-code-prefix-level latitude and longitude observations |
| Category Translation | Portuguese-to-English product category mapping |

### Data Model

The analysis uses a relational data model centered on the order lifecycle:

`Customers → Orders → Order Items → Products / Sellers`

Additional order-level information is provided through:

`Orders → Payments`

`Orders → Reviews`

Geographic information is connected to customers and sellers through ZIP code prefixes after cleaning and aggregation.

### Key Modeling Decisions

- **`order_id`** is the primary identifier used to connect orders with order items, payments, and reviews.
- **`customer_id`** represents the customer record associated with an individual order and is used to join the Customers and Orders tables.
- **`customer_unique_id`** represents the persistent customer identity across multiple orders and is therefore used for repeat-customer, customer-value, and RFM analysis.
- Order items are analyzed at the **order-item grain**, while customer metrics are aggregated to the **unique-customer grain** before segmentation.
- Payments and reviews can contain multiple records per order, so they are not directly joined to the item-level analytical dataset without prior aggregation to avoid row multiplication.
- Geolocation records are cleaned and aggregated by ZIP code prefix before being connected to customer and seller locations.

## Data Cleaning & Preparation

Before conducting business analysis, the raw datasets were profiled, validated, and transformed to ensure consistent data types, reliable relationships, and appropriate analytical grain.

### Data Quality Checks

The initial data-understanding stage included:

- Inspecting dataset dimensions, column types, and missing values.
- Identifying primary and composite keys for each table.
- Checking duplicate records and key uniqueness.
- Validating major foreign-key relationships across customers, orders, order items, products, sellers, payments, and reviews.
- Examining table grain before designing joins and aggregations.
- Reviewing timestamp completeness in relation to different order statuses.

### Data Cleaning

Key preparation steps included:

- Converted order and delivery fields to appropriate datetime types.
- Standardized ZIP code prefixes as strings to preserve leading zeros.
- Cleaned geolocation observations and aggregated latitude and longitude to the ZIP-code-prefix level.
- Preserved valid missing values where they reflected the business process rather than treating every null as an error.
- Converted invalid zero product weights to missing values instead of interpreting them as legitimate measurements.
- Standardized nullable product count fields using appropriate integer data types.
- Added English product category names using the category translation table.
- Enriched customer and seller records with cleaned geographic coordinates.

### Validation & Export

After cleaning, the processed relational tables were validated again for:

- Row counts and key uniqueness.
- Referential integrity across major relationships.
- Data-type consistency.
- Analytical compatibility with PostgreSQL and downstream analysis.

The cleaned datasets were then exported to `data/processed/` and used consistently across the Python, PostgreSQL, and Power BI stages of the project.

## Analysis & Key Findings

### 1. Sales Performance

- The analysis identified **96,478 completed orders**, generating approximately **R$13.22M in product revenue**.
- Average order value was approximately **R$137.04** per completed order.
- Monthly product revenue and completed-order volume showed a very strong positive relationship (**r ≈ 0.99**), indicating that sales expansion was primarily associated with higher transaction volume rather than sustained increases in order value.
- Revenue was concentrated across several major product categories. The **Top 10 categories generated approximately 62.43% of product revenue**, led by Health & Beauty, Watches & Gifts, and Bed Bath & Table.

### 2. Customer Behavior & Value

- Among customers with completed orders, approximately **97% were one-time customers**, while only about **3% were repeat customers**, highlighting limited observed repeat purchasing during the analysis period.
- Revenue was moderately concentrated among higher-value customers: the **Top 10% of customers generated approximately 41.10% of product revenue**.
- RFM analysis revealed substantial differences in customer value across behavioral segments.
- **Recent High-Value One-Time customers** represented only **11.49% of customers** but generated approximately **28.66% of revenue**, with average customer value approaching that of High-Value Repeat customers.
- This segment represents a particularly strong opportunity for **second-purchase conversion and retention campaigns**.

### 3. Seller Performance

- **2,970 sellers** generated revenue from completed orders during the analysis period.
- Seller completed-order volume and product revenue showed a strong positive relationship (**r ≈ 0.80**).
- In contrast, completed-order volume had almost no linear relationship with revenue per seller order (**r ≈ -0.05**).
- These results suggest that seller revenue is primarily associated with transaction volume, while some sellers outperform peers through substantially higher revenue per order.
- Seller revenue was distributed across a broad seller base: the **Top 10 sellers generated approximately 13.27% of seller revenue**, while the **Top 10% of sellers generated approximately 67.11%**.

### 4. Delivery Performance

- Average end-to-end delivery time was approximately **12.56 days**.
- Approximately **93.23% of delivered orders arrived on or before the estimated delivery date**, while **6.77% were late**.
- Delivery performance varied substantially across customer states, indicating geographic differences in logistics efficiency.
- To reduce volatility from small samples, state-level operational comparisons in the Power BI dashboard focus on states with at least **500 valid deliveries**.

## Business Recommendations

Based on the analysis, the following actions are recommended:

- **Prioritize second-purchase conversion:** Target Recent High-Value One-Time customers with personalized follow-up campaigns, incentives, or product recommendations.
- **Protect high-value repeat customers:** Maintain engagement with High-Value Repeat customers through retention and loyalty initiatives.
- **Scale seller volume strategically:** Since seller revenue is strongly associated with completed-order volume, identify high-performing sellers with capacity for additional transaction growth.
- **Investigate geographic delivery bottlenecks:** Focus logistics analysis on states with persistently high late-delivery rates or long delivery times.
- **Monitor revenue concentration:** Track dependence on high-value customers, major product categories, and leading sellers to manage concentration risk.

## Power BI Dashboard

The final Power BI report translates the analytical findings into a three-page interactive dashboard designed for executive monitoring, customer analysis, and operational decision-making.

### Executive Overview

Provides a high-level view of product revenue, completed orders, average order value, sales trends, product categories, geographic performance, delivery performance, and customer retention.

![Executive Overview](images/dashboard_overview.png)

### Customer Analysis

Examines customer retention, RFM segmentation, customer value, purchase behavior, and revenue concentration. The dashboard highlights Recent High-Value One-Time customers as a key opportunity for second-purchase conversion.

![Customer Analysis](images/dashboard_customer_analysis.png)

### Sales & Operations Analysis

Evaluates seller performance and delivery operations, including the relationship between seller order volume and revenue, top-performing sellers, state-level late-delivery rates, and average delivery times.

State-level delivery comparisons apply a minimum threshold of **500 valid deliveries** to reduce volatility from small samples.

![Sales & Operations Analysis](images/dashboard_sales_operations.png)

## Tools & Technologies

| Tool | Purpose |
|---|---|
| **Python** | Data profiling, cleaning, exploratory analysis, RFM segmentation, sales analysis, customer analysis, and delivery analysis |
| **Pandas / NumPy** | Data manipulation, transformation, aggregation, and analytical calculations |
| **Matplotlib** | Exploratory data visualization |
| **PostgreSQL** | Relational database for storing and querying the cleaned datasets |
| **SQL** | Business analysis, aggregation, customer segmentation, seller analysis, and delivery-performance validation |
| **Power BI** | Data modeling, DAX measures, interactive dashboards, and business visualization |
| **Jupyter Notebook** | Documented and reproducible Python analysis workflow |
| **Git / GitHub** | Version control and project documentation |

## Project Structure

```text
olist-ecommerce-analysis/
├── data/
│   ├── raw/
│   └── processed/
│
├── notebooks/
│   ├── 01_data_understanding.ipynb
│   ├── 02_data_cleaning.ipynb
│   ├── 03_sales_analysis.ipynb
│   ├── 04_customer_analysis.ipynb
│   ├── 05_delivery_analysis.ipynb
│   └── 06_dashboard_data.ipynb
│
├── sql/
│   ├── create_tables.sql
│   └── analysis_queries.sql
│
├── dashboard/
│   └── olist_dashboard.pbix
│
├── images/
│   ├── dashboard_overview.png
│   ├── dashboard_customer_analysis.png
│   └── dashboard_sales_operations.png
│
├── README.md
├── requirements.txt
└── .gitignore