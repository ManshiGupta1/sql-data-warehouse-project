/*
================================================================================
Script:      Load Bronze Layer
Layer:       Bronze
Procedure:   bronze.load_bronze

Purpose:
    This stored procedure loads data into the Bronze layer from external
    CSV files.

    The procedure performs the following actions:

        1. Truncates the Bronze tables before loading new data.
        2. Uses the BULK INSERT command to load data from CSV files.
        3. Loads the raw data into the corresponding Bronze tables.

    The Bronze layer stores raw data from the CRM and ERP source systems
    with minimal transformation.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;

WARNING:
    This procedure truncates the existing Bronze tables before loading
    new data. Any existing data in the Bronze layer will be deleted.

    Ensure that the source CSV files are available and accessible before
    executing this procedure.

================================================================================
*/




CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME ,@batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
	SET @batch_start_time = GETDATE();
	PRINT '===================================================';
	PRINT 'LOADING BRONZE LAYER';
	PRINT '===================================================';

	PRINT '===================================================';
	PRINT 'LODING CRM TABLES';
	PRINT '===================================================';

	SET @start_time = GETDATE();
	PRINT '>> TRUNCATING TABLE :bronze.crm_cust_info ';
	TRUNCATE TABLE bronze.crm_cust_info;

	PRINT '>> INSERTING DATA INTO : bronze.crm_cust_info';
	BULK INSERT bronze.crm_cust_info
	FROM 'C:\Users\mansh\Downloads\source_crm\cust_info.csv'
	WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	TABLOCK 

	);
	SET @end_time = GETDATE();
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================'

	SET @start_time = GETDATE();
	PRINT '>> TRUNCATING TABLE :bronze.crm_prd_info ';
	TRUNCATE TABLE bronze.crm_prd_info;

	PRINT '>> INSERTING DATA INTO : bronze.crm_prd_info';
	BULK INSERT bronze.crm_prd_info
	FROM 'C:\Users\mansh\Downloads\source_crm\prd_info.csv'
	WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	TABLOCK 

	);
	SET @end_time = GETDATE();
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';

	SET @start_time = GETDATE();
	PRINT '>> TRUNCATING TABLE :bronze.crm_sales_details';
	TRUNCATE TABLE bronze.crm_sales_details;

	PRINT '>> INSERTING DATA INTO : bronze.crm_sales_details';
	BULK INSERT bronze.crm_sales_details
	FROM 'C:\Users\mansh\Downloads\source_crm\sales_details.csv'
	WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	TABLOCK 

	);
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';


	PRINT '===================================================';
	PRINT 'LODING ERP TABLES';
	PRINT '===================================================';

	SET @start_time = GETDATE();
	PRINT '>> TRUNCATING TABLE :bronze.erp_cust_az12';
	TRUNCATE TABLE bronze.erp_cust_az12;

	PRINT '>> INSERTING DATA INTO : bronze.erp_cust_az12';
	BULK INSERT bronze.erp_cust_az12
	FROM 'C:\Users\mansh\Downloads\source_erp\CUST_AZ12.csv'
	WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	TABLOCK 

	);
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';

	SET @start_time = GETDATE();
	PRINT '>> TRUNCATING TABLE :bronze.erp_loc_a101';
	TRUNCATE TABLE bronze.erp_loc_a101;

	PRINT '>> INSERTING DATA INTO : bronze.erp_loc_a101';
	BULK INSERT bronze.erp_loc_a101
	FROM 'C:\Users\mansh\Downloads\source_erp\LOC_A101.csv'
	WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	TABLOCK 

	);
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';

	SET @start_time = GETDATE();
	PRINT '>> TRUNCATING TABLE :bronze.erp_px_cat_g1v2';
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;

	PRINT '>> INSERTING DATA INTO : bronze.erp_px_cat_g1v2';
	BULK INSERT bronze.erp_px_cat_g1v2
	FROM 'C:\Users\mansh\Downloads\source_erp\PX_CAT_G1V2.csv'
	WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	TABLOCK 

);
	SET @end_time = GETDATE();
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';


	SET @batch_end_time = GETDATE();
    PRINT '======================================================================';
	PRINT 'LOADING BRONZE LAYER IS COMPLETED !';
	PRINT '>> LOADING DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Seconds';
	PRINT '======================================================================';
END TRY
BEGIN CATCH
	PRINT '==========================================================';
	PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
	PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
	PRINT 'ERROR MESSAGE' + CAST(ERROR_MESSAGE() AS NVARCHAR);
	PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
	PRINT '==========================================================';

END CATCH
END
