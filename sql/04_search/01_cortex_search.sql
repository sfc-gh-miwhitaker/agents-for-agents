/*
================================================================================
CORTEX SEARCH SERVICE - Policy Documents
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates a Cortex Search service for RAG-based retrieval of company policies.
This enables the agent to answer questions about company policies using
semantic search over the policy document corpus.
================================================================================
*/

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- CORTEX SEARCH SERVICE
-- =============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE POLICY_SEARCH_SERVICE
    ON POLICY_CONTENT
    ATTRIBUTES POLICY_TITLE, POLICY_CATEGORY
    WAREHOUSE = SFE_MULTI_AGENT_ORCHESTRATION_WH
    TARGET_LAG = '1 hour'
    COMMENT = 'DEMO: Cortex Search for policy documents (Expires: 2026-02-28)'
AS (
    SELECT 
        POLICY_ID,
        POLICY_TITLE,
        POLICY_CATEGORY,
        POLICY_CONTENT,
        EFFECTIVE_DATE,
        LAST_UPDATED,
        VERSION
    FROM POLICY_DOCUMENTS
);

-- =============================================================================
-- GRANT ACCESS
-- =============================================================================
GRANT USAGE ON CORTEX SEARCH SERVICE POLICY_SEARCH_SERVICE TO ROLE PUBLIC;
