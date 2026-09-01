import urllib.request
import json
import time

proxies = [
    {"ip": "31.59.20.176", "port": 6754, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "45.38.107.97", "port": 6014, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "198.105.121.200", "port": 6462, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "64.137.96.74", "port": 6641, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "198.23.243.226", "port": 6361, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "38.154.185.97", "port": 6370, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "84.247.60.125", "port": 6095, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "142.111.67.146", "port": 5611, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "191.96.254.138", "port": 6185, "user": "wvybfinb", "pass": "ky0dps1os6ir"},
    {"ip": "31.58.9.4", "port": 6077, "user": "wvybfinb", "pass": "ky0dps1os6ir"}
]

print("Scanning Webshare Proxies Locations...\n")
results = []
for p in proxies:
    ip = p["ip"]
    try:
        url = f"http://ip-api.com/json/{ip}?fields=status,country,countryCode,regionName,city,org"
        with urllib.request.urlopen(url, timeout=5) as res:
            d = json.loads(res.read().decode())
            country = d.get("country", "Unknown")
            code = d.get("countryCode", "??")
            city = d.get("city", "Unknown")
            region = d.get("regionName", "")
            org = d.get("org", "")
            p["country"] = country
            p["countryCode"] = code
            p["city"] = city
            p["region"] = region
            p["org"] = org
            print(f"[{code}] {country} - {city}, {region} ({ip}:{p['port']})")
            results.append(p)
    except Exception as e:
        print(f"Error {ip}: {e}")
    time.sleep(0.3)

with open("deploy/webshare_nodes.json", "w") as f:
    json.dump(results, f, indent=2)
