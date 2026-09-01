import urllib.request
import json

api_key = "2SBVQPUF6S7RUTNVSSHYIRR6KA4GLT4R4QVQ"

def get_data(endpoint):
    req = urllib.request.Request(
        f"https://api.vultr.com/v2/{endpoint}",
        headers={"Authorization": f"Bearer {api_key}"}
    )
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read().decode())

plans = get_data("plans")
print("=== AVAILABLE PLANS ===")
for p in plans.get("plans", []):
    if p.get("monthly_cost") in [3.5, 5.0, 6.0] or "vc2" in p.get("id", ""):
        print(f"Plan: {p.get('id')} | Cost: ${p.get('monthly_cost')}/mo | RAM: {p.get('ram')}MB | Locations count: {len(p.get('locations', []))}")
        print("  Locations:", ", ".join(p.get("locations", [])[:15]))
