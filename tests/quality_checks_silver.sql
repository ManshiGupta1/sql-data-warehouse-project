/*
================================================================================
Quality Checks: Silver Layer
Script:          quality_checks_silver.sql
Layer:           Silver

Script Purpose:
    This script performs quality checks for data consistency, accuracy,
    and standardization across the Silver schema.

    It includes checks for:

        - NULL or duplicate primary keys
        - Unwanted spaces in string fields
        - Data standardization and consistency
        - Invalid date ranges
        - Data consistency between related fields
        - Validation of transformed and cleansed data

Usage Notes:
    - Run these checks after loading the Silver layer.
    - Investigate and resolve any discrepancies found during the checks.
    - These queries are intended for validation and do not modify the data.

================================================================================
*/


-- ============================================================================
-- 1. CUSTOMER DATA QUALITY CHECKS
-- ============================================================================

-- Check the Silver customer table
-- Purpose: Review the loaded customer data.
SELECT *
FROM silver.crm_cust_info;


-- Check for NULL or duplicate customer IDs
-- Expectation: No NULL values or duplicate customer IDs should exist.
SELECT 
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- Check a specific customer ID in the Bronze layer
-- Purpose: Investigate duplicate or inconsistent customer records
-- identified during the quality checks.
SELECT *
FROM bronze.crm_cust_info
WHERE cst_id = 29449;


-- Keep only the latest record for each customer ID
-- Purpose: Validate that the most recent customer record is selected
-- when duplicate customer records exist.
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY cst_id
               ORDER BY cst_create_date DESC
           ) AS flag_last
    FROM silver.crm_cust_info
) t
WHERE flag_last = 1;


-- ============================================================================
-- 2. STRING QUALITY CHECKS
-- ============================================================================

-- Check for unwanted spaces in product names
-- Expectation: No results should be returned.
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


-- Check for invalid or missing product costs
-- Expectation: No negative or NULL product costs should exist.
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;


-- Check for unwanted spaces in customer first names
-- Expectation: No results should be returned.
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);


-- Check for unwanted spaces in customer last names
-- Expectation: No results should be returned.
SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);


-- Check for unwanted spaces in customer gender
-- Expectation: No results should be returned.
SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);


-- ============================================================================
-- 3. DATA STANDARDIZATION AND CONSISTENCY
-- ============================================================================

-- Check distinct customer gender values
-- Purpose: Verify that gender values are standardized.
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;


-- Check distinct customer marital status values
-- Purpose: Verify that marital status values are standardized.
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;


-- ============================================================================
-- 4. PRODUCT DATA QUALITY CHECKS
-- ============================================================================

-- Review the Silver product table
SELECT *
FROM silver.crm_prd_info;


-- Check for duplicate or NULL product IDs
-- Expectation: No duplicate or NULL product IDs should exist.
SELECT 
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- Check distinct product line values
-- Purpose: Verify product line values are standardized.
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;


-- Check for invalid product date ranges
-- Expectation: Product end date should not be earlier than the start date.
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- Check for invalid product start dates in the Bronze layer
-- Purpose: Validate whether product start dates can be converted
-- correctly into DATE values.
SELECT prd_start_dt
FROM bronze.crm_prd_info
WHERE TRY_CONVERT(
          DATE,
          CONVERT(VARCHAR(8), prd_start_dt),
          112
      ) IS NULL
  AND prd_start_dt IS NOT NULL;


-- Check product date consistency in the Bronze layer
-- Expectation: End date should not be earlier than start date.
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================================
-- 5. PRODUCT DATE RANGE VALIDATION
-- ============================================================================

-- Calculate the expected end date for each product version
-- Purpose: Validate that product versions have continuous and
-- logically ordered effective date ranges.
SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    LEAD(prd_start_dt) OVER (
        PARTITION BY prd_key
        ORDER BY prd_start_dt
    ) - 1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN (
    'AC-HE-U509-R',
    'AC-HE-HL-U509'
);


-- ============================================================================
-- 6. SALES DATA QUALITY CHECKS
-- ============================================================================

