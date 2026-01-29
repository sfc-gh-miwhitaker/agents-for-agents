/*
================================================================================
SAMPLE DATA - Sales Analytics
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates realistic sales data for the multi-agent orchestration demo.
*/

USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- DIMENSION TABLES
-- =============================================================================

-- Products dimension
CREATE OR REPLACE TABLE DIM_PRODUCTS (
    PRODUCT_ID INT PRIMARY KEY,
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(50),
    SUBCATEGORY VARCHAR(50),
    UNIT_COST DECIMAL(10,2),
    UNIT_PRICE DECIMAL(10,2)
)
COMMENT = 'DEMO: Product dimension for sales analytics (Expires: 2026-02-28)';

INSERT INTO DIM_PRODUCTS VALUES
    (1, 'Enterprise Analytics Suite', 'Software', 'Analytics', 5000.00, 12000.00),
    (2, 'Data Integration Platform', 'Software', 'ETL', 3000.00, 8000.00),
    (3, 'Cloud Storage - 1TB', 'Infrastructure', 'Storage', 50.00, 150.00),
    (4, 'Compute Credits - 1000', 'Infrastructure', 'Compute', 200.00, 500.00),
    (5, 'Professional Services - Day', 'Services', 'Consulting', 800.00, 2000.00),
    (6, 'Training Package', 'Services', 'Education', 500.00, 1500.00),
    (7, 'Security Module', 'Software', 'Security', 2000.00, 5000.00),
    (8, 'AI/ML Toolkit', 'Software', 'AI', 4000.00, 10000.00),
    (9, 'Support - Premium', 'Services', 'Support', 1000.00, 3000.00),
    (10, 'Data Sharing License', 'Software', 'Collaboration', 1500.00, 4000.00);

-- Regions dimension
CREATE OR REPLACE TABLE DIM_REGIONS (
    REGION_ID INT PRIMARY KEY,
    REGION_NAME VARCHAR(50),
    COUNTRY VARCHAR(50),
    TIMEZONE VARCHAR(50)
)
COMMENT = 'DEMO: Region dimension for sales analytics (Expires: 2026-02-28)';

INSERT INTO DIM_REGIONS VALUES
    (1, 'North America - West', 'USA', 'America/Los_Angeles'),
    (2, 'North America - East', 'USA', 'America/New_York'),
    (3, 'North America - Central', 'USA', 'America/Chicago'),
    (4, 'Europe - West', 'UK', 'Europe/London'),
    (5, 'Europe - Central', 'Germany', 'Europe/Berlin'),
    (6, 'Asia Pacific - East', 'Japan', 'Asia/Tokyo'),
    (7, 'Asia Pacific - South', 'Australia', 'Australia/Sydney'),
    (8, 'Latin America', 'Brazil', 'America/Sao_Paulo');

-- Sales reps dimension
CREATE OR REPLACE TABLE DIM_SALES_REPS (
    REP_ID INT PRIMARY KEY,
    REP_NAME VARCHAR(100),
    REGION_ID INT REFERENCES DIM_REGIONS(REGION_ID),
    HIRE_DATE DATE,
    QUOTA DECIMAL(12,2)
)
COMMENT = 'DEMO: Sales rep dimension with quotas (Expires: 2026-02-28)';

INSERT INTO DIM_SALES_REPS VALUES
    (1, 'Sarah Chen', 1, '2022-03-15', 2000000.00),
    (2, 'Marcus Johnson', 2, '2021-06-01', 2500000.00),
    (3, 'Emily Rodriguez', 3, '2023-01-10', 1500000.00),
    (4, 'James Wilson', 4, '2020-09-20', 2200000.00),
    (5, 'Anna Schmidt', 5, '2022-07-05', 1800000.00),
    (6, 'Kenji Tanaka', 6, '2021-11-15', 2100000.00),
    (7, 'Lisa Park', 7, '2023-04-01', 1600000.00),
    (8, 'Carlos Silva', 8, '2022-02-28', 1400000.00);

-- =============================================================================
-- FACT TABLE - Sales Transactions
-- =============================================================================
CREATE OR REPLACE TABLE FACT_SALES (
    TRANSACTION_ID INT PRIMARY KEY,
    TRANSACTION_DATE DATE,
    PRODUCT_ID INT REFERENCES DIM_PRODUCTS(PRODUCT_ID),
    REP_ID INT REFERENCES DIM_SALES_REPS(REP_ID),
    QUANTITY INT,
    DISCOUNT_PERCENT DECIMAL(5,2),
    TOTAL_REVENUE DECIMAL(12,2),
    TOTAL_COST DECIMAL(12,2)
)
COMMENT = 'DEMO: Sales transactions fact table (Expires: 2026-02-28)';

-- Generate realistic sales data for the past 12 months
INSERT INTO FACT_SALES
WITH date_range AS (
    SELECT DATEADD(day, SEQ4(), DATEADD(month, -12, CURRENT_DATE())) AS sale_date
    FROM TABLE(GENERATOR(ROWCOUNT => 365))
),
transactions AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY d.sale_date, p.PRODUCT_ID) AS TRANSACTION_ID,
        d.sale_date AS TRANSACTION_DATE,
        p.PRODUCT_ID,
        r.REP_ID,
        UNIFORM(1, 10, RANDOM()) AS QUANTITY,
        ROUND(UNIFORM(0, 20, RANDOM()), 2) AS DISCOUNT_PERCENT,
        p.UNIT_PRICE,
        p.UNIT_COST
    FROM date_range d
    CROSS JOIN DIM_PRODUCTS p
    CROSS JOIN DIM_SALES_REPS r
    WHERE UNIFORM(0, 100, RANDOM()) < 15  -- ~15% chance of sale per day/product/rep
)
SELECT 
    TRANSACTION_ID,
    TRANSACTION_DATE,
    PRODUCT_ID,
    REP_ID,
    QUANTITY,
    DISCOUNT_PERCENT,
    ROUND(QUANTITY * UNIT_PRICE * (1 - DISCOUNT_PERCENT/100), 2) AS TOTAL_REVENUE,
    ROUND(QUANTITY * UNIT_COST, 2) AS TOTAL_COST
FROM transactions;

-- =============================================================================
-- SUMMARY VIEW for quick analytics
-- =============================================================================
CREATE OR REPLACE VIEW V_SALES_SUMMARY
COMMENT = 'DEMO: Aggregated sales summary view (Expires: 2026-02-28)'
AS
SELECT 
    fs.TRANSACTION_DATE,
    dp.PRODUCT_NAME,
    dp.CATEGORY,
    dr.REGION_NAME,
    ds.REP_NAME,
    fs.QUANTITY,
    fs.TOTAL_REVENUE,
    fs.TOTAL_COST,
    fs.TOTAL_REVENUE - fs.TOTAL_COST AS GROSS_PROFIT,
    ROUND((fs.TOTAL_REVENUE - fs.TOTAL_COST) / NULLIF(fs.TOTAL_REVENUE, 0) * 100, 2) AS PROFIT_MARGIN_PCT
FROM FACT_SALES fs
JOIN DIM_PRODUCTS dp ON fs.PRODUCT_ID = dp.PRODUCT_ID
JOIN DIM_SALES_REPS ds ON fs.REP_ID = ds.REP_ID
JOIN DIM_REGIONS dr ON ds.REGION_ID = dr.REGION_ID;
