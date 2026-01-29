/*
================================================================================
TEARDOWN ALL - Multi-Agent Orchestration Demo Cleanup
Author: SE Community | Expires: 2026-02-28
================================================================================
INSTRUCTIONS: Run this script to completely remove the demo from your account.
WARNING: This will delete ALL objects created by this demo!
================================================================================
*/

-- =============================================================================
-- DROP AGENT
-- =============================================================================
DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.BUSINESS_ANALYTICS_ASSISTANT;

-- =============================================================================
-- DROP CORTEX SEARCH SERVICE  
-- =============================================================================
DROP CORTEX SEARCH SERVICE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_SEARCH_SERVICE;

-- =============================================================================
-- DROP SEMANTIC VIEW
-- =============================================================================
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_MAO_SALES_ANALYTICS;

-- =============================================================================
-- DROP CUSTOM TOOLS (UDFs)
-- =============================================================================
DROP FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_QUOTA_ATTAINMENT(VARCHAR, DATE);
DROP FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_GET_DISCOUNT_APPROVAL(DECIMAL, DECIMAL);
DROP FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_FORECAST_REVENUE(INT, VARCHAR);
DROP FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_COMMISSION(DECIMAL, VARCHAR, DECIMAL, BOOLEAN);

-- =============================================================================
-- DROP VIEWS
-- =============================================================================
DROP VIEW IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.V_SALES_SUMMARY;

-- =============================================================================
-- DROP TABLES
-- =============================================================================
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_REGIONS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_PRODUCTS;
DROP TABLE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_DOCUMENTS;

-- =============================================================================
-- DROP SCHEMA
-- =============================================================================
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION;

-- Note: We don't drop SEMANTIC_MODELS schema as it may be shared with other demos
-- Note: We don't drop SNOWFLAKE_EXAMPLE database as it's a shared database

-- =============================================================================
-- DROP WAREHOUSE
-- =============================================================================
DROP WAREHOUSE IF EXISTS SFE_MULTI_AGENT_ORCHESTRATION_WH;

-- =============================================================================
-- CONFIRMATION
-- =============================================================================
SELECT 'Multi-Agent Orchestration demo has been completely removed.' AS STATUS;
