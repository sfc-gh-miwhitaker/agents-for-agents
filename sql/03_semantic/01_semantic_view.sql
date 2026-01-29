/*
================================================================================
SEMANTIC VIEW - Sales Analytics
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates a Semantic View for Cortex Analyst to enable natural language queries
against the sales data. This replaces the legacy YAML semantic model files.

IMPORTANT: Semantic Views are first-class database objects that define:
- Logical tables with business-friendly names
- Dimensions and measures with descriptions
- Relationships between tables
- Time intelligence configurations
================================================================================
*/

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SEMANTIC_MODELS;

-- =============================================================================
-- SEMANTIC VIEW: Sales Analytics
-- =============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_MAO_SALES_ANALYTICS
    COMMENT = 'DEMO: Semantic view for multi-agent orchestration sales analytics (Expires: 2026-02-28)'
AS
-- Define the logical data model for Cortex Analyst
DEFINE TABLES (
    -- Fact table: Sales transactions
    sales_transactions AS (
        SELECT 
            TRANSACTION_ID,
            TRANSACTION_DATE,
            PRODUCT_ID,
            REP_ID,
            QUANTITY,
            DISCOUNT_PERCENT,
            TOTAL_REVENUE,
            TOTAL_COST,
            TOTAL_REVENUE - TOTAL_COST AS GROSS_PROFIT
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES
    )
    WITH MEASURES (
        total_revenue DECIMAL(12,2) AS SUM(TOTAL_REVENUE) 
            WITH DESCRIPTION = 'Total revenue from sales transactions',
        total_cost DECIMAL(12,2) AS SUM(TOTAL_COST)
            WITH DESCRIPTION = 'Total cost of goods sold',
        gross_profit DECIMAL(12,2) AS SUM(GROSS_PROFIT)
            WITH DESCRIPTION = 'Gross profit (revenue minus cost)',
        profit_margin DECIMAL(5,2) AS (SUM(GROSS_PROFIT) / NULLIF(SUM(TOTAL_REVENUE), 0) * 100)
            WITH DESCRIPTION = 'Profit margin as a percentage',
        transaction_count INT AS COUNT(TRANSACTION_ID)
            WITH DESCRIPTION = 'Number of sales transactions',
        total_quantity INT AS SUM(QUANTITY)
            WITH DESCRIPTION = 'Total units sold',
        average_order_value DECIMAL(12,2) AS AVG(TOTAL_REVENUE)
            WITH DESCRIPTION = 'Average revenue per transaction',
        average_discount DECIMAL(5,2) AS AVG(DISCOUNT_PERCENT)
            WITH DESCRIPTION = 'Average discount percentage applied'
    )
    WITH DIMENSIONS (
        transaction_date DATE AS TRANSACTION_DATE
            WITH DESCRIPTION = 'Date of the sales transaction'
            WITH TIME_SPINE,
        product_id INT AS PRODUCT_ID
            WITH DESCRIPTION = 'Foreign key to product dimension',
        rep_id INT AS REP_ID
            WITH DESCRIPTION = 'Foreign key to sales rep dimension'
    ),

    -- Dimension table: Products
    products AS (
        SELECT 
            PRODUCT_ID,
            PRODUCT_NAME,
            CATEGORY,
            SUBCATEGORY,
            UNIT_COST,
            UNIT_PRICE
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_PRODUCTS
    )
    WITH PRIMARY KEY (PRODUCT_ID)
    WITH DIMENSIONS (
        product_id INT AS PRODUCT_ID
            WITH DESCRIPTION = 'Unique product identifier',
        product_name VARCHAR(100) AS PRODUCT_NAME
            WITH DESCRIPTION = 'Name of the product',
        category VARCHAR(50) AS CATEGORY
            WITH DESCRIPTION = 'Product category (Software, Infrastructure, Services)',
        subcategory VARCHAR(50) AS SUBCATEGORY
            WITH DESCRIPTION = 'Product subcategory for finer grouping',
        unit_cost DECIMAL(10,2) AS UNIT_COST
            WITH DESCRIPTION = 'Cost per unit',
        unit_price DECIMAL(10,2) AS UNIT_PRICE
            WITH DESCRIPTION = 'List price per unit'
    ),

    -- Dimension table: Sales Representatives
    sales_reps AS (
        SELECT 
            REP_ID,
            REP_NAME,
            REGION_ID,
            HIRE_DATE,
            QUOTA
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS
    )
    WITH PRIMARY KEY (REP_ID)
    WITH DIMENSIONS (
        rep_id INT AS REP_ID
            WITH DESCRIPTION = 'Unique sales representative identifier',
        rep_name VARCHAR(100) AS REP_NAME
            WITH DESCRIPTION = 'Name of the sales representative',
        region_id INT AS REGION_ID
            WITH DESCRIPTION = 'Foreign key to region dimension',
        hire_date DATE AS HIRE_DATE
            WITH DESCRIPTION = 'Date the rep was hired',
        quota DECIMAL(12,2) AS QUOTA
            WITH DESCRIPTION = 'Annual sales quota for the rep'
    ),

    -- Dimension table: Regions
    regions AS (
        SELECT 
            REGION_ID,
            REGION_NAME,
            COUNTRY,
            TIMEZONE
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_REGIONS
    )
    WITH PRIMARY KEY (REGION_ID)
    WITH DIMENSIONS (
        region_id INT AS REGION_ID
            WITH DESCRIPTION = 'Unique region identifier',
        region_name VARCHAR(50) AS REGION_NAME
            WITH DESCRIPTION = 'Name of the sales region',
        country VARCHAR(50) AS COUNTRY
            WITH DESCRIPTION = 'Country of the region',
        timezone VARCHAR(50) AS TIMEZONE
            WITH DESCRIPTION = 'Primary timezone for the region'
    )
)

