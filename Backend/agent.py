import os
import json
import uuid
import re
from typing import Annotated, Any, Dict, List, Optional, Sequence, Set, TypedDict
from dotenv import load_dotenv
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, ToolMessage, SystemMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.tools import tool
from langgraph.graph.message import add_messages
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from difflib import SequenceMatcher
import google.generativeai as genai
import cv2
import numpy as np

STORE_NAME = None
DOMAIN = None
LOCATION = None
OPERATING_HOURS = None
ONLINE_HOURS = None
SERVICES = None
BUSINESS_CONFIG_LOADED = False

import pickle
load_dotenv()
class AgentState(TypedDict):
    messages: Annotated[Sequence[BaseMessage], add_messages]


base_agent = ChatGoogleGenerativeAI(model="gemini-2.5-flash").bind_tools(tools)

def load_products_db(PRODUCTS_DB_FILE) -> List[Dict[str, Any]]:
    if not os.path.exists(PRODUCTS_DB_FILE):
        raise FileNotFoundError(f"Products database file not found: {PRODUCTS_DB_FILE}")
    with open(PRODUCTS_DB_FILE, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
            return data.get('products', [])
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in products database: {e}")



def load_business_config(config_path):
    global STORE_NAME, DOMAIN, LOCATION, OPERATING_HOURS, ONLINE_HOURS, SERVICES, BUSINESS_CONFIG_LOADED
    if BUSINESS_CONFIG_LOADED:
        return
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Business config file not found: {config_path}")
    with open(config_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        STORE_NAME = data.get("store_name", "Store")
        DOMAIN = data.get("domain", "laptop")
        LOCATION = data.get("location", "")
        OPERATING_HOURS = data.get("operating_hours", "")
        ONLINE_HOURS = data.get("online_hours", "")
        SERVICES = data.get("services", "")
        BUSINESS_CONFIG_LOADED = True
        
def model_call(state : AgentState) -> AgentState:
    """
    The main LLM agent's call. It decides to answer directly or call a tool.
    """
    global paths
    load_business_config(paths["business_config"])
    system_prompt = SystemMessage(content=f"""You are a helpful and friendly AI assistant for {STORE_NAME}, a {DOMAIN} store in Algeria.
                        Your Two Tasks Only:
                            Answer the user's question if it’s simple and you know the answer.
                            Route the user to the correct agent if their request needs more help.
                        **Language** : your responde should be mainly in the user language you have these languages [algerian,french,MSA ,english] if query in algerian your responde should is algerian dialct writen in arabic alphabet and dont mixed it up with other dialcts such as morrocan or tunisan . 
                                  if query clearly in just french respond in french if in MSA respond in MSA..
                        steps:
                        1- Detect the language of the user's last query.
                        2- Respond in the same language as the user latley used.
                        3- feel free to switch between french and algerian
                        4- if you are confused use algerian 
                        When to Answer:
                            Use the following knowledge to answer questions directly and briefly:
                        Store Info:
                            Store Name: {STORE_NAME}
                            Location: {LOCATION}
                            Hours:
                            {OPERATING_HOURS}
                                  
                        Online Store:
                            {ONLINE_HOURS}

                        Products & Services:
                            {SERVICES}

                        How You Can Help:
                            Answer product or service questions
                            Give {DOMAIN} details
                            Help with purchases or order tracking
                            Report issues

                        Stay Updated:
                            New offers and arrivals posted regularly on our Instagram page
                            (with images, specs, and prices)
                                  
                        When to Route:
                            If the user needs something beyond your knowledge or wants to take an action, route them to one of these agents:
                                Search_Agent – User wants to find a product you don’t have enough info about
                                Make_Purchase_Agent – User wants to buy a {DOMAIN}
                                Check_Order_Agent – User wants to check order status
                                Help_Agent – User seems to have a problem, stuck, or asks to talk to a human 
                                Image_Agent- user sends an image and he is asking if this product avilable for us
                                  note : there is now 2 types of searching . normal search using "Search_Agent" and image search using "Image_Agent"
                                   Only route to human agent when the user explicitly requests human assistance for a real problem they're facing.
                                  
                                    Important: When routing to a specialist agent, consider the overall recent context of the conversation, not just the last message. Route based on the user’s latest intent or topic, not isolated statements.
                                    Additionally, do not route to the Make_Purchase_Agent unless the user has specifically provided a product name.
                                            Always be brief, clear, and friendly. Just answer or route.

                                         
                                  """)
    response = base_agent.invoke([system_prompt] + state["messages"])
    return {"messages": [response]}


def llm_router_decision(state: AgentState) -> str:
    """
    Decides the next step based on the last message from the LLM (process node).
    Returns "call_route_tool" if a tool call (specifically 'route') is made.
    Returns "end_conversation" if the LLM responds directly with text.
    """
    last_message = state["messages"][-1]
    if last_message.tool_calls:
        tool_name = last_message.tool_calls[0]["name"]
        if tool_name == "route" :
            return "call_route_tool"
        elif tool_name == "place_order_tool" :
            return "order_call_route_tool"
        elif tool_name == "search_products_tool" :
            return "search_call_route_tool"
        elif tool_name == "check_order" :
            return "check_call_route_tool"
        elif tool_name == "call_human_tool" :
            return "human_call_route_tool"
        elif tool_name == "search_image" :
            return "image_call_route_tool"
        else:
            print(f"DEBUG: Unexpected tool call: {tool_name}")
            return "end_with_error" 
    else:
        return "end_conversation"


def route_tool_output_decision(state: AgentState) -> str:
    """
    Decides the next specialist agent based on the output of the 'route' tool.
    This function is called AFTER the ToolNode executes the 'route' tool.
    """
    tool_output_message = state["messages"][-1]
    
    if isinstance(tool_output_message, ToolMessage):
        agent_name = tool_output_message.content
        print(f"DEBUG: Route tool returned: '{agent_name}'")

        if agent_name == "Search_Agent":
            return "Search_Agent"
        elif agent_name == "Make_Purchase_Agent":
            return "Make_Purchase_Agent"
        elif agent_name == "Check_Order_Agent":
            return "Check_Order_Agent"
        elif agent_name == "Help_Agent":
            return "Help_Agent"
        elif agent_name == "Image_Agent":
            return "Image_Agent"
        else:
            print(f"DEBUG: Invalid route tool output: {agent_name}")
            return "invalid_route_output"
    
    print("DEBUG: Last message was not a ToolMessage after tool execution.")
    return "end_with_error" 
graph = StateGraph(AgentState)

graph.add_node("process", model_call) 
graph.add_node("call_route_tool", ToolNode(tools=tools)) 

graph.add_node("Search_Agent", Search_Agent)
graph.add_node("search_call_route_tool", ToolNode(tools=search_tools)) 
graph.add_conditional_edges(
    "Search_Agent",
    llm_router_decision,
    {
        "end_conversation": END,              
        "search_call_route_tool": "search_call_route_tool",
        "end_with_error": END,             
    }
)
graph.add_edge("search_call_route_tool", "Search_Agent")

graph.add_node("Make_Purchase_Agent", Make_Purchase_Agent)
graph.add_node("order_call_route_tool", ToolNode(tools=order_tools))
graph.add_conditional_edges(
    "Make_Purchase_Agent",
    llm_router_decision,
    {
        "end_conversation": END,              
        "order_call_route_tool": "order_call_route_tool",
        "end_with_error": END,               
    }
)
graph.add_edge("order_call_route_tool", "Make_Purchase_Agent")

graph.add_node("Check_Order_Agent", Check_Order_Agent)
graph.add_node("check_call_route_tool", ToolNode(tools=check_order_tools))
graph.add_conditional_edges(
    "Check_Order_Agent",
    llm_router_decision,
    {
        "end_conversation": END,             
        "check_call_route_tool": "check_call_route_tool", 
        "end_with_error": END,                
    }
)

graph.add_edge("check_call_route_tool", "Check_Order_Agent")


graph.add_node("Help_Agent", Human_Router_Agent)
graph.add_node("human_call_route_tool", ToolNode(tools=human_tools))
graph.add_conditional_edges(
    "Help_Agent",
    llm_router_decision,
    {
        "end_conversation": END,              
        "human_call_route_tool": "human_call_route_tool", 
        "end_with_error": END,                
    }
)
graph.add_edge("human_call_route_tool", END)

graph.add_node("Image_Agent", Image_Agent)
graph.add_node("image_call_route_tool", ToolNode(tools=image_tools))
graph.add_conditional_edges(
    "Image_Agent",
    llm_router_decision,
    {
        "end_conversation": END,              
        "image_call_route_tool": "image_call_route_tool", 
        "end_with_error": END,                
    }
)
graph.add_edge("image_call_route_tool", "Image_Agent")

graph.set_entry_point("process")

graph.add_conditional_edges(
    "process",
    llm_router_decision,
    {
        "call_route_tool": "call_route_tool", 
        "end_conversation": END,              
        "end_with_error": END,                
    }
)

graph.add_conditional_edges(
    "call_route_tool",
    route_tool_output_decision,
    {
        "Search_Agent": "Search_Agent",
        "Make_Purchase_Agent": "Make_Purchase_Agent",
        "Check_Order_Agent": "Check_Order_Agent",
        "Help_Agent": "Help_Agent",
        "Image_Agent":"Image_Agent",
        "invalid_route_output": END, 
        "end_with_error": END,      
    }
)

app = graph.compile()

