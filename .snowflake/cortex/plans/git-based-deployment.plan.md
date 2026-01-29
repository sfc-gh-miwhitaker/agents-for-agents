---
name: "git-based-deployment"
created: "2026-01-29T20:38:16.646Z"
status: pending
---

# Plan: Git-Based Deployment for agents-for-agents

## Current State

[deploy\_all.sql](<> "file:///Users/mwhitaker/src/agents-for-agents/deploy_all.sql") uses `!source` commands which only work in SnowSQL, not Snowsight "Run All".

## Target State

Match [Sam-the-snowman/deploy\_all.sql](<> "file:///Users/mwhitaker/src/Sam-the-snowman/deploy_all.sql") pattern:

- Git integration with `EXECUTE IMMEDIATE FROM '@repo/branches/main/sql/...'`
- DECLARE/BEGIN/END expiration block
- Single final SELECT

## Changes

### 1. Rewrite deploy\_all.sql

Replace current content with:

```
/*******************************************************************************
 * DEMO PROJECT: Multi-Agent Orchestration
 * Script: deploy_all.sql - Complete Deployment Script
 * EXPIRATION: 2026-02-28
 ******************************************************************************/

-- Expiration check
DECLARE
  demo_expired EXCEPTION (-20001, 'DEMO EXPIRED');
BEGIN
  IF (CURRENT_DATE() > '2026-02-28'::DATE) THEN
    RAISE demo_expired;
  END IF;
END;

-- Phase 1: Infrastructure
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE WAREHOUSE SFE_MULTI_AGENT_ORCHESTRATION_WH ...;
CREATE OR REPLACE API INTEGRATION SFE_GITHUB_API_INTEGRATION ...;

USE ROLE SYSADMIN;
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO
    API_INTEGRATION = SFE_GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/agents-for-agents.git';
ALTER GIT REPOSITORY ... FETCH;

-- Phase 2: Module Execution
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO/branches/main/sql/01_sales_data.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO/branches/main/sql/02_policy_data.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO/branches/main/sql/03_semantic_view.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO/branches/main/sql/04_cortex_search.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO/branches/main/sql/05_custom_tools.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO/branches/main/sql/06_create_agent.sql';

-- Deployment Complete
SELECT 'DEPLOYMENT COMPLETE' AS status, ...;
```

### 2. Flatten sql/ Directory

Current structure:

```
sql/
├── 01_setup/01_infrastructure.sql
├── 02_data/01_sales_data.sql
├── 02_data/02_policy_data.sql
...
```

New structure:

```
sql/
├── 01_sales_data.sql
├── 02_policy_data.sql
├── 03_semantic_view.sql
├── 04_cortex_search.sql
├── 05_custom_tools.sql
├── 06_create_agent.sql
└── 99_teardown.sql
```

Infrastructure setup moves inline into deploy\_all.sql (like Sam-the-snowman Phase 1).

### 3. Update teardown\_all.sql

Add cleanup for Git repository:

```
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_AGENTS_FOR_AGENTS_REPO;
```

## Files to Modify

| File                                     | Action                              |
| ---------------------------------------- | ----------------------------------- |
| deploy\_all.sql                          | Rewrite completely                  |
| sql/01\_setup/01\_infrastructure.sql     | Delete (move inline)                |
| sql/02\_data/01\_sales\_data.sql         | Move to sql/01\_sales\_data.sql     |
| sql/02\_data/02\_policy\_data.sql        | Move to sql/02\_policy\_data.sql    |
| sql/03\_semantic/01\_semantic\_view\.sql | Move to sql/03\_semantic\_view\.sql |
| sql/04\_search/01\_cortex\_search.sql    | Move to sql/04\_cortex\_search.sql  |
| sql/05\_tools/01\_custom\_tools.sql      | Move to sql/05\_custom\_tools.sql   |
| sql/06\_agents/01\_create\_agents.sql    | Move to sql/06\_create\_agent.sql   |
| teardown\_all.sql                        | Add Git repo cleanup                |
