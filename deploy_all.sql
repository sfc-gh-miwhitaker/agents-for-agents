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
================================================================================
*/

-- =============================================================================
-- EXPIRATION CHECK
-- =============================================================================
-- This demo expires on 2026-02-28. Fail fast if expired.
SET demo_expiration = '2026-02-28'::DATE;
SET demo_name = 'Multi-Agent Orchestration';

SELECT 
    CASE 
        WHEN CURRENT_DATE() > $demo_expiration 
        THEN 'ERROR: This demo expired on ' || $demo_expiration || '. Please obtain an updated version.'
        ELSE 'Demo valid until ' || $demo_expiration || '. Proceeding with deployment...'
    END AS deployment_status;

-- Halt execution if expired (will error on next statement if expired)
SELECT IFF(
    CURRENT_DATE() > $demo_expiration,
    1/0,  -- Force error if expired
    1
) AS expiration_check;

-- =============================================================================
-- 01 SETUP: Infrastructure
-- =============================================================================

-- Warehouse
CREATE WAREHOUSE IF NOT EXISTS SFE_MULTI_AGENT_ORCHESTRATION_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Multi-Agent Orchestration warehouse (Expires: 2026-02-28)';

USE WAREHOUSE SFE_MULTI_AGENT_ORCHESTRATION_WH;

-- Database (shared)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'Shared database for Snowflake demo projects';

USE DATABASE SNOWFLAKE_EXAMPLE;

-- Schemas
CREATE SCHEMA IF NOT EXISTS MULTI_AGENT_ORCHESTRATION
    COMMENT = 'DEMO: Multi-Agent Orchestration - Business analytics with Cortex Agents (Expires: 2026-02-28)';

CREATE SCHEMA IF NOT EXISTS SEMANTIC_MODELS
    COMMENT = 'Shared schema for semantic views used by Cortex Analyst';

USE SCHEMA MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- 02 DATA: Sales Analytics Tables
-- =============================================================================

-- Products dimension
CREATE OR REPLACE TABLE DIM_PRODUCTS (
    PRODUCT_ID INT PRIMARY KEY,
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(50),
    SUBCATEGORY VARCHAR(50),
    UNIT_COST DECIMAL(10,2),
    UNIT_PRICE DECIMAL(10,2)
);

INSERT INTO DIM_PRODUCTS VALUES
    (1, 'Enterprise Analytics Suite', 'Software', 'Analytics', 5000.00, 12000.00),
    (2, 'Data Integration Platform', 'Software', 'ETL', 3000.00, 8000.00),
    (3, 'Cloud Storage - 1TB', 'Infrastructure', 'Storage', 50.00, 150.00),
    (4, 'Compute Credits - 1000', 'Infrastructure', 'Compute', 200.00, 500.00),
    (5, 'Professional Services - Day', 'Services', 'Consulting', 800.00, 2000.00),
    (6, 'Training Package', 'Services', 'Education', 500.00, 1500.00),
    (7, 'Security Module', 'Software', 'Security', 2000.00, 5000.00),
    (8, 'AI/ML Toolkit', 'Software', 'AI', 4000.00, 10000.00),
    (9, 'Support - Premium', 'Services', 'Support', 1000.00, 3000.00),
    (10, 'Data Sharing License', 'Software', 'Collaboration', 1500.00, 4000.00);

-- Regions dimension
CREATE OR REPLACE TABLE DIM_REGIONS (
    REGION_ID INT PRIMARY KEY,
    REGION_NAME VARCHAR(50),
    COUNTRY VARCHAR(50),
    TIMEZONE VARCHAR(50)
);

INSERT INTO DIM_REGIONS VALUES
    (1, 'North America - West', 'USA', 'America/Los_Angeles'),
    (2, 'North America - East', 'USA', 'America/New_York'),
    (3, 'North America - Central', 'USA', 'America/Chicago'),
    (4, 'Europe - West', 'UK', 'Europe/London'),
    (5, 'Europe - Central', 'Germany', 'Europe/Berlin'),
    (6, 'Asia Pacific - East', 'Japan', 'Asia/Tokyo'),
    (7, 'Asia Pacific - South', 'Australia', 'Australia/Sydney'),
    (8, 'Latin America', 'Brazil', 'America/Sao_Paulo');

