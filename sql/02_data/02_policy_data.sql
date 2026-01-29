/*
================================================================================
SAMPLE DATA - Company Policies (for Cortex Search)
Author: SE Community | Expires: 2026-02-28
================================================================================
Creates policy documents for RAG-based retrieval via Cortex Search.
*/

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA MULTI_AGENT_ORCHESTRATION;

-- =============================================================================
-- POLICY DOCUMENTS TABLE
-- =============================================================================
CREATE OR REPLACE TABLE POLICY_DOCUMENTS (
    POLICY_ID INT PRIMARY KEY,
    POLICY_TITLE VARCHAR(200),
    POLICY_CATEGORY VARCHAR(50),
    POLICY_CONTENT TEXT,
    EFFECTIVE_DATE DATE,
    LAST_UPDATED DATE,
    VERSION VARCHAR(10)
)
COMMENT = 'DEMO: Company policy documents for Cortex Search (Expires: 2026-02-28)';

INSERT INTO POLICY_DOCUMENTS VALUES
-- Sales Policies
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
   - Quarterly review of all exceptional discounts

4. PROHIBITED DISCOUNTS:
   - No retroactive discounts after invoice generation
   - No discounts on professional services without SOW adjustment
   - No stacking of promotional discounts',
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
   - Clawback period: 90 days from customer payment

4. SPLIT RULES:
   - Territory transfers: 50/50 split for 60 days
   - Team selling: Pre-approved split agreements required
   - Channel deals: Reduced rate of 5% base',
'2025-01-01', '2025-10-01', '3.0'),

(3, 'Deal Desk Engagement Policy', 'Sales',
'DEAL DESK ENGAGEMENT POLICY

1. MANDATORY DEAL DESK REVIEW:
   - All deals over $250,000 annual value
   - Non-standard payment terms
   - Custom SLA requirements
   - Multi-cloud deployments

2. TURNAROUND TIMES:
   - Standard review: 2 business days
   - Expedited review: 4 business hours (requires justification)
   - Complex deals: 5 business days

3. REQUIRED DOCUMENTATION:
   - Customer requirements summary
   - Competitive landscape analysis
   - Technical validation sign-off
   - Legal review (if custom terms)

4. ESCALATION PATH:
   Deal Desk Analyst → Deal Desk Manager → VP Sales Operations → CFO',
'2025-06-01', '2025-12-01', '1.2'),

-- Finance Policies
(4, 'Revenue Recognition Policy', 'Finance',
'REVENUE RECOGNITION POLICY (ASC 606 Compliant)

1. PERFORMANCE OBLIGATIONS:
   - Software licenses: Recognized at delivery
   - SaaS subscriptions: Recognized ratably over term
   - Professional services: Recognized as delivered
   - Support: Recognized ratably over service period

2. CONTRACT MODIFICATIONS:
   - Upgrades: Prospective treatment
   - Downgrades: Cumulative catch-up adjustment
   - Extensions: New performance obligation

3. VARIABLE CONSIDERATION:
   - Usage-based: Estimate using expected value method
   - Milestone payments: Recognize when highly probable
   - Penalties: Reduce transaction price

4. TIMING REQUIREMENTS:
   - Quarter-end deals: Must be signed by 11:59 PM PT
   - Revenue cannot be recognized before delivery
   - Multi-element arrangements require standalone selling price allocation',
'2025-01-01', '2025-09-15', '4.0'),

(5, 'Expense Reimbursement Policy', 'Finance',
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
   - Itemized receipts required for all expenses over $25
   - Business purpose documentation required

4. APPROVAL THRESHOLDS:
   - Under $500: Auto-approved with valid receipts
   - $500-$2,500: Manager approval
   - Over $2,500: VP approval',
'2025-03-01', '2025-11-01', '2.5'),

-- HR Policies
(6, 'Work From Home Policy', 'Human Resources',
'WORK FROM HOME POLICY

1. ELIGIBILITY:
   - All employees after 90-day onboarding period
   - Role must be suitable for remote work
   - Performance must be in good standing

2. SCHEDULE OPTIONS:
   - Hybrid: 2-3 days in office per week
   - Remote-first: Quarterly in-person meetings required
   - Full office: Available for those who prefer

3. HOME OFFICE REQUIREMENTS:
   - Dedicated workspace
   - Reliable internet (minimum 50 Mbps)
   - Company-provided equipment must be secured

4. COMMUNICATION EXPECTATIONS:
   - Available during core hours (10 AM - 3 PM local)
   - Camera-on for team meetings
   - Response time: 2 hours during business hours

5. EQUIPMENT STIPEND:
   - One-time $500 home office setup
   - $50/month internet subsidy for full remote',
'2025-01-01', '2025-08-15', '3.2'),

