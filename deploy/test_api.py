import urllib.request
import json

api_key = "2SBVQPUF6S7RUTNVSSHYIRR6KA4GLT4R4QVQ"

req = urllib.request.Request(
    "https://api.vultr.com/v2/instances",
    headers={"Authorization": f"Bearer {api_key}"}
)

with urllib.request.urlopen(req) as res:
    data = json.loads(res.read().decode())
    print(f"Total existing instances: {len(data.get('instances', []))}")
    for inst in data.get('instances', []):
        print(f"  - ID: {inst.get('id')} | Region: {inst.get('region')} | IP: {inst.get('main_ip')} | Status: {inst.get('status')} | Label: {inst.get('label')}")
