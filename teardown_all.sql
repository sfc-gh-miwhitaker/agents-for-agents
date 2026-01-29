/*
================================================================================
TEARDOWN ALL - Multi-Agent Orchestration Demo Cleanup
Author: SE Community | Expires: 2026-02-28
================================================================================
INSTRUCTIONS: Open in Snowsight → Click "Run All"
WARNING: This will delete ALL objects created by this demo!
================================================================================
*/

-- =============================================================================
-- DROP AGENT (must drop before schema)
-- =============================================================================
DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.BUSINESS_ANALYTICS_ASSISTANT;

-- =============================================================================
-- DROP CORTEX SEARCH SERVICE (must drop before schema)
-- =============================================================================
DROP CORTEX SEARCH SERVICE IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_SEARCH_SERVICE;

-- =============================================================================
-- DROP SEMANTIC VIEW (in shared schema - drop view only, keep schema)
-- =============================================================================
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_MAO_SALES_ANALYTICS;

-- =============================================================================
-- DROP PROJECT SCHEMA (CASCADE removes all tables, views, functions, etc.)
-- =============================================================================
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION CASCADE;

-- =============================================================================
-- DROP PROJECT WAREHOUSE
-- =============================================================================
DROP WAREHOUSE IF EXISTS SFE_MULTI_AGENT_ORCHESTRATION_WH;

-- =============================================================================
-- PROTECTED - NEVER DROP:
-- - SNOWFLAKE_EXAMPLE database (shared)
-- - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema (shared)
-- - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared)
-- - SFE_GIT_API_INTEGRATION (shared)
-- =============================================================================

SELECT 'Teardown complete!' AS status, CURRENT_TIMESTAMP() AS completed_at;
