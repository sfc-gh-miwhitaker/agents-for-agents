# Multi-Agent Orchestration Demo

![Expires](https://img.shields.io/badge/Expires-2026--02--28-orange)

A Snowflake Cortex Agents demo showcasing multi-tool orchestration with Cortex Analyst, Cortex Search, and custom UDFs.

> **⚠️ EXPIRATION WARNING:** This demo expires on 2026-02-28. After this date, deployment will fail and assets should be cleaned up.

**Author:** SE Community

---

## Quick Start

1. Open `deploy_all.sql` in Snowsight
2. Click **Run All**
3. Done.

### Run the Streamlit App

```sql
-- In Snowsight, create a Streamlit app and upload app/streamlit_app.py
-- Or deploy via Snowflake CLI:
snow streamlit deploy --file app/streamlit_app.py
```

### Test the Agent Directly

```sql
-- Simple query
SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT(
    'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.BUSINESS_ANALYTICS_ASSISTANT',
    OBJECT_CONSTRUCT(
        'messages', ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT('role', 'user', 'content', 'What was our total revenue last quarter?')
        )
    )
);

-- With thread context for follow-up questions
SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT(
    'SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.BUSINESS_ANALYTICS_ASSISTANT',
    OBJECT_CONSTRUCT(
        'messages', ARRAY_CONSTRUCT(
            OBJECT_CONSTRUCT('role', 'user', 'content', 'Break that down by region')
        ),
        'thread_id', '<thread_id_from_previous_response>',
        'parent_message_id', '<message_id_from_previous_response>'
    )
);
```

---

## What This Demo Shows

### Cortex Agent Capabilities

| Capability | Tool | Description |
|------------|------|-------------|
| **Text-to-SQL** | Cortex Analyst | Natural language queries against sales data via Semantic View |
| **RAG Retrieval** | Cortex Search | Semantic search over company policy documents |
| **Custom Logic** | Generic Tools | UDFs for quota, commission, and discount calculations |

### Key API Features (Post-Sept 2025)

- **Semantic Views** - First-class database objects (not YAML files)
- **CREATE AGENT SQL** - SQL-native agent management
- **Threads API** - Server-side conversation context
- **Budget Configuration** - Resource limits (seconds, tokens)
- **Model Auto-Selection** - `orchestration: auto`

---

## Project Structure

```
agents-for-agents/
├── deploy_all.sql              # Deployment orchestrator (EXECUTE IMMEDIATE FROM)
├── teardown_all.sql            # Complete cleanup (inline DROP statements)
├── LICENSE                     # Apache 2.0
├── sql/
│   ├── 01_setup/               # Infrastructure (warehouse, database, schema)
│   ├── 02_data/                # Sample sales & policy data
│   ├── 03_semantic/            # Semantic View definition
│   ├── 04_search/              # Cortex Search service
│   ├── 05_tools/               # Custom UDFs
│   ├── 06_agents/              # Agent creation
│   └── 08_testing/             # Smoke tests
├── app/
│   └── streamlit_app.py        # Chat UI with streaming
├── diagrams/
│   └── data-flow.md            # Architecture diagrams (Mermaid)
└── .github/workflows/
    └── expire-demo.yml         # Auto-archive on expiration
```

---

## Sample Questions

### Sales Analytics (Cortex Analyst)
- "What was our total revenue last quarter?"
- "Show me the top 5 sales reps by revenue"
- "Which product category is most profitable?"
- "Compare revenue by region for the last 6 months"

### Policy Lookup (Cortex Search)
- "What is our discount policy?"
- "What approval do I need for a 25% discount?"
- "What are the work from home requirements?"
- "Explain our commission structure"

### Calculations (Custom Tools)
- "What's Sarah Chen's quota attainment?"
- "Calculate commission for a $500K new deal at 120% quota"
- "What approval is needed for 18% discount on $200K deal?"

### Multi-Tool Questions
- "Is Sarah Chen on track for her quota, and what's her commission potential?"
- "What discount can I offer without approval, and what's the policy?"

---

## Snowflake Objects Created

| Object | Type | Name |
|--------|------|------|
| API Integration | API INTEGRATION | `SFE_GIT_API_INTEGRATION` |
| Git Repository | GIT REPOSITORY | `SNOWFLAKE_EXAMPLE.GIT_REPOS.MULTI_AGENT_ORCHESTRATION_REPO` |
| Warehouse | WAREHOUSE | `SFE_MULTI_AGENT_ORCHESTRATION_WH` |
| Database | DATABASE | `SNOWFLAKE_EXAMPLE` |
| Schema | SCHEMA | `MULTI_AGENT_ORCHESTRATION` |
| Schema | SCHEMA | `SEMANTIC_MODELS` |
| Agent | AGENT | `BUSINESS_ANALYTICS_ASSISTANT` |
| Semantic View | SEMANTIC VIEW | `SV_MAO_SALES_ANALYTICS` |
| Search Service | CORTEX SEARCH | `POLICY_SEARCH_SERVICE` |
| Tables | TABLE | `FACT_SALES`, `DIM_*`, `POLICY_DOCUMENTS` |
| Functions | FUNCTION | `TOOL_CALCULATE_*`, `TOOL_GET_*` |

---

## Cleanup

1. Open `teardown_all.sql` in Snowsight
2. Click **Run All**

---

## Prerequisites

- Snowflake account with Cortex features enabled
- ACCOUNTADMIN role (script handles all object creation)

---

## API Reference

### Invoke Agent

```sql
SNOWFLAKE.CORTEX.INVOKE_AGENT(
    '<agent_name>',
    OBJECT_CONSTRUCT(
        'messages', ARRAY_CONSTRUCT(...),
        'thread_id', '<uuid>',
        'parent_message_id', '<message_id>',
        'stream', TRUE,
        'budget', OBJECT_CONSTRUCT('seconds', 30, 'tokens', 16000)
    )
)
```

### Streaming Events

| Event Type | Description |
|------------|-------------|
| `response.status` | Agent processing status |
| `response.thinking.delta` | Incremental reasoning (if enabled) |
| `response.text.delta` | Incremental response text |
| `response.text` | Complete response text |
| `response.tool_call` | Tool execution notification |
| `response` | Final response with message_id |

### Tool Types

| Type | Resource | Use Case |
|------|----------|----------|
| `cortex_analyst_text_to_sql` | `semantic_view` | Structured data queries |
| `cortex_search` | `cortex_search_service` | Document retrieval |
| `generic` | `function` | Custom UDF execution |

---

## Resources

- [Snowflake Cortex Agents Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Semantic Views Guide](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-views)
- [Multi-Agent Orchestration Guide](https://www.snowflake.com/en/developers/guides/multi-agent-orchestration-snowflake-intelligence/)
