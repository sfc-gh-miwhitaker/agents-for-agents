/*
================================================================================
CUSTOM TOOLS - UDFs for Agent Use
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates custom UDFs that can be used as tools by the Cortex Agent.
These demonstrate the 'generic' tool type capability.
================================================================================
*/

USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- TOOL: Calculate Quota Attainment
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
COMMENT = 'DEMO: Calculates quota attainment for a sales rep (Expires: 2026-02-28)'
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

-- =============================================================================
-- TOOL: Get Discount Approval Requirements
-- =============================================================================
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
COMMENT = 'DEMO: Determines discount approval requirements (Expires: 2026-02-28)'
AS
$$
    SELECT 
        CASE 
            WHEN discount_percent <= 5 THEN 'STANDARD - Multi-year'
            WHEN discount_percent <= 10 THEN 'STANDARD - Annual'
            WHEN discount_percent <= 15 AND deal_value >= 500000 THEN 'STANDARD - Enterprise'
            WHEN discount_percent <= 20 THEN 'ELEVATED'
            ELSE 'EXCEPTIONAL'
        END AS DISCOUNT_LEVEL,
        CASE 
            WHEN discount_percent <= 5 THEN 'No approval required'
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
            WHEN discount_percent <= 15 THEN 'Standard discount within policy guidelines'
            WHEN discount_percent <= 20 THEN 'Document competitive pressure or strategic value'
            ELSE 'Written business justification required'
        END AS NOTES
$$;

-- =============================================================================
-- TOOL: Forecast Revenue
-- =============================================================================
CREATE OR REPLACE FUNCTION TOOL_FORECAST_REVENUE(
    months_ahead INT DEFAULT 3,
    region_filter VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    forecast_month DATE,
    region_name VARCHAR,
    forecasted_revenue DECIMAL(12,2),
    confidence VARCHAR,
    basis VARCHAR
)
LANGUAGE SQL
COMMENT = 'DEMO: Generates revenue forecast from historical trends (Expires: 2026-02-28)'
AS
$$
    WITH historical_avg AS (
        SELECT 
            r.REGION_NAME,
            AVG(fs.TOTAL_REVENUE) AS avg_daily_revenue,
            STDDEV(fs.TOTAL_REVENUE) AS stddev_revenue
        FROM SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.FACT_SALES fs
        JOIN SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_SALES_REPS sr ON fs.REP_ID = sr.REP_ID
        JOIN SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.DIM_REGIONS r ON sr.REGION_ID = r.REGION_ID
        WHERE fs.TRANSACTION_DATE >= DATEADD(month, -6, CURRENT_DATE())
            AND (region_filter IS NULL OR LOWER(r.REGION_NAME) LIKE LOWER('%' || region_filter || '%'))
        GROUP BY r.REGION_NAME
    ),
    months AS (
        SELECT DATEADD(month, SEQ4() + 1, DATE_TRUNC('month', CURRENT_DATE())) AS forecast_month
        FROM TABLE(GENERATOR(ROWCOUNT => 12))
        WHERE SEQ4() < months_ahead
    )
    SELECT 
        m.forecast_month,
        h.REGION_NAME,
        ROUND(h.avg_daily_revenue * 30, 2) AS forecasted_revenue,
        CASE 
            WHEN h.stddev_revenue / NULLIF(h.avg_daily_revenue, 0) < 0.2 THEN 'HIGH'
            WHEN h.stddev_revenue / NULLIF(h.avg_daily_revenue, 0) < 0.4 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS confidence,
        '6-month historical average' AS basis
    FROM months m
    CROSS JOIN historical_avg h
    ORDER BY m.forecast_month, h.REGION_NAME
$$;

-- =============================================================================
-- TOOL: Calculate Commission
-- =============================================================================
CREATE OR REPLACE FUNCTION TOOL_CALCULATE_COMMISSION(
    deal_value DECIMAL(12,2),
    deal_type VARCHAR,  -- 'NEW', 'EXPANSION', 'RENEWAL'
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
COMMENT = 'DEMO: Calculates sales commission for deals (Expires: 2026-02-28)'
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
        'Base: ' || 
        CASE UPPER(deal_type) WHEN 'NEW' THEN '10%' WHEN 'EXPANSION' THEN '7%' WHEN 'RENEWAL' THEN '3%' ELSE '5%' END ||
        ' × Accelerator: ' ||
        CASE WHEN quota_attainment_pct >= 150 THEN '2.0x' WHEN quota_attainment_pct >= 100 THEN '1.5x' ELSE '1.0x' END ||
        CASE WHEN is_multi_year THEN ' + 5% multi-year bonus' ELSE '' END AS BREAKDOWN
$$;

-- =============================================================================
-- GRANTS
-- =============================================================================
GRANT USAGE ON FUNCTION TOOL_CALCULATE_QUOTA_ATTAINMENT(VARCHAR, DATE) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION TOOL_GET_DISCOUNT_APPROVAL(DECIMAL, DECIMAL) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION TOOL_FORECAST_REVENUE(INT, VARCHAR) TO ROLE PUBLIC;
GRANT USAGE ON FUNCTION TOOL_CALCULATE_COMMISSION(DECIMAL, VARCHAR, DECIMAL, BOOLEAN) TO ROLE PUBLIC;
