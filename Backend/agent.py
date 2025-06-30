import os
import json
import logging
from typing import Annotated, Sequence, TypedDict
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from langgraph.prebuilt import ToolNode
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from langchain_core.tools import tool
from search_engine import run_agent
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://337a-105-235-133-238.ngrok-free.app",
        "http://127.0.0.1:5500",  # <-- add this line for local dev
        "http://localhost:5500"    # <-- add this line for local dev
    ],  # Only allow your frontend's ngrok URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BUSINESS_INFO = {
    "business_name": "",
    "domain": "",
    "location": "",
    "services": "",
    "description": ""
}

def load_business_config_from_dict(data: dict):
    BUSINESS_INFO.update({
        "business_name": data.get("business_name", "Your Company"),
        "domain": data.get("domain", "B2B service"),
        "location": data.get("location", "Global"),
        "services": data.get("services", ""),
        "description": data.get("description", "")
    })
    print("✅ Business config loaded successfully.")
    print(json.dumps(BUSINESS_INFO, indent=2))
    # Save updated config to business_config.json
    try:
        with open("business_config.json", "w", encoding="utf-8") as f:
            json.dump(BUSINESS_INFO, f, indent=2)
        print("✅ business_config.json updated.")
    except Exception as e:
        print(f"❌ Failed to update business_config.json: {e}")



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
        3. Use your search tool to find leads. You can call the tool multiple times with different queries if needed but at max try only 2 times a time.
        4- you should be more smarter then searching by direct same keywords of our service . your description for search should describle those people that would need our service and search for them by simple queries and smart

        Our business information:
        - Domain: "{BUSINESS_INFO['domain']}"
        - Services: "{BUSINESS_INFO['services']}"
        - Location: "{BUSINESS_INFO['location']}"
        - Description: "{BUSINESS_INFO['description']}"
        note: 
            you can call the tool mutliple time in same responde.
            do not make description of mutliple target. each one search should have it well direct query not very long
            description = search query
        Your job is to determine the best descreptions parameters for the search tool and then call it.
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
        note: you can remove any one that dosen't need to our service
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

@app.post("/upload-config")
async def upload_config(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        data = json.loads(contents)
        load_business_config_from_dict(data)
        return {"status": "success", "message": "Business config uploaded and loaded."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to load config: {e}")

@app.post("/run-agent")
async def run_agent_endpoint():
    try:
        app_graph = build_graph()
        initial_message = {"messages": [HumanMessage(content="Find potential leads for our business.")]}
        final_state = None
        for event in app_graph.stream(initial_message, stream_mode="values"):
            final_state = event
        result = final_state['messages'][-1].content
        try:
            result_json = json.loads(result)
            return JSONResponse(content=result_json)
        except Exception:
            return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent execution failed: {e}")

from fastapi import Request

@app.get("/dashboard-data")
async def get_dashboard_data():
    """
    Loads dashboard data from dashboard_data.json and returns it.
    If the file does not exist, returns default dashboard data.
    """
    dashboard_path = os.path.join(os.path.dirname(__file__), "dashboard_data.json")
    if not os.path.exists(dashboard_path):
        # Default dashboard data structure
        default_data = {
            "total_calls": 0,
            "calls_this_week": 0,
            "success_rate": 0,
            "new_leads": 0,
            "performance": {
                "labels": [],
                "leads": [],
                "success": []
            },
            "leads_table": []
        }
        return default_data
    try:
        with open(dashboard_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load dashboard data: {e}")

@app.get("/agent-info")
async def get_agent_info():
    """
    Returns the current agent (business) info from business_config.json.
    """
    config_path = os.path.join(os.path.dirname(__file__), "business_config.json")
    if not os.path.exists(config_path):
        # Return default info if file doesn't exist
        return {
            "business_name": "",
            "domain": "",
            "location": "",
            "services": "",
            "description": ""
        }
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load agent info: {e}")

@app.post("/agent-info")
async def update_agent_info(info: dict):
    """
    Updates the agent (business) info and saves to business_config.json.
    """
    config_path = os.path.join(os.path.dirname(__file__), "business_config.json")
    try:
        # Save to file
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(info, f, indent=2)
        # Update in-memory BUSINESS_INFO as well
        BUSINESS_INFO.update(info)
        # Always return a JSONResponse with status 200
        return JSONResponse(content={"status": "success"}, status_code=200)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save agent info: {e}")