-- Sales reps dimension
CREATE OR REPLACE TABLE DIM_SALES_REPS (
    REP_ID INT PRIMARY KEY,
    REP_NAME VARCHAR(100),
    REGION_ID INT REFERENCES DIM_REGIONS(REGION_ID),
    HIRE_DATE DATE,
    QUOTA DECIMAL(12,2)
);

INSERT INTO DIM_SALES_REPS VALUES
    (1, 'Sarah Chen', 1, '2022-03-15', 2000000.00),
    (2, 'Marcus Johnson', 2, '2021-06-01', 2500000.00),
    (3, 'Emily Rodriguez', 3, '2023-01-10', 1500000.00),
    (4, 'James Wilson', 4, '2020-09-20', 2200000.00),
    (5, 'Anna Schmidt', 5, '2022-07-05', 1800000.00),
    (6, 'Kenji Tanaka', 6, '2021-11-15', 2100000.00),
    (7, 'Lisa Park', 7, '2023-04-01', 1600000.00),
    (8, 'Carlos Silva', 8, '2022-02-28', 1400000.00);

-- Fact table: Sales transactions
CREATE OR REPLACE TABLE FACT_SALES (
    TRANSACTION_ID INT PRIMARY KEY,
    TRANSACTION_DATE DATE,
    PRODUCT_ID INT REFERENCES DIM_PRODUCTS(PRODUCT_ID),
    REP_ID INT REFERENCES DIM_SALES_REPS(REP_ID),
    QUANTITY INT,
    DISCOUNT_PERCENT DECIMAL(5,2),
    TOTAL_REVENUE DECIMAL(12,2),
    TOTAL_COST DECIMAL(12,2)
);

-- Generate 12 months of sales data
INSERT INTO FACT_SALES
WITH date_range AS (
    SELECT DATEADD(day, SEQ4(), DATEADD(month, -12, CURRENT_DATE())) AS sale_date
    FROM TABLE(GENERATOR(ROWCOUNT => 365))
),
transactions AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY d.sale_date, p.PRODUCT_ID) AS TRANSACTION_ID,
        d.sale_date AS TRANSACTION_DATE,
        p.PRODUCT_ID,
        r.REP_ID,
        UNIFORM(1, 10, RANDOM()) AS QUANTITY,
        ROUND(UNIFORM(0, 20, RANDOM()), 2) AS DISCOUNT_PERCENT,
        p.UNIT_PRICE,
        p.UNIT_COST
    FROM date_range d
    CROSS JOIN DIM_PRODUCTS p
    CROSS JOIN DIM_SALES_REPS r
    WHERE UNIFORM(0, 100, RANDOM()) < 15
)
SELECT 
    TRANSACTION_ID,
    TRANSACTION_DATE,
    PRODUCT_ID,
    REP_ID,
    QUANTITY,
    DISCOUNT_PERCENT,
    ROUND(QUANTITY * UNIT_PRICE * (1 - DISCOUNT_PERCENT/100), 2) AS TOTAL_REVENUE,
    ROUND(QUANTITY * UNIT_COST, 2) AS TOTAL_COST
FROM transactions;

-- Summary view
CREATE OR REPLACE VIEW V_SALES_SUMMARY AS
SELECT 
    fs.TRANSACTION_DATE,
    dp.PRODUCT_NAME,
    dp.CATEGORY,
    dr.REGION_NAME,
    ds.REP_NAME,
    fs.QUANTITY,
    fs.TOTAL_REVENUE,
    fs.TOTAL_COST,
    fs.TOTAL_REVENUE - fs.TOTAL_COST AS GROSS_PROFIT,
    ROUND((fs.TOTAL_REVENUE - fs.TOTAL_COST) / NULLIF(fs.TOTAL_REVENUE, 0) * 100, 2) AS PROFIT_MARGIN_PCT