(7, 'Performance Review Policy', 'Human Resources',
'PERFORMANCE REVIEW POLICY

1. REVIEW CADENCE:
   - Annual comprehensive review (Q4)
   - Mid-year check-in (Q2)
   - Quarterly goal updates

2. RATING SCALE:
   - 5: Exceptional - Significantly exceeds expectations
   - 4: Exceeds - Consistently above expectations
   - 3: Meets - Solid performer, meets expectations
   - 2: Developing - Improvement needed
   - 1: Below - Immediate improvement required

3. COMPENSATION IMPACT:
   - Rating 5: 8-12% merit increase eligible
   - Rating 4: 5-8% merit increase eligible
   - Rating 3: 2-4% merit increase eligible
   - Rating 2: No merit increase, PIP consideration
   - Rating 1: Performance Improvement Plan required

4. CALIBRATION PROCESS:
   - Department calibration sessions required
   - Distribution guidelines: ~15% top performers
   - Skip-level review for all promotions',
'2025-01-01', '2025-07-01', '2.0'),

-- IT Policies  
(8, 'Data Security Policy', 'Information Technology',
'DATA SECURITY POLICY

1. DATA CLASSIFICATION:
   - Public: Marketing materials, published content
   - Internal: Company communications, procedures
   - Confidential: Customer data, financial records
   - Restricted: PII, credentials, strategic plans

2. ACCESS CONTROL:
   - Least privilege principle
   - Quarterly access reviews required
   - MFA required for all systems
   - Privileged access requires justification

3. DATA HANDLING:
   - Confidential data must be encrypted at rest and in transit
   - No sensitive data in email or chat
   - Approved tools only for data sharing
   - Customer data cannot leave approved environments

4. INCIDENT REPORTING:
   - Report suspected breaches within 1 hour
   - Security team: security@company.com
   - Hotline: 1-800-SECURITY (24/7)

5. PENALTIES:
   - Policy violations subject to disciplinary action
   - Negligent breaches may result in termination',
'2025-01-01', '2025-12-01', '5.1'),

(9, 'Software Procurement Policy', 'Information Technology',
'SOFTWARE PROCUREMENT POLICY

1. APPROVAL REQUIREMENTS:
   - Under $5,000/year: Manager approval
   - $5,000-$25,000/year: IT and Finance approval
   - Over $25,000/year: VP and Procurement approval

2. SECURITY REVIEW:
   - All SaaS tools require security assessment
   - SOC 2 Type II or equivalent required
   - Data processing agreement required for PII handling

3. PREFERRED VENDORS:
   - Check approved vendor list before new procurement
   - Volume discounts available through IT
   - Shadow IT prohibited

4. CONTRACT REQUIREMENTS:
   - Maximum initial term: 1 year for new vendors
   - Data portability clause required
   - 90-day termination notice acceptable

5. RENEWAL PROCESS:
   - Renewal review 90 days before expiration
   - Usage analysis required for renewal approval
   - Consolidation opportunities must be evaluated',
'2025-04-01', '2025-10-15', '2.3'),

(10, 'AI and Machine Learning Usage Policy', 'Information Technology',
'AI AND MACHINE LEARNING USAGE POLICY

1. APPROVED AI TOOLS:
   - Snowflake Cortex (internal data analysis)
   - Company-approved LLM integrations only
   - Custom models require ML Platform review

2. DATA RESTRICTIONS:
   - No customer PII in external AI tools
   - No confidential financial data in public AI
   - Internal data stays in approved environments

3. USE CASES REQUIRING APPROVAL:
   - Customer-facing AI features
   - Automated decision-making systems
   - AI-generated content for external use

4. RESPONSIBLE AI PRINCIPLES:
   - Transparency: Document AI involvement
   - Fairness: Test for bias in models
   - Accountability: Human oversight required
   - Privacy: Data minimization principles

5. PROHIBITED USES:
   - Automated hiring/firing decisions without human review
   - Surveillance of employee communications
   - Deceptive AI-generated content',
'2025-06-01', '2025-11-20', '1.0');

-- Full-text search optimization
ALTER TABLE POLICY_DOCUMENTS SET
    SEARCH OPTIMIZATION ON;
