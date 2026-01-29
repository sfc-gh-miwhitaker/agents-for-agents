"""
================================================================================
Multi-Agent Orchestration Demo - Streamlit UI
Author: SE Community | Expires: 2026-02-28
================================================================================
A Streamlit application demonstrating Cortex Agents with multi-tool orchestration.

Features:
- Streaming response display
- Threads API for conversation context
- Tool execution visualization
- Sample question suggestions

Run with: streamlit run app/streamlit_app.py
================================================================================
"""

import streamlit as st
import json
import uuid
from datetime import datetime
from snowflake.snowpark.context import get_active_session

# =============================================================================
# CONFIGURATION
# =============================================================================

AGENT_NAME = "SNOWFLAKE_EXAMPLE.MULTI_AGENT_ORCHESTRATION.BUSINESS_ANALYTICS_ASSISTANT"
PAGE_TITLE = "Business Analytics Assistant"
PAGE_ICON = "📊"

SAMPLE_QUESTIONS = [
    "What was our total revenue last quarter?",
    "Show me the top 5 sales reps by revenue",
    "What's Sarah Chen's quota attainment?",
    "What approval do I need for a 15% discount on a $300,000 deal?",
    "What is our discount policy?",
    "Calculate commission for a $500,000 new business deal with 120% quota attainment",
    "Which product category is most profitable?",
    "What are the work from home policy requirements?",
]

# =============================================================================
# PAGE CONFIGURATION
# =============================================================================

st.set_page_config(
    page_title=PAGE_TITLE,
    page_icon=PAGE_ICON,
    layout="wide",
    initial_sidebar_state="expanded"
)

# =============================================================================
# SESSION STATE INITIALIZATION
# =============================================================================

if "session" not in st.session_state:
    st.session_state.session = get_active_session()

if "messages" not in st.session_state:
    st.session_state.messages = []

if "thread_id" not in st.session_state:
    # Create a new thread for conversation context
    st.session_state.thread_id = str(uuid.uuid4())

if "parent_message_id" not in st.session_state:
    st.session_state.parent_message_id = None

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def call_agent_streaming(prompt: str) -> str:
    """
    Call the Cortex Agent with streaming enabled.
    Uses the Threads API for conversation context management.
    
    Returns the complete response text.
    """
    session = st.session_state.session
    
    # Build the agent request with thread context
    request = {
        "messages": [{"role": "user", "content": prompt}],
        "thread_id": st.session_state.thread_id,
        "stream": True,
        "budget": {
            "seconds": 30,
            "tokens": 16000
        }
    }
    
    # Include parent_message_id if continuing a conversation
    if st.session_state.parent_message_id:
        request["parent_message_id"] = st.session_state.parent_message_id
    
    # Call the agent with streaming
    response_stream = session.sql(f"""
        SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT(
            '{AGENT_NAME}',
            PARSE_JSON($${json.dumps(request)}$$)
        ) AS response
    """).collect()
    
    full_response = ""
    tool_calls = []
    
    # Process the streaming response
    if response_stream:
        result = response_stream[0]["RESPONSE"]
        if isinstance(result, str):
            result = json.loads(result)
        
        # Handle streaming events
        if "events" in result:
            for event in result["events"]:
                event_type = event.get("type", "")
                
                if event_type == "response.text.delta":
                    # Incremental text update
                    delta = event.get("delta", "")
                    full_response += delta
                    
                elif event_type == "response.text":
                    # Complete text response
                    full_response = event.get("text", full_response)
                    
                elif event_type == "response.tool_call":
                    # Tool was called
                    tool_calls.append({
                        "tool": event.get("tool_name", "unknown"),
                        "status": event.get("status", "")
                    })
                    
                elif event_type == "response":
                    # Final response with metadata
                    if "message_id" in event:
                        st.session_state.parent_message_id = event["message_id"]
        
        # Fallback for non-streaming response format
        elif "response" in result:
            full_response = result["response"]
            if "message_id" in result:
                st.session_state.parent_message_id = result["message_id"]
        
        elif "text" in result:
            full_response = result["text"]
    
    return full_response, tool_calls


