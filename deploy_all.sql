/*
================================================================================
DEPLOY ALL - Multi-Agent Orchestration Demo
Author: SE Community | Expires: 2026-02-28
================================================================================
INSTRUCTIONS: Open in Snowsight → Click "Run All"

This demo showcases Snowflake Cortex Agents with multi-tool orchestration:
- Cortex Analyst (text-to-SQL via Semantic Views)
- Cortex Search (RAG over policy documents)
- Custom Tools (UDFs for specialized calculations)

Prerequisites:
- ACCOUNTADMIN or role with CREATE WAREHOUSE, CREATE DATABASE privileges
- Cortex features enabled in your account
- Git repository integration (see setup below)
================================================================================
*/

-- =============================================================================
-- EXPIRATION CHECK
-- =============================================================================
DECLARE
    demo_expired EXCEPTION (-20001, 'DEMO EXPIRED: This demo expired on 2026-02-28. Please obtain an updated version or fork and update expiration dates.');
BEGIN
    IF (CURRENT_DATE() > '2026-02-28'::DATE) THEN
        RAISE demo_expired;
    END IF;
END;

-- =============================================================================
-- GIT REPOSITORY SETUP (Run once per account)
-- =============================================================================
-- If not already configured, create the Git repository integration:
--
-- USE ROLE ACCOUNTADMIN;
-- CREATE OR REPLACE API INTEGRATION SFE_GIT_API_INTEGRATION
--     API_PROVIDER = git_https_api
--     API_ALLOWED_PREFIXES = ('https://github.com/')
--     ENABLED = TRUE;
--
-- CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO
--     API_INTEGRATION = SFE_GIT_API_INTEGRATION
--     ORIGIN = 'https://github.com/Snowflake-Labs/agents-for-agents';
-- =============================================================================

-- Fetch latest from Git repository
USE ROLE SYSADMIN;
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO FETCH;

-- =============================================================================
-- EXECUTE DEPLOYMENT SCRIPTS
-- =============================================================================

-- 01 SETUP: Infrastructure (warehouse, database, schemas)
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/01_setup/01_infrastructure.sql';

-- 02 DATA: Sample data for sales and policies
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/02_data/01_sales_data.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/02_data/02_policy_data.sql';

-- 03 SEMANTIC: Semantic View for Cortex Analyst
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/03_semantic/01_semantic_view.sql';

-- 04 SEARCH: Cortex Search Service
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/04_search/01_cortex_search.sql';

-- 05 TOOLS: Custom UDFs for agent use
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/05_tools/01_custom_tools.sql';

-- 06 AGENTS: Create Cortex Agent
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO/branches/main/sql/06_agents/01_create_agents.sql';

-- =============================================================================
-- DEPLOYMENT COMPLETE
-- =============================================================================
SELECT 'Deployment complete!' AS status,
       'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION' AS schema,
       'BUSINESS_ANALYTICS_ASSISTANT' AS agent,
       '2026-02-28' AS expires,
       CURRENT_TIMESTAMP() AS completed_at;
