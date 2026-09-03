/*

Quality Checks: Gold Layer
Script:          quality_checks_gold.sql
Layer:           Gold

Script Purpose:
This script performs quality checks to validate the integrity, consistency,
and accuracy of the Gold layer.

```
These checks ensure:
    - Uniqueness of surrogate keys in the dimension tables
    - Referential integrity between fact and dimension tables
    - Validation of relationships within the data model
    - Consistency of the Gold layer for analytical and reporting purposes
```

Usage Notes:
- Run these checks after loading the Gold layer.
- Investigate and resolve any discrepancies found during the checks.
- These queries are intended for validation and do not modify the data.

================================================================================
*/






--TESTING

SELECT DISTINCT
ci.cst_gndr,
ca.gen,
CASE WHEN ci.cst_gndr !='N/A' THEN ci.cst_gndr 
	ELSE COALESCE(ca.gen,'N/A')

END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key =ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
ORDER BY 1,2;

SELECT distinct(gender) FROM gold.dim_customers;

SELECT prd_key,COUNT(*) FROM (
SELECT 
    pn.prd_id,
    pn.prd_key,
    pn.prd_nm,
    pn.cat_id,
    pc.cat,
    pc.subcat,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt,
    pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL --FILTER OUT ALL HISTORICAL DATA
)t GROUP BY prd_key
HAVING COUNT(*) >1;


select * from gold.dim_products;

SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL;
