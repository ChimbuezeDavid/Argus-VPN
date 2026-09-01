#!/usr/bin/env python3
"""
==============================================================================
Argus VPN - Automated Global Fleet Orchestrator (Vultr API v2)
==============================================================================
Deploys, configures, and integrates WireGuard exit nodes in 1-click across
global datacenters using the Vultr Cloud API.

Usage:
  python deploy_fleet.py --api-key YOUR_VULTR_API_KEY --regions london,tokyo,singapore,toronto,paris
"""

import argparse
import base64
import json
import os
import sys
import time
import urllib.request
import urllib.error

# Ensure UTF-8 output on Windows terminal
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)

VULTR_API_BASE = "https://api.vultr.com/v2"

# Region Mapping: Friendly Name / Code -> Vultr Region ID + Geo Metadata
REGIONS_CATALOG = {
    # 🇬🇧 United Kingdom
    "london": {
        "id": "lhr", "city": "London", "country": "United Kingdom", "countryCode": "GB",
        "regionGroup": "Europe", "flag": "🇬🇧", "lat": 51.5074, "lng": -0.1278
    },
    # 🇯🇵 Japan
    "tokyo": {
        "id": "nrt", "city": "Tokyo", "country": "Japan", "countryCode": "JP",
        "regionGroup": "Asia", "flag": "🇯🇵", "lat": 35.6762, "lng": 139.6503
    },
    # 🇸🇬 Singapore
    "singapore": {
        "id": "sgp", "city": "Singapore", "country": "Singapore", "countryCode": "SG",
        "regionGroup": "Asia", "flag": "🇸🇬", "lat": 1.3521, "lng": 103.8198
    },
    # 🇨🇦 Canada
    "toronto": {
        "id": "yto", "city": "Toronto", "country": "Canada", "countryCode": "CA",
        "regionGroup": "Americas", "flag": "🇨🇦", "lat": 43.6532, "lng": -79.3832
    },
    # 🇫🇷 France
    "paris": {
        "id": "cdg", "city": "Paris", "country": "France", "countryCode": "FR",
        "regionGroup": "Europe", "flag": "🇫🇷", "lat": 48.8566, "lng": 2.3522
    },
    # 🇳🇱 Netherlands
    "amsterdam": {
        "id": "ams", "city": "Amsterdam", "country": "Netherlands", "countryCode": "NL",
        "regionGroup": "Europe", "flag": "🇳🇱", "lat": 52.3676, "lng": 4.9041
    },
    # 🇦🇺 Australia
    "sydney": {
        "id": "syd", "city": "Sydney", "country": "Australia", "countryCode": "AU",
        "regionGroup": "Asia", "flag": "🇦🇺", "lat": -33.8688, "lng": 151.2093
    },
    # 🇩🇪 Germany
    "frankfurt": {
        "id": "fra", "city": "Frankfurt", "country": "Germany", "countryCode": "DE",
        "regionGroup": "Europe", "flag": "🇩🇪", "lat": 50.1109, "lng": 8.6821
    },
    # 🇺🇸 US West (Los Angeles)
    "losangeles": {
        "id": "lax", "city": "Los Angeles", "country": "United States", "countryCode": "US",
        "regionGroup": "Americas", "flag": "🇺🇸", "lat": 34.0522, "lng": -118.2437
    },
    # 🇺🇸 US Central (Chicago)
    "chicago": {
        "id": "ord", "city": "Chicago", "country": "United States", "countryCode": "US",
        "regionGroup": "Americas", "flag": "🇺🇸", "lat": 41.8781, "lng": -87.6298
    },
    # 🇺🇸 US South (Miami)
    "miami": {
        "id": "mia", "city": "Miami", "country": "United States", "countryCode": "US",
        "regionGroup": "Americas", "flag": "🇺🇸", "lat": 25.7617, "lng": -80.1918
    },
    # 🇺🇸 US South-Central (Dallas)
    "dallas": {
        "id": "dfw", "city": "Dallas", "country": "United States", "countryCode": "US",
        "regionGroup": "Americas", "flag": "🇺🇸", "lat": 32.7767, "lng": -96.7970
    },
    # 🇺🇸 US East (New York / NJ)
    "newyork": {
        "id": "ewr", "city": "New York", "country": "United States", "countryCode": "US",
        "regionGroup": "Americas", "flag": "🇺🇸", "lat": 40.7128, "lng": -74.0060
    },
    # 🇰🇷 South Korea
    "seoul": {
        "id": "icn", "city": "Seoul", "country": "South Korea", "countryCode": "KR",
        "regionGroup": "Asia", "flag": "🇰🇷", "lat": 37.5665, "lng": 126.9780
    },
    # 🇧🇷 Brazil
    "saopaulo": {
        "id": "sao", "city": "São Paulo", "country": "Brazil", "countryCode": "BR",
        "regionGroup": "Americas", "flag": "🇧🇷", "lat": -23.5505, "lng": -46.6333
    },
    # 🇮🇳 India (Mumbai)
    "mumbai": {
        "id": "bom", "city": "Mumbai", "country": "India", "countryCode": "IN",
        "regionGroup": "Asia", "flag": "🇮🇳", "lat": 19.0760, "lng": 72.8777
    },
    # 🇿🇦 South Africa
    "johannesburg": {
        "id": "jnb", "city": "Johannesburg", "country": "South Africa", "countryCode": "ZA",
        "regionGroup": "Africa", "flag": "🇿🇦", "lat": -26.2041, "lng": 28.0473
    },
    # 🇪🇸 Spain
    "madrid": {
        "id": "mad", "city": "Madrid", "country": "Spain", "countryCode": "ES",
        "regionGroup": "Europe", "flag": "🇪🇸", "lat": 40.4168, "lng": -3.7038
    },
    # 🇸🇪 Sweden
    "stockholm": {
        "id": "arn", "city": "Stockholm", "country": "Sweden", "countryCode": "SE",
        "regionGroup": "Europe", "flag": "🇸🇪", "lat": 59.3293, "lng": 18.0686
    },
    # 🇵🇱 Poland
    "warsaw": {
        "id": "waw", "city": "Warsaw", "country": "Poland", "countryCode": "PL",
        "regionGroup": "Europe", "flag": "🇵🇱", "lat": 52.2297, "lng": 21.0122
    },
    # 🇲🇽 Mexico
    "mexicocity": {
        "id": "mex", "city": "Mexico City", "country": "Mexico", "countryCode": "MX",
        "regionGroup": "Americas", "flag": "🇲🇽", "lat": 19.4326, "lng": -99.1332
    },
    # 🇮🇱 Israel
    "telaviv": {
        "id": "tlv", "city": "Tel Aviv", "country": "Israel", "countryCode": "IL",
        "regionGroup": "Middle East", "flag": "🇮🇱", "lat": 32.0853, "lng": 34.7818
    }
}