def call_agent_simple(prompt: str) -> tuple[str, list]:
    """
    Simplified agent call for environments without full streaming support.
    """
    session = st.session_state.session
    
    try:
        # Use the SQL function to invoke the agent
        result = session.sql(f"""
            SELECT SNOWFLAKE.CORTEX.INVOKE_AGENT(
                '{AGENT_NAME}',
                OBJECT_CONSTRUCT(
                    'messages', ARRAY_CONSTRUCT(
                        OBJECT_CONSTRUCT('role', 'user', 'content', '{prompt.replace("'", "''")}')
                    ),
                    'thread_id', '{st.session_state.thread_id}'
                )
            ) AS response
        """).collect()
        
        if result:
            response_data = result[0]["RESPONSE"]
            if isinstance(response_data, str):
                response_data = json.loads(response_data)
            
            # Extract response text
            response_text = response_data.get("response", 
                          response_data.get("text", 
                          str(response_data)))
            
            # Update parent message ID for threading
            if "message_id" in response_data:
                st.session_state.parent_message_id = response_data["message_id"]
            
            return response_text, []
        
        return "No response received from agent.", []
        
    except Exception as e:
        return f"Error calling agent: {str(e)}", []


def reset_conversation():
    """Reset the conversation state."""
    st.session_state.messages = []
    st.session_state.thread_id = str(uuid.uuid4())
    st.session_state.parent_message_id = None


# =============================================================================
# SIDEBAR
# =============================================================================

with st.sidebar:
    st.title(f"{PAGE_ICON} {PAGE_TITLE}")
    
    st.markdown("---")
    
    st.subheader("About")
    st.markdown("""
    This demo showcases **Snowflake Cortex Agents** with multi-tool orchestration:
    
    - **Cortex Analyst**: Natural language to SQL
    - **Cortex Search**: Policy document retrieval
    - **Custom Tools**: Specialized calculations
    """)
    
    st.markdown("---")
    
    st.subheader("Sample Questions")
    for question in SAMPLE_QUESTIONS:
        if st.button(question, key=f"sample_{hash(question)}", use_container_width=True):
            st.session_state.pending_question = question
            st.rerun()
    
    st.markdown("---")
    
    if st.button("🔄 New Conversation", use_container_width=True):
        reset_conversation()
        st.rerun()
    
    st.markdown("---")
    
    st.caption(f"Thread ID: `{st.session_state.thread_id[:8]}...`")
    st.caption("Expires: 2026-02-28")


# =============================================================================
# MAIN CHAT INTERFACE
# =============================================================================

st.title(f"{PAGE_ICON} {PAGE_TITLE}")
st.caption("Ask questions about sales data, company policies, or get help with calculations.")

# Display chat history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Handle pending question from sidebar
if "pending_question" in st.session_state:
    prompt = st.session_state.pending_question
    del st.session_state.pending_question
    
    # Add user message to history
    st.session_state.messages.append({"role": "user", "content": prompt})
    
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # Get agent response
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response, tool_calls = call_agent_simple(prompt)
        
        # Show tool usage if any
        if tool_calls:
            with st.expander("🔧 Tools Used"):
                for tc in tool_calls:
                    st.write(f"- {tc['tool']}: {tc['status']}")
        
        st.markdown(response)
    
    # Add assistant message to history
    st.session_state.messages.append({"role": "assistant", "content": response})
    st.rerun()

# Chat input
if prompt := st.chat_input("Ask a question..."):
    # Add user message to history
    st.session_state.messages.append({"role": "user", "content": prompt})
    
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # Get agent response
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response, tool_calls = call_agent_simple(prompt)
        
        # Show tool usage if any
        if tool_calls:
            with st.expander("🔧 Tools Used"):
                for tc in tool_calls:
                    st.write(f"- {tc['tool']}: {tc['status']}")
        
        st.markdown(response)
    
    # Add assistant message to history
    st.session_state.messages.append({"role": "assistant", "content": response})