FROM FACT_SALES fs
JOIN DIM_PRODUCTS dp ON fs.PRODUCT_ID = dp.PRODUCT_ID
JOIN DIM_SALES_REPS ds ON fs.REP_ID = ds.REP_ID
JOIN DIM_REGIONS dr ON ds.REGION_ID = dr.REGION_ID;

-- =============================================================================
-- 02 DATA: Policy Documents (for Cortex Search)
-- =============================================================================

CREATE OR REPLACE TABLE POLICY_DOCUMENTS (
    POLICY_ID INT PRIMARY KEY,
    POLICY_TITLE VARCHAR(200),
    POLICY_CATEGORY VARCHAR(50),
    POLICY_CONTENT TEXT,
    EFFECTIVE_DATE DATE,
    LAST_UPDATED DATE,
    VERSION VARCHAR(10)
);

INSERT INTO POLICY_DOCUMENTS VALUES
(1, 'Discount Authorization Policy', 'Sales', 
'DISCOUNT AUTHORIZATION POLICY

1. STANDARD DISCOUNTS (No approval required):
   - Up to 10% for annual contracts
   - Up to 5% for multi-year commitments
   - Up to 15% for enterprise deals over $500,000

2. ELEVATED DISCOUNTS (Manager approval required):
   - 11-20% discounts require Sales Manager approval
   - Must document competitive pressure or strategic value
   - Approval valid for 30 days from request

3. EXCEPTIONAL DISCOUNTS (VP approval required):
   - Discounts over 20% require VP Sales approval
   - Must include written business justification
   - Quarterly review of all exceptional discounts',
'2025-01-01', '2025-11-15', '2.1'),

(2, 'Commission Structure Policy', 'Sales',
'COMMISSION STRUCTURE POLICY

1. BASE COMMISSION RATES:
   - New Business: 10% of first-year contract value
   - Expansion: 7% of incremental annual value
   - Renewal: 3% of renewal value

2. ACCELERATORS:
   - 1.5x multiplier when exceeding 100% of quota
   - 2.0x multiplier when exceeding 150% of quota
   - Additional 5% bonus for multi-year deals

3. PAYMENT SCHEDULE:
   - 50% paid upon signed contract
   - 50% paid upon first payment received
   - Clawback period: 90 days from customer payment',
'2025-01-01', '2025-10-01', '3.0'),

(3, 'Expense Reimbursement Policy', 'Finance',
'EXPENSE REIMBURSEMENT POLICY

1. TRAVEL EXPENSES:
   - Airfare: Economy class for flights under 6 hours
   - Hotels: Up to $250/night (higher in major metros with approval)
   - Meals: $75/day per diem or actuals with receipts
   - Ground transport: Rideshare preferred, rental car with approval

2. CLIENT ENTERTAINMENT:
   - Pre-approval required for expenses over $500
   - Maximum $150/person for client meals
   - Quarterly entertainment budget per rep: $2,000

3. SUBMISSION REQUIREMENTS:
   - Submit within 30 days of expense
   - Itemized receipts required for all expenses over $25',
'2025-03-01', '2025-11-01', '2.5'),

(4, 'Work From Home Policy', 'Human Resources',
'WORK FROM HOME POLICY

1. ELIGIBILITY:
   - All employees after 90-day onboarding period
   - Role must be suitable for remote work
   - Performance must be in good standing

2. SCHEDULE OPTIONS:
   - Hybrid: 2-3 days in office per week
   - Remote-first: Quarterly in-person meetings required
   - Full office: Available for those who prefer

3. EQUIPMENT STIPEND:
   - One-time $500 home office setup
   - $50/month internet subsidy for full remote',
'2025-01-01', '2025-08-15', '3.2'),

