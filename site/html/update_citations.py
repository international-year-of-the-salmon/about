import requests
import json
from datetime import datetime

def get_crossref_citations(doi):
    headers = {"Accept": "application/json"}
    cited_by_url = f"https://api.crossref.org/works?filter=reference:{doi}"
    cursor = "*"
    citing_works = []

    while True:
        response = requests.get(
            cited_by_url,
            headers=headers,
            params={"rows": 1000, "cursor": cursor, "mailto": "your-email@example.com"}
        )
        if response.status_code != 200:
            break

        data = response.json().get("message", {})
        citing_works.extend(data.get("items", []))
        cursor = data.get("next-cursor")
        if not cursor:
            break

    results = []
    for item in citing_works:
        results.append({
            "title": item.get("title", ["No Title"])[0],
            "doi": item.get("DOI", "No DOI"),
            "published": item.get("created", {}).get("date-time", ""),
        })

    return results

# Update this with your target DOI
DOI = "10.1038/s41586-020-2649-2"
citations = get_crossref_citations(DOI)

output = {
    "doi": DOI,
    "last_updated": datetime.utcnow().isoformat(),
    "citation_count": len(citations),
    "citing_works": citations
}

# Save as JSON
with open("citations.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)
