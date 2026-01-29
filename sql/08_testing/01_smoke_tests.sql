/*
================================================================================
SMOKE TEST - Multi-Agent Orchestration Demo
Author: SE Community | Expires: 2026-02-28
================================================================================
Verifies deployment was successful. Run after deploy_all.sql completes.
================================================================================
*/

-- =============================================================================
-- VERIFY INFRASTRUCTURE
-- =============================================================================
SHOW WAREHOUSES LIKE 'SFE_MULTI_AGENT_ORCHESTRATION_WH';
SHOW SCHEMAS LIKE 'MULTI_AGENT_ORCHESTRATION' IN DATABASE SNOWFLAKE_EXAMPLE;

-- =============================================================================
-- VERIFY TABLES EXIST AND HAVE DATA
-- =============================================================================
SELECT 'DIM_PRODUCTS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT 
FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_PRODUCTS
UNION ALL
SELECT 'DIM_REGIONS', COUNT(*) 
FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_REGIONS
UNION ALL
SELECT 'DIM_SALES_REPS', COUNT(*) 
FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS
UNION ALL
SELECT 'FACT_SALES', COUNT(*) 
FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES
UNION ALL
SELECT 'POLICY_DOCUMENTS', COUNT(*) 
FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_DOCUMENTS;

-- =============================================================================
-- VERIFY SEMANTIC VIEW
-- =============================================================================
SHOW SEMANTIC VIEWS LIKE 'SV_MAO_SALES_ANALYTICS' IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

-- =============================================================================
-- VERIFY CORTEX SEARCH SERVICE
-- =============================================================================
SHOW CORTEX SEARCH SERVICES LIKE 'POLICY_SEARCH_SERVICE' IN SCHEMA SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- VERIFY CUSTOM TOOLS (UDFs)
-- =============================================================================
SHOW USER FUNCTIONS LIKE 'TOOL_%' IN SCHEMA SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- VERIFY AGENT
-- =============================================================================
SHOW AGENTS LIKE 'BUSINESS_ANALYTICS_ASSISTANT' IN SCHEMA SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- TEST AGENT INVOCATION (Simple Query)
-- =============================================================================
SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT(
    'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.BUSINESS_ANALYTICS_ASSISTANT',
    OBJECT_CONSTRUCT(
        'messages', ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT('role', 'user', 'content', 'What is the total revenue for this year?')
        )
    )
) AS AGENT_RESPONSE;

-- =============================================================================
-- SMOKE TEST COMPLETE
-- =============================================================================
SELECT 'All smoke tests completed. Review results above for any failures.' AS STATUS;