(5, 'AI and Machine Learning Usage Policy', 'Information Technology',
'AI AND MACHINE LEARNING USAGE POLICY

1. APPROVED AI TOOLS:
   - Snowflake Cortex (internal data analysis)
   - Company-approved LLM integrations only
   - Custom models require ML Platform review

2. DATA RESTRICTIONS:
   - No customer PII in external AI tools
   - No confidential financial data in public AI
   - Internal data stays in approved environments

3. RESPONSIBLE AI PRINCIPLES:
   - Transparency: Document AI involvement
   - Fairness: Test for bias in models
   - Accountability: Human oversight required',
'2025-06-01', '2025-11-20', '1.0');

ALTER TABLE POLICY_DOCUMENTS SET SEARCH OPTIMIZATION = ON;

-- =============================================================================
-- 03 SEMANTIC: Semantic View for Cortex Analyst
-- =============================================================================

USE SCHEMA SEMANTIC_MODELS;

CREATE OR REPLACE SEMANTIC VIEW SV_MAO_SALES_ANALYTICS
    COMMENT = 'DEMO: Semantic view for multi-agent orchestration sales analytics (Expires: 2026-02-28)'
AS
DEFINE TABLES (
    sales_transactions AS (
        SELECT 
            TRANSACTION_ID,
            TRANSACTION_DATE,
            PRODUCT_ID,
            REP_ID,
            QUANTITY,
            DISCOUNT_PERCENT,
            TOTAL_REVENUE,
            TOTAL_COST,
            TOTAL_REVENUE - TOTAL_COST AS GROSS_PROFIT
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES
    )
    WITH MEASURES (
        total_revenue DECIMAL(12,2) AS SUM(TOTAL_REVENUE) 
            WITH DESCRIPTION = 'Total revenue from sales transactions',
        total_cost DECIMAL(12,2) AS SUM(TOTAL_COST)
            WITH DESCRIPTION = 'Total cost of goods sold',
        gross_profit DECIMAL(12,2) AS SUM(GROSS_PROFIT)
            WITH DESCRIPTION = 'Gross profit (revenue minus cost)',
        profit_margin DECIMAL(5,2) AS (SUM(GROSS_PROFIT) / NULLIF(SUM(TOTAL_REVENUE), 0) * 100)
            WITH DESCRIPTION = 'Profit margin as a percentage',
        transaction_count INT AS COUNT(TRANSACTION_ID)
            WITH DESCRIPTION = 'Number of sales transactions',
        total_quantity INT AS SUM(QUANTITY)
            WITH DESCRIPTION = 'Total units sold',
        average_order_value DECIMAL(12,2) AS AVG(TOTAL_REVENUE)
            WITH DESCRIPTION = 'Average revenue per transaction'
    )
    WITH DIMENSIONS (
        transaction_date DATE AS TRANSACTION_DATE
            WITH DESCRIPTION = 'Date of the sales transaction'
            WITH TIME_SPINE,
        product_id INT AS PRODUCT_ID
            WITH DESCRIPTION = 'Foreign key to product dimension',
        rep_id INT AS REP_ID
            WITH DESCRIPTION = 'Foreign key to sales rep dimension'
    ),

    products AS (
        SELECT PRODUCT_ID, PRODUCT_NAME, CATEGORY, SUBCATEGORY, UNIT_COST, UNIT_PRICE
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_PRODUCTS
    )
    WITH PRIMARY KEY (PRODUCT_ID)
    WITH DIMENSIONS (
        product_id INT AS PRODUCT_ID WITH DESCRIPTION = 'Unique product identifier',
        product_name VARCHAR(100) AS PRODUCT_NAME WITH DESCRIPTION = 'Name of the product',
        category VARCHAR(50) AS CATEGORY WITH DESCRIPTION = 'Product category',
        subcategory VARCHAR(50) AS SUBCATEGORY WITH DESCRIPTION = 'Product subcategory'
    ),

    sales_reps AS (
        SELECT REP_ID, REP_NAME, REGION_ID, HIRE_DATE, QUOTA
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS
    )
    WITH PRIMARY KEY (REP_ID)
    WITH DIMENSIONS (
        rep_id INT AS REP_ID WITH DESCRIPTION = 'Unique sales rep identifier',
        rep_name VARCHAR(100) AS REP_NAME WITH DESCRIPTION = 'Sales representative name',
        region_id INT AS REGION_ID WITH DESCRIPTION = 'Foreign key to region',
        quota DECIMAL(12,2) AS QUOTA WITH DESCRIPTION = 'Annual sales quota'
    ),

    regions AS (
        SELECT REGION_ID, REGION_NAME, COUNTRY, TIMEZONE
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_REGIONS
    )
    WITH PRIMARY KEY (REGION_ID)
    WITH DIMENSIONS (
        region_id INT AS REGION_ID WITH DESCRIPTION = 'Unique region identifier',
        region_name VARCHAR(50) AS REGION_NAME WITH DESCRIPTION = 'Region name',
        country VARCHAR(50) AS COUNTRY WITH DESCRIPTION = 'Country'
    )
)
DEFINE RELATIONSHIPS (
    sales_transactions.product_id REFERENCES products.product_id,
    sales_transactions.rep_id REFERENCES sales_reps.rep_id,
    sales_reps.region_id REFERENCES regions.region_id
);

