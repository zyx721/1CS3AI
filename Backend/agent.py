
import os
import json
import logging
from typing import Annotated, Sequence, TypedDict

from langchain_core.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from langchain_core.tools import tool
from search_engine import run_agent


BUSINESS_INFO = {
    "business_name": "",
    "domain": "",
    "location": "",
    "services": "",
    "description": ""
}

def load_business_config(path: str):
    """Loads business info from a JSON config file."""
    if not os.path.exists(path):
        raise FileNotFoundError(f"Business config not found: {path}")
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        BUSINESS_INFO.update({
            "business_name": data.get("business_name", "Your Company"),
            "domain": data.get("domain", "B2B service"),
            "location": data.get("location", "Global"),
            "services": data.get("services", ""),
            "description": data.get("description", "")
        })
    print("✅ Business config loaded successfully.")
    print(json.dumps(BUSINESS_INFO, indent=2))



@tool
def search_leads(description: str) -> str:
    """
    Finds and qualifies B2B leads based on a description of target buisness.
    Returns the found leads as a JSON string.
    """
    try:
        results = run_agent(description)
        return f"Found {len(results)} leads: {json.dumps(results)}"
    except Exception as e:
        return f"❌ Failed to search leads: {e}"

search_tools = [search_leads]
search_llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash").bind_tools(search_tools)

class AgentState(TypedDict):
    messages: Annotated[Sequence[HumanMessage | AIMessage | ToolMessage], add_messages]

def search_agent(state: AgentState) -> AgentState:
    """Agent responsible for searching for potential leads."""
    print("\n--- STEP 1: Executing Search Agent ---")
    print(f"DEBUG: Current state messages: {state['messages'][-1].content}")

    sys_prompt = SystemMessage(content=f"""
        You are a Search Agent for businesses.
        Your goal is to find potential leads for our company based on our business profile.

        1. Understand our service from the information provided below.
        2. Identify what kinds of businesses would need our service.
        3. Use your search tool to find leads. You can call the tool multiple times with different queries if needed.

        Our business information:
        - Domain: "{BUSINESS_INFO['domain']}"
        - Services: "{BUSINESS_INFO['services']}"
        - Location: "{BUSINESS_INFO['location']}"
        - Description: "{BUSINESS_INFO['description']}"

        Your job is to determine the best service and location parameters for the search tool and then call it.
    """)
    response = search_llm.invoke([sys_prompt] + state["messages"])
    print(f"DEBUG: Search Agent LLM response: {response.tool_calls}")
    return {"messages": [response]}



@tool
def Save(relevant_leads: list):
    """Saves the provided list of the most relevant leads."""
    print(f"\n--- DEBUG: Executing 'Save' tool ---")
    print(f"✅ Saving {len(relevant_leads)} most relevant leads:")
    for lead in relevant_leads:
        print(f"  - {lead.get('company_name', 'N/A')} in {lead.get('industry', 'N/A')}")
    return "Successfully saved relevant leads."

save_tools = [Save]
organization_llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash").bind_tools(save_tools)

def organization_agent(state: AgentState)-> AgentState:
    """Agent responsible for filtering and saving the best leads."""
    print("\n--- STEP 2: Executing Organization Agent ---")
    print(f"DEBUG: Current state messages: {state['messages'][-1].content}")

    sys_prompt = SystemMessage(content=f"""
        You are a B2B Sales Analyst. You have been given a list of potential leads from a search.
        Your goal is to analyze these leads, select only the most relevant ones based on our business profile, and save them.

        1. Review the list of leads provided in the last message.
        2. Based on our company's services ('{BUSINESS_INFO['services']}'), rank the leads by relevance.
        3. Call the `Save` tool with a list containing only the most relevant leads.

        Your output should be a call to the `Save` tool.
    """)
    response = organization_llm.invoke([sys_prompt] + state["messages"])
    print(f"DEBUG: Organization Agent LLM response: {response.tool_calls}")
    return {"messages": [response]}


def build_graph():
    """Builds and compiles the LangGraph agent graph."""
    graph = StateGraph(AgentState)
    graph.add_node("search_agent", search_agent)
    graph.add_node("org_agent", organization_agent)

    graph.set_entry_point("search_agent")

    graph.add_edge("search_agent", "org_agent")
    graph.add_edge("org_agent", END)

    return graph.compile()

if __name__ == "__main__":
    load_business_config("business_config.json")

    app = build_graph()
    print("\n--- Graph Compiled. Starting Execution... ---")

    initial_message = {"messages": [HumanMessage(content="Find potential leads for our business.")]}

    final_state = None
    for event in app.stream(initial_message, stream_mode="values"):
        final_state = event

    print("\n--- Execution Finished ---")
    print("Final State:")
    print(final_state['messages'][-1].content)