CLOUD_INIT_SCRIPT = """#!/usr/bin/env bash
curl -sSL https://raw.githubusercontent.com/ChimbuezeDavid/Argus-VPN/main/deploy/setup_node.sh | bash
"""

def vultr_request(endpoint, api_key, method="GET", data=None):
    url = f"{VULTR_API_BASE}/{endpoint}"
    req = urllib.request.Request(url, method=method)
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")
    if data:
        req.data = json.dumps(data).encode("utf-8")
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            resp_body = res.read().decode("utf-8")
            return json.loads(resp_body) if resp_body else {}
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode("utf-8")
        print(f"[-] Vultr API Error ({e.code}): {error_msg}")
        return None
    except Exception as e:
        print(f"[-] Connection Error: {e}")
        return None

def get_ubuntu_os_id(api_key):
    res = vultr_request("os", api_key)
    if not res or "os" not in res:
        return 2284 # Fallback ID for Ubuntu 24.04 x64
    for item in res["os"]:
        if "Ubuntu 24.04" in item.get("name", ""):
            return item["id"]
        if "Ubuntu 22.04" in item.get("name", ""):
            return item["id"]
    return 2284

def deploy_node(api_key, region_key, os_id):
    meta = REGIONS_CATALOG[region_key]
    user_data_b64 = base64.b64encode(CLOUD_INIT_SCRIPT.encode("utf-8")).decode("utf-8")

    slug = region_key.lower().replace(" ", "").replace("_", "-")
    payload = {
        "region": meta["id"],
        "plan": "vc2-1c-1gb", # Standard $5/mo plan
        "os_id": os_id,
        "label": f"argus-node-{meta['id']}",
        "hostname": f"{meta['countryCode'].lower()}-{slug}-1.argusvpn.com",
        "enable_ipv6": False,
        "backups": "disabled",
        "user_data": user_data_b64
    }

    print(f"[+] Deploying {meta['flag']} {meta['city']}, {meta['country']} (Region: {meta['id']})...")
    res = vultr_request("instances", api_key, method="POST", data=payload)
    if res and "instance" in res:
        inst = res["instance"]
        print(f"    √ Instance created! ID: {inst['id']}")
        return inst
    return None

