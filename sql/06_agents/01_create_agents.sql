/*
================================================================================
CREATE AGENTS - Cortex Agent Definitions
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates Cortex Agents using the FROM SPECIFICATION YAML syntax.

IMPORTANT: Current syntax (January 2026):
- Use FROM SPECIFICATION $$ ... $$ with YAML content
- 'models.orchestration' specifies the LLM (or omit for auto-selection)
- 'instructions.system' replaces SYSTEM_PROMPT
- 'tools' array with tool_spec objects
- 'tool_resources' map for tool configuration
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
  FROM SPECIFICATION
  $$
  orchestration:
    budget:
      seconds: 30
      tokens: 16000

  instructions:
    system: |
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
    orchestration: "Use sales_analyst for revenue/sales questions; use policy_search for policy questions; use custom tools for calculations"
    response: "Be concise but thorough. Format numbers appropriately."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "sales_analyst"
        description: "Query sales data including transactions, products, regions, and sales rep performance. Use this for any questions about revenue, sales figures, trends, or performance metrics."

    - tool_spec:
        type: "cortex_search"
        name: "policy_search"
        description: "Search company policy documents. Use this for questions about company policies, procedures, guidelines, or rules."

    - tool_spec:
        type: "generic"
        name: "quota_calculator"
        description: "Calculate quota attainment for a sales representative. Provide the rep name to see their YTD revenue vs quota."
        input_schema:
          type: "object"
          properties:
            rep_name:
              type: "string"
              description: "Name of the sales representative"
          required:
            - rep_name

    - tool_spec:
        type: "generic"
        name: "discount_checker"
        description: "Check what approval is needed for a discount. Provide the discount percentage and deal value."
        input_schema:
          type: "object"
          properties:
            discount_percent:
              type: "number"
              description: "Discount percentage (0-100)"
            deal_value:
              type: "number"
              description: "Total deal value in dollars"
          required:
            - discount_percent
            - deal_value

    - tool_spec:
        type: "generic"
        name: "revenue_forecaster"
        description: "Generate revenue forecast based on historical data. Optionally filter by region."
        input_schema:
          type: "object"
          properties:
            region:
              type: "string"
              description: "Optional region filter (North, South, East, West)"

    - tool_spec:
        type: "generic"
        name: "commission_calculator"
        description: "Calculate sales commission for a deal. Provide deal value, type, quota attainment, and whether multi-year."
        input_schema:
          type: "object"
          properties:
            deal_value:
              type: "number"
              description: "Deal value in dollars"
            deal_type:
              type: "string"
              description: "Type of deal: NEW, EXPANSION, or RENEWAL"
            quota_attainment:
              type: "number"
              description: "Current quota attainment as decimal (e.g., 0.85 for 85%)"
            is_multi_year:
              type: "boolean"
              description: "Whether this is a multi-year deal"
          required:
            - deal_value
            - deal_type
            - quota_attainment
            - is_multi_year

  tool_resources:
    sales_analyst:
      semantic_view: "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_MAO_SALES_ANALYTICS"

    policy_search:
      name: "SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_SEARCH_SERVICE"
      max_results: "5"

    quota_calculator:
      type: "function"
      identifier: "SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_QUOTA_ATTAINMENT"
      warehouse: "SFE_MULTI_AGENT_ORCHESTRATION_WH"

    discount_checker:
      type: "function"
      identifier: "SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_GET_DISCOUNT_APPROVAL"
      warehouse: "SFE_MULTI_AGENT_ORCHESTRATION_WH"

    revenue_forecaster:
      type: "function"
      identifier: "SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_FORECAST_REVENUE"
      warehouse: "SFE_MULTI_AGENT_ORCHESTRATION_WH"

    commission_calculator:
      type: "function"
      identifier: "SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_COMMISSION"
      warehouse: "SFE_MULTI_AGENT_ORCHESTRATION_WH"
  $$;

-- =============================================================================
-- GRANT ACCESS
-- =============================================================================
GRANT USAGE ON AGENT BUSINESS_ANALYTICS_ASSISTANT TO ROLE PUBLIC;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================
-- List agents in this schema
SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION;

-- Show agent details (specification, tools, etc.)
DESCRIBE AGENT BUSINESS_ANALYTICS_ASSISTANT;
