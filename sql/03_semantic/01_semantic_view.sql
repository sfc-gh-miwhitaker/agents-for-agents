/*
================================================================================
SEMANTIC VIEW - Sales Analytics
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates a Semantic View for Cortex Analyst to enable natural language queries
against the sales data.
================================================================================
*/

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SEMANTIC_MODELS;

-- =============================================================================
-- SEMANTIC VIEW: Sales Analytics
-- =============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_MAO_SALES_ANALYTICS

  TABLES (
    sales AS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES
      PRIMARY KEY (TRANSACTION_ID)
      COMMENT = 'Sales transactions fact table',
    
    products AS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_PRODUCTS
      PRIMARY KEY (PRODUCT_ID)
      COMMENT = 'Product dimension',
    
    sales_reps AS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS
      PRIMARY KEY (REP_ID)
      COMMENT = 'Sales representatives dimension',
    
    regions AS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_REGIONS
      PRIMARY KEY (REGION_ID)
      COMMENT = 'Geographic regions dimension'
  )

  RELATIONSHIPS (
    sales_to_products AS sales (PRODUCT_ID) REFERENCES products,
    sales_to_reps AS sales (REP_ID) REFERENCES sales_reps,
    reps_to_regions AS sales_reps (REGION_ID) REFERENCES regions
  )

  FACTS (
    sales.gross_profit AS TOTAL_REVENUE - TOTAL_COST
      COMMENT = 'Gross profit per transaction'
  )

  DIMENSIONS (
    sales.transaction_date AS TRANSACTION_DATE
      COMMENT = 'Date of the sales transaction',
    sales.quantity AS QUANTITY
      COMMENT = 'Units sold',
    sales.discount_percent AS DISCOUNT_PERCENT
      COMMENT = 'Discount percentage applied',
    sales.total_revenue AS TOTAL_REVENUE
      COMMENT = 'Total revenue from transaction',
    sales.total_cost AS TOTAL_COST
      COMMENT = 'Total cost of goods sold',
    
    products.product_name AS PRODUCT_NAME
      COMMENT = 'Name of the product',
    products.category AS CATEGORY
      COMMENT = 'Product category',
    products.subcategory AS SUBCATEGORY
      COMMENT = 'Product subcategory',
    products.unit_price AS UNIT_PRICE
      COMMENT = 'List price per unit',
    
    sales_reps.rep_name AS REP_NAME
      COMMENT = 'Sales representative name',
    sales_reps.quota AS QUOTA
      COMMENT = 'Annual sales quota',
    sales_reps.hire_date AS HIRE_DATE
      COMMENT = 'Date rep was hired',
    
    regions.region_name AS REGION_NAME
      COMMENT = 'Geographic region name',
    regions.country AS COUNTRY
      COMMENT = 'Country'
  )

  METRICS (
    sales.total_revenue_sum AS SUM(TOTAL_REVENUE)
      COMMENT = 'Total revenue',
    sales.total_cost_sum AS SUM(TOTAL_COST)
      COMMENT = 'Total cost of goods sold',
    sales.gross_profit_sum AS SUM(TOTAL_REVENUE - TOTAL_COST)
      COMMENT = 'Total gross profit',
    sales.transaction_count AS COUNT(TRANSACTION_ID)
      COMMENT = 'Number of transactions',
    sales.total_units AS SUM(QUANTITY)
      COMMENT = 'Total units sold',
    sales.avg_order_value AS AVG(TOTAL_REVENUE)
      COMMENT = 'Average order value',
    sales.avg_discount AS AVG(DISCOUNT_PERCENT)
      COMMENT = 'Average discount percentage'
  )

  COMMENT = 'DEMO: Semantic view for sales analytics (Expires: 2026-02-28)';

-- Grant access to the semantic view
GRANT USAGE ON SEMANTIC VIEW SV_MAO_SALES_ANALYTICS TO ROLE PUBLIC;
