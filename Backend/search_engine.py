# search_engine.py
import requests
import google.generativeai as genai
from bs4 import BeautifulSoup
import re
import json
import time
import os

SERPER_API_KEY = "42e856cc5ef002c1597514cd71b67fb2e5cd6428"
GEMINI_API_KEY = "AIzaSyDTZhbhhS7o9a55vxaF53L1zpZ08xk2d-w"

# Configure Gemini
genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel("gemini-2.5-flash") # Updated model name

def serper_search(query, max_results=10):
    """Performs a Google search using the Serper API."""
    print(f"[DEBUG] Serper searching for: '{query}'")
    url = "https://google.serper.dev/search"
    headers = {"X-API-KEY": SERPER_API_KEY, "Content-Type": "application/json"}
    payload = {"q": query}
    try:
        res = requests.post(url, headers=headers, json=payload, timeout=10)
        res.raise_for_status() # Raise an exception for bad status codes
        data = res.json()
        return [r["link"] for r in data.get("organic", [])[:max_results]]
    except requests.exceptions.RequestException as e:
        print(f"[!] Serper error: {e}")
        return []

def scrape_page(url):
    """Scrapes a webpage to extract text and contact details."""
    try:
        res = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
        res.raise_for_status()
        soup = BeautifulSoup(res.text, "html.parser")
        text = soup.get_text()
        text = re.sub(r'\s+', ' ', text).strip()
        # Find contact info (simplified for robustness)
        phones = list(set(re.findall(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}', text)))
        emails = list(set(re.findall(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', text)))
        return text[:4000], phones, emails # Return a larger chunk of text for better analysis
    except Exception as e:
        print(f"[!] Error scraping {url}: {e}")
        return "", [], []

def analyze_lead(url, text, phones, emails):
    """Uses Gemini to analyze the scraped text and format it as a lead."""
    prompt = f"""
        You are a B2B lead analyst. Based on the following website text, extract the company's information.

        Website Text:
        ---
        {text}
        ---

        Extracted Information from scraping:
        - Potential Phones: {phones}
        - Potential Emails: {emails}

        Your Task:
        Analyze the text and provide a structured JSON object with the following keys:
        - "company_name": The name of the business.
        - "niche": A specific description of the business (e.g., 'Corporate Law Firm', 'Digital Marketing Agency for SaaS', 'Craft Coffee Roastery').
        - "description": A one-sentence summary of what the company does or offers.
        - "phone": The most likely primary contact phone number.
        - "email": The best contact email address (prefer info@, contact@, sales@ over personal names).
        
        If a value cannot be found, set it to null.
        Respond ONLY with the JSON object.
    """
    try:
        response = gemini_model.generate_content(prompt)
        json_str = re.search(r'```json\s*(\{.*?\})\s*```', response.text, re.DOTALL)
        if json_str:
            lead_data = json.loads(json_str.group(1))
        else: 
            lead_data = json.loads(response.text)
            
        lead_data["url"] = url 
        return lead_data
    except Exception as e:
        print(f"[!] Gemini analysis error for {url}: {e}")
        print(f"    Response text was: {response.text}")
        return None

def run_agent(service: str):
    """
    The main agent function that orchestrates the lead generation process.
    This is designed to be called from the LangGraph application.
    """
    
    print(f"[🌐] Starting lead search with query: {service}")
    links = serper_search(service)
    if not links:
        print("[!] No links found from search.")
        return []

    results = []
    for url in links:
        print(f"\n[🔗] Processing: {url}")
        text, phones, emails = scrape_page(url)
        if len(text) < 100:
            print(f"[!] Skipping {url} due to insufficient content.")
            continue
            
        lead = analyze_lead(url, text, phones, emails)
        if lead:
            print(f"[✅] Lead qualified: {lead.get('company_name', 'N/A')} | {lead.get('niche', 'N/A')}")
            results.append(lead)
        else:
            print(f"[❌] Lead rejected for {url}.")
        time.sleep(1) 

    print(f"\n[🎯] Agent finished. Found {len(results)} qualified leads.")
    return results

