import urllib.request
import json
import time

api_key = "2SBVQPUF6S7RUTNVSSHYIRR6KA4GLT4R4QVQ"

def vultr_request(endpoint, method="GET"):
    url = f"https://api.vultr.com/v2/{endpoint}"
    req = urllib.request.Request(
        url,
        method=method,
        headers={"Authorization": f"Bearer {api_key}"}
    )
    try:
        with urllib.request.urlopen(req) as res:
            resp_body = res.read().decode("utf-8")
            return json.loads(resp_body) if resp_body else {}
    except Exception as e:
        print(f"Error {method} {endpoint}:", e)
        return None

# 1. List all instances
data = vultr_request("instances")
instances = data.get("instances", [])
print(f"Found {len(instances)} active instances on Vultr.")

# 2. Delete each instance
for inst in instances:
    inst_id = inst.get("id")
    label = inst.get("label") or inst.get("region")
    print(f"[-] Deleting instance: {label} ({inst_id})...")
    vultr_request(f"instances/{inst_id}", method="DELETE")

print("\n[√] All instances deletion requested! Verifying...")
time.sleep(3)
check_data = vultr_request("instances")
remaining = len(check_data.get("instances", []))
print(f"[√] Remaining instances on Vultr: {remaining}")
