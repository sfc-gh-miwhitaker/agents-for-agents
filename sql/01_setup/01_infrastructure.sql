/*
================================================================================
INFRASTRUCTURE SETUP - Multi-Agent Orchestration Demo
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates the foundational infrastructure for the multi-agent orchestration demo.
*/

-- =============================================================================
-- WAREHOUSE
-- =============================================================================
CREATE WAREHOUSE IF NOT EXISTS SFE_MULTI_AGENT_ORCHESTRATION_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Multi-Agent Orchestration warehouse (Expires: 2026-02-28)';

USE WAREHOUSE SFE_MULTI_AGENT_ORCHESTRATION_WH;

-- =============================================================================
-- DATABASE (Using shared SNOWFLAKE_EXAMPLE)
-- =============================================================================
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'Shared database for Snowflake demo projects';

USE DATABASE SNOWFLAKE_EXAMPLE;

-- =============================================================================
-- SCHEMA (Project namespace - collision-proof)
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS MULTI_AGENT_ORCHESTRATION
    COMMENT = 'DEMO: Multi-Agent Orchestration - Business analytics with Cortex Agents (Expires: 2026-02-28)';

-- Shared schema for semantic views (if not exists)
CREATE SCHEMA IF NOT EXISTS SEMANTIC_MODELS
    COMMENT = 'Shared schema for semantic views used by Cortex Analyst';

USE SCHEMA MULTI_AGENT_ORCHESTRATION;