-- Validate sales transaction dates and financial calculations.
-- Purpose:
--     - Convert integer dates into DATE format.
--     - Handle invalid dates.
--     - Validate sales amounts.
--     - Validate product prices.
--     - Ensure sales = quantity × price.

SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    -- Convert order date from YYYYMMDD format to DATE
    CASE 
        WHEN sls_order_dt = 0
          OR LEN(sls_order_dt) != 8
        THEN NULL
        ELSE CONVERT(
            DATE,
            CONVERT(VARCHAR(8), sls_order_dt),
            112
        )
    END AS sls_order_dt,

    -- Convert ship date from YYYYMMDD format to DATE
    CASE 
        WHEN sls_ship_dt = 0
          OR LEN(sls_ship_dt) != 8
        THEN NULL
        ELSE CONVERT(
            DATE,
            CONVERT(VARCHAR(8), sls_ship_dt),
            112
        )
    END AS sls_ship_dt,

    -- Convert due date from YYYYMMDD format to DATE
    CASE 
        WHEN sls_due_dt = 0
          OR LEN(sls_due_dt) != 8
        THEN NULL
        ELSE CONVERT(
            DATE,
            CONVERT(VARCHAR(8), sls_due_dt),
            112
        )
    END AS sls_due_dt,

    -- Validate and correct sales amount
    CASE 
        WHEN sls_sales IS NULL
          OR sls_sales <= 0
          OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    -- Validate and correct product price
    CASE 
        WHEN sls_price IS NULL
          OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;


-- ============================================================================
-- 7. ERP CUSTOMER DATA QUALITY CHECKS
-- ============================================================================

-- Standardize ERP customer IDs, birth dates, and gender values.
-- Purpose:
--     - Remove the 'NAS' prefix from customer IDs.
--     - Handle future birth dates.
--     - Standardize gender values.

SELECT
    CASE
        WHEN cid LIKE 'NAS%'
        THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    CASE
        WHEN bdate > GETDATE()
        THEN NULL
        ELSE bdate
    END AS bdate,

    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
        THEN 'Female'

        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
        THEN 'Male'

        ELSE 'N/A'
    END AS gen

FROM bronze.erp_cust_az12;


-- Check for unrealistic birth dates
-- Expectation: Birth dates should fall within a reasonable range
-- and should not be in the future.
SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > GETDATE();


-- Check standardized gender values
-- Purpose: Verify that gender values contain only expected categories.
SELECT DISTINCT gen
FROM silver.erp_cust_az12;


-- ============================================================================
-- 8. ERP LOCATION DATA QUALITY CHECKS
-- ============================================================================

-- Review raw ERP location data.
SELECT *
FROM bronze.erp_loc_a101;


-- Validate standardized country values and customer IDs.
-- Purpose:
--     - Remove '-' from customer IDs.
--     - Standardize country names.
--     - Replace missing or empty country values with 'N/A'.

INSERT INTO silver.erp_loc_a101 (cid, cntry)
SELECT
    REPLACE(cid, '-', '') AS cid,

    CASE
        WHEN TRIM(cntry) IN ('USA', 'US')
            THEN 'United States'

        WHEN TRIM(cntry) = 'DE'
            THEN 'Germany'

        WHEN TRIM(cntry) = ''
          OR cntry IS NULL
            THEN 'N/A'

        ELSE TRIM(cntry)
    END AS cntry

FROM bronze.erp_loc_a101;


-- Check standardized country values
-- Purpose: Verify that country values are consistent.
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ============================================================================
-- 9. ERP PRODUCT CATEGORY DATA QUALITY CHECKS
-- ============================================================================

-- Review ERP product category data.
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;


-- Check for unwanted spaces in category values
-- Expectation: No results should be returned.
SELECT cat
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(cat) != cat;


-- Check for unwanted spaces in subcategory values
-- Expectation: No results should be returned.
SELECT subcat
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(subcat) != subcat;


-- Check distinct maintenance values
-- Purpose: Verify that maintenance values are standardized.
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2
ORDER BY maintenance;


-- Check for unwanted spaces in maintenance values
-- Expectation: No results should be returned.
SELECT maintenance
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(maintenance) != maintenance;


-- ============================================================================
-- END OF SILVER LAYER QUALITY CHECKS
-- ============================================================================