-- Define relationships between tables
DEFINE RELATIONSHIPS (
    sales_transactions.product_id REFERENCES products.product_id,
    sales_transactions.rep_id REFERENCES sales_reps.rep_id,
    sales_reps.region_id REFERENCES regions.region_id
)

-- Define common filters and time configurations
WITH FILTERS (
    current_year AS transaction_date >= DATE_TRUNC('year', CURRENT_DATE())
        WITH DESCRIPTION = 'Filter to current calendar year',
    last_12_months AS transaction_date >= DATEADD(month, -12, CURRENT_DATE())
        WITH DESCRIPTION = 'Filter to trailing 12 months',
    current_quarter AS transaction_date >= DATE_TRUNC('quarter', CURRENT_DATE())
        WITH DESCRIPTION = 'Filter to current quarter'
)

WITH VERIFIED_QUERIES (
    -- Pre-verified query patterns for common questions
    'total revenue by region' AS (
        SELECT r.region_name, SUM(s.total_revenue) as revenue
        FROM sales_transactions s
        JOIN sales_reps sr ON s.rep_id = sr.rep_id
        JOIN regions r ON sr.region_id = r.region_id
        GROUP BY r.region_name
        ORDER BY revenue DESC
    ),
    'top products by profit' AS (
        SELECT p.product_name, SUM(s.gross_profit) as profit
        FROM sales_transactions s
        JOIN products p ON s.product_id = p.product_id
        GROUP BY p.product_name
        ORDER BY profit DESC
        LIMIT 10
    ),
    'sales rep performance' AS (
        SELECT 
            sr.rep_name,
            sr.quota,
            SUM(s.total_revenue) as actual_revenue,
            ROUND(SUM(s.total_revenue) / sr.quota * 100, 2) as quota_attainment_pct
        FROM sales_transactions s
        JOIN sales_reps sr ON s.rep_id = sr.rep_id
        GROUP BY sr.rep_name, sr.quota
        ORDER BY quota_attainment_pct DESC
    )
);

-- Grant access to the semantic view
GRANT USAGE ON SEMANTIC VIEW SV_MAO_SALES_ANALYTICS TO ROLE PUBLIC;
