/*
================================================================================
Stored Procedure: Load Silver Layer
Layer:            Silver
Data Flow:        Bronze → Silver

Script Purpose:
    This stored procedure performs the ETL process to populate the Silver
    schema tables from the Bronze schema.

Actions Performed:
    - Truncates the existing Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;

================================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME , @end_time DATETIME ,@batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
	SET @batch_start_time = GETDATE();
	PRINT '===================================================';
	PRINT 'LOADING SILVER LAYER';
	PRINT '===================================================';

	PRINT '===================================================';
	PRINT 'LODING CRM TABLES';
	PRINT '===================================================';
    SET @start_time = GETDATE();
    PRINT '>> TRUNCATING TABLE : silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;
    PRINT '>> INSERTING DATA INTO :silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)
    SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	    WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	    ELSE 'N/A'
    END cst_marital_status,
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	    ELSE 'N/A'
    END cst_gndr,
    cst_create_date 
    FROM(
	
	    SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	    from bronze.crm_cust_info
    )t where flag_last =1 AND cst_id IS NOT NULL;
    SET @end_time = GETDATE();
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================'


    SET @start_time = GETDATE();
    PRINT '>> TRUNCATING TABLE : silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;
    PRINT '>> INSERTING DATA INTO :silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info(
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
    )
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
        prd_nm,
        ISNULL(prd_cost,0) AS prd_cost,

        CASE 
            WHEN UPPER(TRIM(PRD_LINE)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(PRD_LINE)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(PRD_LINE)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(PRD_LINE)) = 'T' THEN 'Touring'
            ELSE 'N/A'
        END AS prd_line,

        prd_start_dt,

        DATEADD(
            DAY,
            -1,
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key 
                ORDER BY prd_start_dt
            )
        ) AS prd_end_dt

    FROM bronze.crm_prd_info;
    SET @end_time = GETDATE();
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';


    SET @start_time = GETDATE();
    PRINT '>> TRUNCATING TABLE :silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;
    PRINT '>> INSERTING DATA INTO :silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )

    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Convert order date
        CASE 
            WHEN sls_order_dt = 0 
              OR LEN(sls_order_dt) != 8 
            THEN NULL
            ELSE CONVERT(DATE, CONVERT(VARCHAR(8), sls_order_dt), 112)
        END AS sls_order_dt,

        -- Convert ship date
        CASE 
            WHEN sls_ship_dt = 0 
              OR LEN(sls_ship_dt) != 8 
            THEN NULL
            ELSE CONVERT(DATE, CONVERT(VARCHAR(8), sls_ship_dt), 112)
        END AS sls_ship_dt,

        -- Convert due date
        CASE 
            WHEN sls_due_dt = 0 
              OR LEN(sls_due_dt) != 8 
            THEN NULL
            ELSE CONVERT(DATE, CONVERT(VARCHAR(8), sls_due_dt), 112)
        END AS sls_due_dt,

        -- Fix sales
        CASE 
            WHEN sls_sales IS NULL 
              OR sls_sales <= 0 
              OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        -- Fix price
        CASE 
            WHEN sls_price IS NULL 
              OR sls_price <= 0 
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;


    PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';


	PRINT '===================================================';
	PRINT 'LODING ERP TABLES';
	PRINT '===================================================';

    SET @start_time = GETDATE();
    PRINT '>> TRUNCATING TABLE : silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;
    PRINT '>> INSERTING DATA INTO :silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
    SELECT 
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
        ELSE cid
    END AS cid,
    CASE WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,
    CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'N/A'
    END AS gen
    from bronze.erp_cust_az12
    PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';


    SET @start_time = GETDATE();
    PRINT '>> TRUNCATING TABLE : silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;
    PRINT '>> INSERTING DATA INTO :silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101(cid,cntry)
    SELECT 
    REPLACE(cid,'-','') as cid,
    CASE WHEN TRIM(cntry) IN ('USA','US') THEN ('United States')
         WHEN TRIM(cntry) = 'DE' THEN 'Germany'
         WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
         ELSE TRIM(cntry)
    END AS cntry
    from bronze.erp_loc_a101;

    PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';

    SET @start_time = GETDATE();
    PRINT '>> TRUNCATING TABLE : silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    PRINT '>> INSERTING DATA INTO :silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
    select 
    id,
    cat,
    subcat,
    maintenance
    from bronze.erp_px_cat_g1v2;
    SET @end_time = GETDATE();
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';


    SET @batch_end_time = GETDATE();
    PRINT '======================================================================';
	PRINT 'LOADING SILVER LAYER IS COMPLETED !';
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';
END TRY
BEGIN CATCH
	PRINT '==========================================================';
	PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
	PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
	PRINT 'ERROR MESSAGE' + CAST(ERROR_MESSAGE() AS NVARCHAR);
	PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
	PRINT '==========================================================';

END CATCH
END
