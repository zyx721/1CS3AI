import os
import json
import logging
from typing import Annotated, Sequence, TypedDict, Optional

# --- LangChain & LangGraph Imports ---
from langgraph.prebuilt import ToolNode
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from langchain_core.tools import tool
from dotenv import load_dotenv

# --- FastAPI Server Imports ---
import uvicorn
from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel

# --- Dummy search_engine.run_agent for portability ---
# In a real scenario, this would be your actual search module.
try:
    from search_engine import run_agent
except ImportError:
    print("⚠️  'search_engine' not found. Using a dummy search function for demonstration.")
    def run_agent(description: str):
        print(f"--- DUMMY SEARCH for: '{description}' ---")
        return [
            {"company_name": "Innovate Corp", "url": "innovate.com", "phone": "111-222-3333", "description": "A dummy company specializing in innovation."},
            {"company_name": "Solutions Inc", "url": "solutions.com", "phone": "444-555-6666", "description": "A test company that provides solutions."}
        ]

# --- Core Application Setup ---
load_dotenv()
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Global In-Memory State & Constants ---
BUSINESS_INFO = {
    "business_name": "Default Company",
    "domain": "B2B",
    "location": "Global",
    "services": "General Services",
    "description": "A default business description."
}
BUSINESS_CONFIG_PATH = "business_config.json"
RANKED_LEADS_PATH = "ranked_leads.json"
DASHBOARD_DATA_PATH = "dashboard_data.json"

# --- Configuration Helper Functions ---
def load_business_config(path: str = BUSINESS_CONFIG_PATH):
    """Loads business configuration from a JSON file into the in-memory dictionary."""
    if not os.path.exists(path):
        logging.warning(f"Business config '{path}' not found. Saving and using default values.")
        save_business_config()
        return
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            BUSINESS_INFO.update({
                "business_name": data.get("business_name", "Your Company"),
                "domain": data.get("domain", "B2B service"),
                "location": data.get("location", "Global"),
                "services": data.get("services", ""),
                "description": data.get("description", "")
            })
        logging.info("✅ Business config loaded successfully.")
    except (json.JSONDecodeError, IOError) as e:
        logging.error(f"❌ Error loading business config: {e}. Using default values.")

def save_business_config(path: str = BUSINESS_CONFIG_PATH):
    """Saves the in-memory BUSINESS_INFO to a JSON file."""
    try:
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(BUSINESS_INFO, f, indent=4)
        logging.info(f"✅ Business config saved to {path}.")
    except IOError as e:
        logging.error(f"❌ Failed to save business config: {e}")

# --- Agent Tools & Logic (Original Code) ---
@tool
def search_leads(description: str) -> str:
    """
    search_leads(description:str)
    A tool for finding and qualifying B2B leads based on a description of a target business.
    Returns the found leads as a JSON string.
    """
    try:
        results = run_agent(description)
        return f"Found {len(results)} leads: {json.dumps(results)}"
    except Exception as e:
        return f"❌ Failed to search leads: {e}"

@tool
def save_ranked_leads(ranked_leads: list[dict]):
    """Saves the provided list of ranked leads to a 'ranked_leads.json' file."""
    logging.info(f"Executing 'save_ranked_leads' tool...")
    try:
        with open(RANKED_LEADS_PATH, "w", encoding="utf-8") as f:
            json.dump(ranked_leads, f, indent=4)
        success_message = f"Successfully saved {len(ranked_leads)} ranked leads to {RANKED_LEADS_PATH}"
        logging.info(f"✅ {success_message}")
        return success_message
    except Exception as e:
        error_message = f"❌ Error saving leads to JSON file: {e}"
        logging.error(error_message)
        return error_message

# --- Agent LLM and State Definition ---
llm_model_name = "gemini-1.5-flash"
try:
    llm = ChatGoogleGenerativeAI(model=llm_model_name)
    search_llm = llm.bind_tools([search_leads])
    organization_llm = llm.bind_tools([save_ranked_leads])
except Exception as e:
    logging.error(f"Could not initialize Google Generative AI. Check API key. Error: {e}")
    llm = None  # Flag that LLM is not available

class AgentState(TypedDict):
    messages: Annotated[Sequence[HumanMessage | AIMessage | ToolMessage], add_messages]

# --- Agent Nodes (Functions) ---
def search_agent(state: AgentState) -> AgentState:
    logging.info("--- STEP 1: Executing Search Agent ---")
    sys_prompt = SystemMessage(content=f"""
        You are a Search Agent. Your goal is to find potential leads for our company.
        Use your search tool based on our business profile:
        - Domain: "{BUSINESS_INFO['domain']}"
        - Services: "{BUSINESS_INFO['services']}"
        - Location: "{BUSINESS_INFO['location']}"
        - Description: "{BUSINESS_INFO['description']}"
        Your job is to determine the best search query (description) for the `search_leads` tool and call it.
    """)
    response = search_llm.invoke([sys_prompt] + state["messages"])
    logging.info(f"Search Agent LLM response tool calls: {response.tool_calls}")
    return {"messages": [response]}