GRANT USAGE ON SEMANTIC VIEW SV_MAO_SALES_ANALYTICS TO ROLE PUBLIC;

-- =============================================================================
-- 04 SEARCH: Cortex Search Service
-- =============================================================================

USE SCHEMA MULTI_AGENT_ORCHESTRATION;

CREATE OR REPLACE CORTEX SEARCH SERVICE POLICY_SEARCH_SERVICE
    ON POLICY_CONTENT
    ATTRIBUTES POLICY_TITLE, POLICY_CATEGORY
    WAREHOUSE = SFE_MULTI_AGENT_ORCHESTRATION_WH
    TARGET_LAG = '1 hour'
    COMMENT = 'DEMO: Cortex Search for policy documents (Expires: 2026-02-28)'
AS (
    SELECT 
        POLICY_ID, POLICY_TITLE, POLICY_CATEGORY, POLICY_CONTENT,
        EFFECTIVE_DATE, LAST_UPDATED, VERSION
    FROM POLICY_DOCUMENTS
);

GRANT USAGE ON CORTEX SEARCH SERVICE POLICY_SEARCH_SERVICE TO ROLE PUBLIC;

-- =============================================================================
-- 05 TOOLS: Custom UDFs
-- =============================================================================

CREATE OR REPLACE FUNCTION TOOL_CALCULATE_QUOTA_ATTAINMENT(
    rep_name VARCHAR,
    as_of_date DATE DEFAULT CURRENT_DATE()
)
RETURNS TABLE (
    rep_name VARCHAR,
    quota DECIMAL(12,2),
    ytd_revenue DECIMAL(12,2),
    quota_attainment_pct DECIMAL(5,2),
    status VARCHAR
)
LANGUAGE SQL
COMMENT = 'Calculates quota attainment for a sales rep.'
AS
$$
    SELECT 
        sr.REP_NAME,
        sr.QUOTA,
        COALESCE(SUM(fs.TOTAL_REVENUE), 0) AS YTD_REVENUE,
        ROUND(COALESCE(SUM(fs.TOTAL_REVENUE), 0) / NULLIF(sr.QUOTA, 0) * 100, 2) AS QUOTA_ATTAINMENT_PCT,
        CASE 
            WHEN COALESCE(SUM(fs.TOTAL_REVENUE), 0) / NULLIF(sr.QUOTA, 0) >= 1.0 THEN 'EXCEEDED'
            WHEN COALESCE(SUM(fs.TOTAL_REVENUE), 0) / NULLIF(sr.QUOTA, 0) >= 0.75 THEN 'ON_TRACK'
            WHEN COALESCE(SUM(fs.TOTAL_REVENUE), 0) / NULLIF(sr.QUOTA, 0) >= 0.5 THEN 'AT_RISK'
            ELSE 'BEHIND'
        END AS STATUS
    FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS sr
    LEFT JOIN SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES fs 
        ON sr.REP_ID = fs.REP_ID 
        AND fs.TRANSACTION_DATE >= DATE_TRUNC('year', as_of_date)
        AND fs.TRANSACTION_DATE <= as_of_date
    WHERE LOWER(sr.REP_NAME) LIKE LOWER('%' || rep_name || '%')
    GROUP BY sr.REP_NAME, sr.QUOTA
