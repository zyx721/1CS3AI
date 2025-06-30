import os
import json
import logging
from typing import Annotated, Sequence, TypedDict
from langgraph.prebuilt import ToolNode
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from langchain_core.tools import tool
from search_engine import run_agent
from dotenv import load_dotenv

load_dotenv()


BUSINESS_INFO = {
    "business_name": "",
    "domain": "",
    "location": "",
    "services": "",
    "description": ""
}

def load_business_config(path: str):
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
    search_leads(description:str)
    tool for finding and qualifies B2B leads based on a description of target buisness.
    Returns the found leads as a JSON string.
    """
    try:
        results = run_agent(description)
        return f"Found {len(results)} leads: {json.dumps(results)}"
    except Exception as e:
        return f"❌ Failed to search leads: {e}"

search_tools = [search_leads]
search_llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash").bind_tools(search_tools)

class AgentState(TypedDict):
    messages: Annotated[Sequence[HumanMessage | AIMessage | ToolMessage], add_messages]

def search_agent(state: AgentState) -> AgentState:
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
        search_leads(description:str) is the tool 
    """)
    response = search_llm.invoke([sys_prompt] + state["messages"])
    print(f"DEBUG: Search Agent LLM response: {response.tool_calls}")
    return {"messages": [response]}



@tool
def save_ranked_leads(ranked_leads: list[dict]):
    """Saves the provided list of ranked leads to a 'ranked_leads.json' file. The list should contain all leads, ordered from most to least relevant. The file will contain all details for each lead, such as URL, phone, company_name, etc."""
    print(f"\n--- DEBUG: Executing 'save_ranked_leads' tool ---")
    try:
        with open("ranked_leads.json", "w", encoding="utf-8") as f:
            json.dump(ranked_leads, f, indent=4)
        success_message = f"Successfully saved {len(ranked_leads)} ranked leads to ranked_leads.json"
        print(f"✅ {success_message}")
        return success_message
    except Exception as e:
        error_message = f"❌ Error saving leads to JSON file: {e}"
        print(error_message)
        return error_message

save_tools = [save_ranked_leads]
organization_llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash").bind_tools(save_tools)

def organization_agent(state: AgentState)-> AgentState:
    print("\n--- STEP 2: Executing Organization Agent ---")
    print(f"DEBUG: Current state messages: {state['messages'][-1].content}")

    sys_prompt = SystemMessage(content=f"""
        You are a B2B Sales Analyst. You have been given a list of potential leads from a search.
        Your role is to rank these leads based on their relevance to our company's services.

        Your task has three steps:
        1. Analyze the full list of leads provided in the previous tool message.
        2. Based on our company's profile (Services: '{BUSINESS_INFO['services']}', Description: '{BUSINESS_INFO['description']}'), reorder the *entire* list of leads from most relevant to least relevant. Do NOT filter or remove any leads.
        3. Call the `save_ranked_leads` tool, passing the complete, newly reordered list of all leads. The list must contain all original information for each lead (url, phone, etc.).

        Your output must be a single call to the `save_ranked_leads` tool.
    """)
    response = organization_llm.invoke([sys_prompt] + state["messages"])
    print(f"DEBUG: Organization Agent LLM response: {response.tool_calls}")
    return {"messages": [response]}

def router(state: AgentState) -> str:
    last_message = state["messages"][-1]

    if isinstance(last_message, AIMessage) and last_message.tool_calls:
        if last_message.tool_calls[0]["name"] == "search_leads":
            return "call_search_tool"
        elif last_message.tool_calls[0]["name"] == "save_ranked_leads":
            return "call_save_tool"
    
    if isinstance(last_message, ToolMessage):
        if last_message.name == "search_leads":
             return "org_agent"

    return END


def build_graph():
    graph = StateGraph(AgentState)

    graph.add_node("search_agent", search_agent)
    graph.add_node("call_search_tool", ToolNode(tools=search_tools))
    graph.add_node("org_agent", organization_agent)
    graph.add_node("call_save_tool", ToolNode(tools=save_tools))

    graph.set_entry_point("search_agent")

    graph.add_conditional_edges(
        "search_agent",
        router,
        {
            "call_search_tool": "call_search_tool",
            END: END
        }
    )
    
    graph.add_edge("call_search_tool", "org_agent")

    graph.add_conditional_edges(
        "org_agent",
        router,
        {
            "call_save_tool": "call_save_tool",
            END: END
        }
    )

    graph.add_edge("call_save_tool", END)

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