def wait_for_instance_ip(api_key, instance_id, timeout_sec=180):
    start = time.time()
    while time.time() - start < timeout_sec:
        res = vultr_request(f"instances/{instance_id}", api_key)
        if res and "instance" in res:
            inst = res["instance"]
            ip = inst.get("main_ip")
            status = inst.get("status")
            if ip and ip != "0.0.0.0" and status == "active":
                return ip
        time.sleep(5)
    return None

def fetch_node_public_key(public_ip, max_retries=15):
    print(f"    [i] Waiting for WireGuard setup to finish on {public_ip}:4001...")
    for _ in range(max_retries):
        time.sleep(6)
        try:
            req = urllib.request.Request(f"http://{public_ip}:4001/api/info", headers={"User-Agent": "ArgusFleetOrchestrator"})
            with urllib.request.urlopen(req, timeout=5) as res:
                if res.status == 200:
                    data = json.loads(res.read().decode("utf-8"))
                    pub_key = data.get("serverPublicKey")
                    if pub_key:
                        return pub_key
        except Exception:
            pass
    return None

def main():
    parser = argparse.ArgumentParser(description="Argus VPN Global Fleet Orchestrator")
    parser.add_argument("--api-key", required=True, help="Your Vultr API Key")
    parser.add_argument("--regions", default="london,tokyo,singapore,toronto,paris",
                        help="Comma-separated list of cities (e.g. london,tokyo,singapore,toronto,paris)")
    args = parser.parse_args()

    requested_regions = [r.strip().lower() for r in args.regions.split(",") if r.strip().lower() in REGIONS_CATALOG]
    if not requested_regions:
        print("[-] No valid regions requested. Available regions:")
        for k, v in REGIONS_CATALOG.items():
            print(f"    - {k} ({v['flag']} {v['city']}, {v['country']})")
        sys.exit(1)

    print("========================================================")
    print("      ARGUS VPN GLOBAL FLEET AUTO-DEPLOYMENT           ")
    print("========================================================")
    print(f"[+] Regions to deploy: {len(requested_regions)} locations ({', '.join(requested_regions)})")
    
    os_id = get_ubuntu_os_id(args.api_key)
    deployed_instances = []

    # 1. Launch Instances concurrently on Vultr
    for r_key in requested_regions:
        inst = deploy_node(args.api_key, r_key, os_id)
        if inst:
            deployed_instances.append({"region_key": r_key, "id": inst["id"]})

    # 2. Wait for IPs and WireGuard Initialization
    results = []
    for item in deployed_instances:
        r_key = item["region_key"]
        meta = REGIONS_CATALOG[r_key]
        print(f"\n[+] Provisioning {meta['flag']} {meta['city']}...")
        ip = wait_for_instance_ip(args.api_key, item["id"])
        if not ip:
            print(f"[-] Timed out waiting for IP on {meta['city']}")
            continue
        print(f"    √ Public IP Assigned: {ip}")
        pub_key = fetch_node_public_key(ip)
        if pub_key:
            print(f"    √ WireGuard Public Key: {pub_key}")
            results.append({
                "city": meta["city"],
                "country": meta["country"],
                "countryCode": meta["countryCode"],
                "region": meta["regionGroup"],
                "flag": meta["flag"],
                "lat": meta["lat"],
                "lng": meta["lng"],
                "publicIp": ip,
                "publicKey": pub_key,
                "port": 51820
            })
        else:
            print(f"[-] Node daemon not responding yet on {ip}:4001")

    print("\n========================================================")
    print("      DEPLOYMENT SUMMARY (READY FOR APP INTEGRATION)    ")
    print("========================================================")
    print(json.dumps(results, indent=2))

    # Save to JSON file
    out_path = os.path.join(os.path.dirname(__file__), "deployed_nodes.json")
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\n[√] Fleet manifest saved to: {out_path}")

if __name__ == "__main__":
    main()
