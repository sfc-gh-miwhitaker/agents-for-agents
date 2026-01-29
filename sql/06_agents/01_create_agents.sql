/*
================================================================================
CREATE AGENTS - Cortex Agent Definitions
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates Cortex Agents using the new SQL-based CREATE AGENT syntax.

IMPORTANT API Changes (Post-September 2025):
- Use CREATE AGENT SQL statement (not API calls)
- Use 'semantic_view' resource type (not 'semantic_model_file')  
- Model selection via 'orchestration: auto' for automatic selection
- Budget configuration with seconds and tokens limits
- Threads API manages conversation context server-side
================================================================================
*/

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- MAIN AGENT: Business Analytics Assistant
-- =============================================================================
-- This agent orchestrates multiple tools to answer complex business questions:
-- 1. Cortex Analyst (text-to-SQL) for structured data queries
-- 2. Cortex Search for policy/document retrieval
-- 3. Custom UDFs for specialized calculations
-- =============================================================================

CREATE OR REPLACE AGENT BUSINESS_ANALYTICS_ASSISTANT
    COMMENT = 'DEMO: Multi-tool business analytics agent (Expires: 2026-02-28)'
    
    -- Model Configuration: Use 'auto' for automatic model selection
    MODEL = (
        orchestration = 'auto'
    )
    
    -- Budget Configuration: Limit resource consumption
    BUDGET = (
        seconds = 30,
        tokens = 16000
    )
    
    -- System Prompt: Define agent behavior and capabilities
    SYSTEM_PROMPT = $$
You are a Business Analytics Assistant with access to company sales data and policy documents.

YOUR CAPABILITIES:
1. **Sales Analytics** (via Cortex Analyst): Query sales transactions, revenue, products, regions, and sales rep performance using natural language. I will convert your questions to SQL automatically.

2. **Policy Lookup** (via Cortex Search): Search company policy documents including sales policies, HR policies, finance policies, and IT policies.

3. **Specialized Calculations**:
   - Calculate quota attainment for sales reps
   - Determine discount approval requirements
   - Generate revenue forecasts
   - Calculate sales commissions

GUIDELINES:
- For data questions, use the sales analytics tool to query the database
- For policy questions, search the policy documents
- For calculations like commissions or quota attainment, use the appropriate calculation tool
- Always provide context with your answers
- When showing numbers, format them appropriately (currency, percentages)
- If a question spans multiple capabilities, combine results thoughtfully
$$
    
    -- Tool Configuration
    TOOLS = (
        -- Tool 1: Cortex Analyst for text-to-SQL on sales data
        sales_analyst = (
            type = 'cortex_analyst_text_to_sql',
            semantic_view = 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_MAO_SALES_ANALYTICS',
            description = 'Query sales data including transactions, products, regions, and sales rep performance. Use this for any questions about revenue, sales figures, trends, or performance metrics.'
        ),
        
        -- Tool 2: Cortex Search for policy documents
        policy_search = (
            type = 'cortex_search',
            cortex_search_service = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_SEARCH_SERVICE',
            max_results = 5,
            description = 'Search company policy documents. Use this for questions about company policies, procedures, guidelines, or rules.'
        ),
        
        -- Tool 3: Custom tool for quota attainment
        quota_calculator = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_QUOTA_ATTAINMENT',
            description = 'Calculate quota attainment for a sales representative. Provide the rep name to see their YTD revenue vs quota.'
        ),
        
        -- Tool 4: Custom tool for discount approval
        discount_checker = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_GET_DISCOUNT_APPROVAL',
            description = 'Check what approval is needed for a discount. Provide the discount percentage and deal value.'
        ),
        
        -- Tool 5: Custom tool for revenue forecasting
        revenue_forecaster = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_FORECAST_REVENUE',
            description = 'Generate revenue forecast based on historical data. Optionally filter by region.'
        ),
        
        -- Tool 6: Custom tool for commission calculation
        commission_calculator = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_COMMISSION',
            description = 'Calculate sales commission for a deal. Provide deal value, type (NEW/EXPANSION/RENEWAL), quota attainment, and whether multi-year.'
        )
    );

-- =============================================================================
-- GRANT ACCESS
-- =============================================================================
GRANT USAGE ON AGENT BUSINESS_ANALYTICS_ASSISTANT TO ROLE PUBLIC;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- Verify agent was created successfully
SELECT 
    AGENT_NAME,
    CREATED,
    COMMENT
FROM INFORMATION_SCHEMA.AGENTS
WHERE AGENT_NAME = 'BUSINESS_ANALYTICS_ASSISTANT';

-- Show agent details
DESCRIBE AGENT BUSINESS_ANALYTICS_ASSISTANT;
