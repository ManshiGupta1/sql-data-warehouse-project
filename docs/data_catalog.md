# Gold Layer — Data Catalog

## Overview

The **Gold layer** represents the business-level data, structured to support analytical and reporting use cases.

It consists of **dimension tables** and **fact tables** designed around specific business metrics. The Gold layer provides clean, integrated, and business-ready data for **BI analytics and reporting**.

---

## 1. `gold.dim_customers`

### Purpose

Stores customer details enriched with **demographic and geographic data**. This dimension supports customer behavior analysis and provides descriptive attributes for sales reporting.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| `customer_key` | INT | Surrogate key uniquely identifying each customer record in the dimension table. |
| `customer_id` | INT | Unique numerical identifier assigned to each customer. |
| `customer_number` | NVARCHAR(50) | Alphanumeric identifier representing the customer, used for tracking and referencing. |
| `first_name` | NVARCHAR(50) | The customer's first name, as recorded in the system. |
| `last_name` | NVARCHAR(50) | The customer's last name or family name. |
| `country` | NVARCHAR(50) | The country of residence for the customer, such as Australia. |
| `marital_status` | NVARCHAR(50) | The marital status of the customer, such as Married or Single. |
| `gender` | NVARCHAR(50) | The gender of the customer, such as Male, Female, or N/A. |
| `birthdate` | DATE | The date of birth of the customer, stored in `YYYY-MM-DD` format. |
| `create_date` | DATE | The date when the customer record was created in the system. |

---

## 2. `gold.dim_products`

### Purpose

Stores detailed product information enriched with **category, subcategory, maintenance, cost, and product line data**. This dimension supports product performance and sales analysis.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| `product_key` | INT | Surrogate key uniquely identifying each product record in the product dimension table. |
| `product_id` | INT | Unique identifier assigned to the product for internal tracking and referencing. |
| `product_number` | NVARCHAR(50) | Structured alphanumeric code representing the product, often used for identification and inventory tracking. |
| `product_name` | NVARCHAR(50) | Descriptive name of the product, including details such as type, color, and size. |
| `category_id` | NVARCHAR(50) | Unique identifier for the product category. |
| `category` | NVARCHAR(50) | Broader classification of the product, such as Bikes or Components. |
| `subcategory` | NVARCHAR(50) | More detailed classification of the product within its category. |
| `maintenance_required` | NVARCHAR(50) | Indicates whether the product requires maintenance, such as Yes or No. |
| `cost` | INT | Cost or base price of the product, measured in monetary units. |
| `product_line` | NVARCHAR(50) | Specific product line or series to which the product belongs, such as Road or Mountain. |
| `start_date` | DATE | Date when the product became available for sale or use. |

## 3. `gold.fact_sales`

### Purpose

Stores transactional sales data for analytical and reporting purposes. This fact table contains measurable sales metrics and links each transaction to the relevant **customer and product dimensions**.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| `order_number` | NVARCHAR(50) | A unique alphanumeric identifier for each sales order, such as `SO54496`. |
| `product_key` | INT | Surrogate key linking the sales transaction to the product dimension table. |
| `customer_key` | INT | Surrogate key linking the sales transaction to the customer dimension table. |
| `order_date` | DATE | The date when the order was placed. |
| `shipping_date` | DATE | The date when the order was shipped to the customer. |
| `due_date` | DATE | The date when the order payment was due. |
| `sales_amount` | INT | The total monetary value of the sale for the line item, measured in whole currency units. |
| `quantity` | INT | The number of units of the product ordered for the line item. |
| `price` | INT | The price per unit of the product for the line item, measured in whole currency units. |
