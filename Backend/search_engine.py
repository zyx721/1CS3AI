import requests
import google.generativeai as genai
from bs4 import BeautifulSoup
import re
import json
import time

SERPER_API_KEY = "42e856cc5ef002c1597514cd71b67fb2e5cd6428"
GEMINI_API_KEY = "AIzaSyDTZhbhhS7o9a55vxaF53L1zpZ08xk2d-w"

genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel("models/gemini-2.5-flash")

def generate_queries(service, location):
    prompt = f"""You are a B2B AI agent. A business offers: '{service}' and wants clients in '{location}'.\n" \
             f"Generate 5 highly specific, actionable Google search queries to find businesses (with decision-makers) who may need this service. " \
             f"Queries should target business needs, pain points, or relevant industries.\n" \
             f"Return only the queries as a Python list, no explanation, no code block, just the list.\n"""
    response = gemini_model.generate_content(prompt)
    text = response.text.strip()
    if text.startswith('```'):
        text = text.lstrip('`').split('\n', 1)[-1]
    if text.endswith('```'):
        text = text.rstrip('`').rsplit('\n', 1)[0]
    try:
        queries = eval(text)
        if isinstance(queries, list):
            return [str(q).strip('- ').strip() for q in queries if str(q).strip() and not str(q).strip().startswith(('```', '[', ']'))]
    except Exception:
        pass
    queries = [q.strip('- ').strip() for q in text.split('\n') if q.strip() and not q.strip().startswith(('```', '[', ']'))]
    queries = [q for q in queries if len(q) > 3 and ' ' in q]
    return queries

def serper_search(query, max_results=10):
    url = "https://google.serper.dev/search"
    headers = {"X-API-KEY": SERPER_API_KEY, "Content-Type": "application/json"}
    payload = {"q": query}
    res = requests.post(url, headers=headers, json=payload)
    if res.status_code != 200:
        print(f"[!] Serper error: {res.status_code} {res.text}")
        return []
    data = res.json()
    return [r["link"] for r in data.get("organic", [])[:max_results]]

def scrape_page(url):
    try:
        res = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
        soup = BeautifulSoup(res.text, "html.parser")
        text = soup.get_text()
        phones = re.findall(r'\+?\d[\d\s\-\(\)]{7,}\d', text)
        emails = re.findall(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+", text)
        address = None
        for tag in soup.find_all(['address']):
            if tag.get_text(strip=True):
                address = tag.get_text(strip=True)
                break
        socials = []
        for a in soup.find_all('a', href=True):
            if any(s in a['href'] for s in ['facebook.com', 'linkedin.com', 'twitter.com', 'instagram.com']):
                socials.append(a['href'])
        return text[:3000], list(set(phones)), list(set(emails)), address, list(set(socials))
    except Exception as e:
        print(f"[!] Error scraping {url}: {e}")
        return "", [], [], None, []

def analyze_lead(url, text, phones, emails, address, socials):
    import re
    prompt = f"""You are a business profiler.\n\nGiven this webpage content:\n\n"""\
             f"{text}\n"\
             f"\nExtract the following as JSON:\n"\
             f"- niche: What kind of business is this? (e.g., cafe, lawyer, marketing agency)\n"\
             f"- description: 1-line summary of what they do\n"\
             f"- address: If available, the business address or location\n"\
             f"- social_links: List of social media links (if any)\n"\
             f"- phone: Main phone number (if any)\n"\
             f"- email: Main email (if any)\n"\
             f"Output format: JSON object with keys niche, description, address, social_links, phone, email.\n"""
    try:
        response = gemini_model.generate_content(prompt)
        if not response.text.strip():
            print(f"[!] Gemini returned empty response for {url}")
            return None
        try:
            result = json.loads(response.text)
        except Exception:
            match = re.search(r'\{.*\}', response.text, re.DOTALL)
            if match:
                try:
                    result = json.loads(match.group(0))
                except Exception:
                    print(f"[!] Gemini response not valid JSON for {url}: {response.text}")
                    return None
            else:
                print(f"[!] Gemini response not valid JSON for {url}: {response.text}")
                return None
        return {
            "url": url,
            "niche": result.get("niche"),
            "description": result.get("description"),
            "address": result.get("address") or address,
            "social_links": result.get("social_links") or socials,
            "phone": result.get("phone") or (phones[0] if phones else None),
            "email": result.get("email") or (emails[0] if emails else None)
        }
    except Exception as e:
        print(f"[!] Gemini error: {e}")
        return None

def run_agent(service, location):
    print(f"\n[🔍] Searching leads for: {service} in {location}")
    queries = generate_queries(service, location)

    all_links = []
    for query in queries:
        print(f"[🌐] Searching: {query}")
        links = serper_search(query)
        all_links.extend(links)
        time.sleep(1)
    all_links = list(set(all_links))  

    results = []
    for idx, url in enumerate(all_links, 1):
        if url.endswith('.pdf') or 'linkedin.com' in url or 'researchgate.net' in url:
            print(f"[!] Skipping non-HTML or non-scrapable URL: {url}")
            continue
        print(f"\n[🔗] ({idx}/{len(all_links)}) Scraping: {url}")
        text, phones, emails, address, socials = scrape_page(url)
        if len(text) < 100:
            continue
        lead = analyze_lead(url, text, phones, emails, address, socials)
        if lead:
            print(f"[✅] Lead accepted: {lead['niche']} | {lead['url']}")
            results.append(lead)
        else:
            print(f"[❌] Rejected.")
        time.sleep(1)

    print("\n🎯 Final JSON Output:")
    print(json.dumps(results, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    print("💼 AI B2B Lead Finder")
    service = input("Enter your service (e.g. web developer): ").strip()
    location = input("Enter your target location (e.g. Tunisia): ").strip()
    run_agent(service, location)