$$;

CREATE OR REPLACE FUNCTION TOOL_GET_DISCOUNT_APPROVAL(
    discount_percent DECIMAL(5,2),
    deal_value DECIMAL(12,2)
)
RETURNS TABLE (
    discount_level VARCHAR,
    approval_required VARCHAR,
    max_days_valid INT,
    notes VARCHAR
)
LANGUAGE SQL
COMMENT = 'Determines discount approval requirements.'
AS
$$
    SELECT 
        CASE 
            WHEN discount_percent <= 10 THEN 'STANDARD'
            WHEN discount_percent <= 15 AND deal_value >= 500000 THEN 'STANDARD - Enterprise'
            WHEN discount_percent <= 20 THEN 'ELEVATED'
            ELSE 'EXCEPTIONAL'
        END AS DISCOUNT_LEVEL,
        CASE 
            WHEN discount_percent <= 10 THEN 'No approval required'
            WHEN discount_percent <= 15 AND deal_value >= 500000 THEN 'No approval required'
            WHEN discount_percent <= 20 THEN 'Sales Manager approval required'
            ELSE 'VP Sales approval required'
        END AS APPROVAL_REQUIRED,
        CASE 
            WHEN discount_percent <= 15 THEN NULL
            WHEN discount_percent <= 20 THEN 30
            ELSE 14
        END AS MAX_DAYS_VALID,
        CASE 
            WHEN discount_percent <= 15 THEN 'Standard discount within policy'
            WHEN discount_percent <= 20 THEN 'Document competitive pressure'
            ELSE 'Written business justification required'
        END AS NOTES
$$;

CREATE OR REPLACE FUNCTION TOOL_CALCULATE_COMMISSION(
    deal_value DECIMAL(12,2),
    deal_type VARCHAR,
    quota_attainment_pct DECIMAL(5,2) DEFAULT 100,
    is_multi_year BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    base_rate DECIMAL(5,2),
    accelerator DECIMAL(3,2),
    multi_year_bonus DECIMAL(5,2),
    total_commission DECIMAL(12,2),
    breakdown VARCHAR
)
LANGUAGE SQL
COMMENT = 'Calculates sales commission based on policy.'
AS
$$
    SELECT 
        CASE UPPER(deal_type)
            WHEN 'NEW' THEN 10.0
            WHEN 'EXPANSION' THEN 7.0
            WHEN 'RENEWAL' THEN 3.0
            ELSE 5.0
        END AS BASE_RATE,
        CASE 
            WHEN quota_attainment_pct >= 150 THEN 2.0
            WHEN quota_attainment_pct >= 100 THEN 1.5
            ELSE 1.0
        END AS ACCELERATOR,
        CASE WHEN is_multi_year THEN 5.0 ELSE 0.0 END AS MULTI_YEAR_BONUS,
        ROUND(
            deal_value * 
            (CASE UPPER(deal_type) WHEN 'NEW' THEN 0.10 WHEN 'EXPANSION' THEN 0.07 WHEN 'RENEWAL' THEN 0.03 ELSE 0.05 END) *
            (CASE WHEN quota_attainment_pct >= 150 THEN 2.0 WHEN quota_attainment_pct >= 100 THEN 1.5 ELSE 1.0 END) +
            (CASE WHEN is_multi_year THEN deal_value * 0.05 ELSE 0 END),
            2
        ) AS TOTAL_COMMISSION,
        'Base: ' || CASE UPPER(deal_type) WHEN 'NEW' THEN '10%' WHEN 'EXPANSION' THEN '7%' WHEN 'RENEWAL' THEN '3%' ELSE '5%' END ||
        ' x Accelerator: ' || CASE WHEN quota_attainment_pct >= 150 THEN '2.0x' WHEN quota_attainment_pct >= 100 THEN '1.5x' ELSE '1.0x' END ||
        CASE WHEN is_multi_year THEN ' + 5% multi-year bonus' ELSE '' END AS BREAKDOWN
