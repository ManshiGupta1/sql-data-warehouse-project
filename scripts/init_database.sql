/*
================================================================================
Script:      Create Database & Schemas
Database:    DataWarehouse
Author:      Manshi
================================================================================

Purpose:
    This script creates a new database named 'DataWarehouse'.

    If the database already exists, it will be dropped and recreated.

    The script also creates three schemas within the database:

        - bronze : Stores raw/source data
        - silver : Stores cleaned and transformed data
        - gold   : Stores business-ready data for analytics and reporting

WARNING:
    Running this script will DROP the entire 'DataWarehouse' database
    if it already exists.

    All data stored in the database will be permanently deleted.

    Process with caution and ensure you have proper backups before
    running this script.

================================================================================
*/


-- ============================================================================
-- 1. DROP DATABASE IF IT ALREADY EXISTS
-- ============================================================================

USE master;
GO

IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN
    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    DROP DATABASE DataWarehouse;
END;
GO


-- ============================================================================
-- 2. CREATE DATABASE
-- ============================================================================

CREATE DATABASE DataWarehouse;
GO


-- ============================================================================
-- 3. USE THE NEW DATABASE
-- ============================================================================

USE DataWarehouse;
GO


-- ============================================================================
-- 4. CREATE DATA WAREHOUSE SCHEMAS
-- ============================================================================

-- Bronze Layer: Raw data loaded from source systems
CREATE SCHEMA bronze;
GO

-- Silver Layer: Cleaned and transformed data
CREATE SCHEMA silver;
GO

-- Gold Layer: Business-ready data used for analytics and reporting
CREATE SCHEMA gold;
GO