def organization_agent(state: AgentState) -> AgentState:
    logging.info("--- STEP 2: Executing Organization Agent ---")
    sys_prompt = SystemMessage(content=f"""
        You are a B2B Sales Analyst. You have a list of potential leads.
        Your task is to rank these leads based on their relevance to our company's services:
        - Services: '{BUSINESS_INFO['services']}'
        - Description: '{BUSINESS_INFO['description']}'
        Reorder the *entire* list from most to least relevant, then call `save_ranked_leads` with the complete, reordered list.
    """)
    response = organization_llm.invoke([sys_prompt] + state["messages"])
    logging.info(f"Organization Agent LLM response tool calls: {response.tool_calls}")
    return {"messages": [response]}

# --- Graph Router and Builder ---
def router(state: AgentState) -> str:
    last_message = state["messages"][-1]
    if isinstance(last_message, AIMessage) and last_message.tool_calls:
        tool_name = last_message.tool_calls[0]["name"]
        if tool_name == "search_leads":
            return "call_search_tool"
        if tool_name == "save_ranked_leads":
            return "call_save_tool"
    if isinstance(last_message, ToolMessage) and last_message.name == "search_leads":
        return "org_agent"
    return END

def build_graph():
    graph = StateGraph(AgentState)
    graph.add_node("search_agent", search_agent)
    graph.add_node("call_search_tool", ToolNode(tools=[search_leads]))
    graph.add_node("org_agent", organization_agent)
    graph.add_node("call_save_tool", ToolNode(tools=[save_ranked_leads]))
    graph.set_entry_point("search_agent")
    graph.add_conditional_edges("search_agent", router)
    graph.add_edge("call_search_tool", "org_agent")
    graph.add_conditional_edges("org_agent", router)
    graph.add_edge("call_save_tool", END)
    return graph.compile()

# ==============================================================================
# --- FastAPI Server Implementation ---
# ==============================================================================
app = FastAPI(
    title="AI Lead Generation Agent Server",
    description="An API to manage and run an AI lead-finding agent.",
    version="1.0.0",
)

class BusinessInfoUpdate(BaseModel):
    business_name: Optional[str] = None
    domain: Optional[str] = None
    location: Optional[str] = None
    services: Optional[str] = None
    description: Optional[str] = None

@app.on_event("startup")
async def startup_event():
    """On server startup, load the business configuration."""
    logging.info("--- Server starting up, loading configuration... ---")
    load_business_config()

@app.post("/upload-config", tags=["Configuration"])
async def upload_config(file: UploadFile = File(..., description="A JSON file with business configuration.")):
    """Uploads, updates, and saves the business configuration."""
    if file.content_type != 'application/json':
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload a JSON file.")
    try:
        content = await file.read()
        data = json.loads(content)
        BUSINESS_INFO.update(data)
        save_business_config()
        return {"message": "Configuration uploaded successfully.", "new_config": BUSINESS_INFO}
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON format.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@app.post("/run-agent", tags=["Agent"])
async def run_agent_endpoint():
    """Launches the AI lead-finding agent graph."""
    if not llm:
        raise HTTPException(status_code=503, detail="LLM service is unavailable. Check server logs for API key issues.")
    if not BUSINESS_INFO.get("services"):
        raise HTTPException(status_code=400, detail="Business services are not configured. Please set them via /agent-info or /upload-config.")
    
    logging.info("--- Received request to run agent ---")
    try:
        graph = build_graph()
        initial_message = {"messages": [HumanMessage(content="Find potential leads for our business.")]}
        final_state = None
        async for event in graph.astream(initial_message, stream_mode="values"):
            final_state = event
        
        final_message = final_state['messages'][-1].content
        logging.info("--- Agent execution finished ---")
        return {"status": "success", "final_result": final_message}
    except Exception as e:
        logging.error(f"Error running agent graph: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Agent execution failed: {str(e)}")

@app.get("/dashboard-data", tags=["Dashboard"])
async def get_dashboard_data():
    """Returns dashboard analytics data. Returns default data if file is missing."""
    try:
        with open(DASHBOARD_DATA_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        logging.warning(f"'{DASHBOARD_DATA_PATH}' not found. Returning default data.")
        return {
            "total_calls": 0,
            "weekly_stats": {"Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0},
            "success_rate": "0%",
            "lead_performance": [],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading dashboard data: {str(e)}")

@app.get("/agent-info", tags=["Configuration"])
async def get_agent_info():
    """Fetches the current business agent configuration."""
    return BUSINESS_INFO

@app.post("/agent-info", tags=["Configuration"])
async def update_agent_info(update_data: BusinessInfoUpdate):
    """Updates the business agent’s configuration via a JSON body."""
    update_dict = update_data.model_dump(exclude_unset=True)
    if not update_dict:
        raise HTTPException(status_code=400, detail="No update data provided.")
    
    BUSINESS_INFO.update(update_dict)
    save_business_config()
    return {"message": "Agent info updated successfully.", "updated_info": BUSINESS_INFO}

@app.get("/ranked-leads", tags=["Leads"])
async def get_ranked_leads():
    """Retrieves the list of ranked leads from ranked_leads.json."""
    try:
        with open(RANKED_LEADS_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return []  # Return an empty list if no leads file exists
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading ranked leads file: {str(e)}")

# --- Main Execution Block ---
if __name__ == "__main__":
    print("--- Starting Uvicorn Server ---")
    print("Access the API at http://127.0.0.1:8000")
    print("API documentation available at http://127.0.0.1:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)