$$;

GRANT USAGE ON FUNCTION TOOL_CALCULATE_QUOTA_ATTAINMENT(VARCHAR, DATE) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION TOOL_GET_DISCOUNT_APPROVAL(DECIMAL, DECIMAL) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION TOOL_CALCULATE_COMMISSION(DECIMAL, VARCHAR, DECIMAL, BOOLEAN) TO ROLE PUBLIC;

-- =============================================================================
-- 06 AGENTS: Create Cortex Agent
-- =============================================================================

CREATE OR REPLACE AGENT BUSINESS_ANALYTICS_ASSISTANT
    COMMENT = 'DEMO: Multi-tool business analytics agent (Expires: 2026-02-28)'
    
    MODEL = (
        orchestration = 'auto'
    )
    
    BUDGET = (
        seconds = 30,
        tokens = 16000
    )
    
    SYSTEM_PROMPT = $$
You are a Business Analytics Assistant with access to company sales data and policy documents.

YOUR CAPABILITIES:
1. **Sales Analytics** (via Cortex Analyst): Query sales transactions, revenue, products, regions, and sales rep performance using natural language.

2. **Policy Lookup** (via Cortex Search): Search company policy documents including sales, HR, finance, and IT policies.

3. **Specialized Calculations**:
   - Calculate quota attainment for sales reps
   - Determine discount approval requirements
   - Calculate sales commissions

GUIDELINES:
- For data questions, use the sales analytics tool
- For policy questions, search the policy documents
- For calculations, use the appropriate calculation tool
- Always provide context with your answers
- Format numbers appropriately (currency, percentages)
$$
    
    TOOLS = (
        sales_analyst = (
            type = 'cortex_analyst_text_to_sql',
            semantic_view = 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_MAO_SALES_ANALYTICS',
            description = 'Query sales data including transactions, products, regions, and rep performance.'
        ),
        
        policy_search = (
            type = 'cortex_search',
            cortex_search_service = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.POLICY_SEARCH_SERVICE',
            max_results = 5,
            description = 'Search company policy documents for procedures and guidelines.'
        ),
        
        quota_calculator = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_QUOTA_ATTAINMENT',
            description = 'Calculate quota attainment for a sales rep.'
        ),
        
        discount_checker = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_GET_DISCOUNT_APPROVAL',
            description = 'Check discount approval requirements.'
        ),
        
        commission_calculator = (
            type = 'generic',
            function = 'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.TOOL_CALCULATE_COMMISSION',
            description = 'Calculate sales commission for a deal.'
        )
    );

GRANT USAGE ON AGENT BUSINESS_ANALYTICS_ASSISTANT TO ROLE PUBLIC;

-- =============================================================================
-- DEPLOYMENT COMPLETE
-- =============================================================================

SELECT '✅ Multi-Agent Orchestration Demo deployed successfully!' AS STATUS
UNION ALL
SELECT '   Database: SNOWFLAKE_EXAMPLE'
UNION ALL
SELECT '   Schema: MULTI_AGENT_ORCHESTRATION'
UNION ALL
SELECT '   Warehouse: SFE_MULTI_AGENT_ORCHESTRATION_WH'
UNION ALL
SELECT '   Agent: BUSINESS_ANALYTICS_ASSISTANT'
UNION ALL
SELECT '   Expires: 2026-02-28'
UNION ALL
SELECT ''
UNION ALL
SELECT 'Next: Run the Streamlit app or test the agent directly.';
