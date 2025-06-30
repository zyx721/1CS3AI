# main.py
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import StateGraph, END
from langchain_core.tools import Tool
from langgraph.graph.message import add_messages
from typing import Annotated, Sequence, TypedDict
from tools.search_tool import search_leads
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

load_business_config("business_config.json")

@tool
def search_leads(service: str, location: str) -> str:
    """Finds and qualifies B2B leads based on a service and location."""
    try:
        results = run_agent(service, location)
        return f"✅ Found {len(results)} leads for '{service}' in '{location}'."
    except Exception as e:
        return f"❌ Failed to search leads: {e}"

tools = [search_leads]
agent = ChatGoogleGenerativeAI(model="gemini-2.5-flash").bind_tools(tools)

class AgentState(TypedDict):
    messages: Annotated[Sequence, add_messages]

def sales_agent(state: AgentState) -> AgentState:
    sys_prompt = SystemMessage(content=f"""
        You are a B2B Sales Agent working for {BUSINESS_INFO['business_name']}.

        Your goal is to:
        1. Understand our service: "{BUSINESS_INFO['services']}"
        2. Think about what kind of businesses might need this.
        3. Use your search tool when needed to find leads in {BUSINESS_INFO['location']}.

        Available tool:
        - search_leads(service, location): searches the internet for relevant business leads.

        Only use this tool when the user asks for leads or you decide to find new leads.

        Your job is to return the results in a helpful format.
    """)
    response = agent.invoke([sys_prompt] + state["messages"])
    return {"messages": [response]}

graph = StateGraph(AgentState)
graph.add_node("sales_agent", sales_agent)
graph.set_entry_point("sales_agent")
graph.add_edge("sales_agent", END)
app = graph.compile()
