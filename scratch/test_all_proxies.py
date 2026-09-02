import subprocess, json

proxies = [
    "31.59.20.176:6754",
    "45.38.107.97:6014",
    "198.105.121.200:6462",
    "64.137.96.74:6641",
    "198.23.243.226:6361",
    "38.154.185.97:6370",
    "84.247.60.125:6095",
    "142.111.67.146:5611",
    "191.96.254.138:6185",
    "31.58.9.4:6077"
]

print("=== Testing All Webshare Proxies ===")
for p in proxies:
    res = subprocess.run(["curl", "-s", "--max-time", "6", "-x", f"socks5://wvybfinb:ky0dps1os6ir@{p}", "https://ipinfo.io"], capture_output=True, text=True)
    try:
        data = json.loads(res.stdout)
        print(f"[{data.get('country')}] {data.get('city')} -> {p} (IP: {data.get('ip')})")
    except Exception as e:
        print(f"[FAIL] {p} -> {res.stdout.strip()[:60]}")
