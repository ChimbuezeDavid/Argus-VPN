#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "  🚀 CONFIGURING MULTI-CITY PROXY DISPATCHER ON ORACLE VM "
echo "=========================================================="

# 1. Install Redsocks
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y redsocks iptables-persistent

# 2. Generate redsocks.conf for our multi-city Webshare proxies
sudo tee /etc/redsocks.conf > /dev/null << 'EOF'
base {
    log_debug = off;
    log_info = on;
    log = "file:/var/log/redsocks.log";
    daemon = on;
    redirector = iptables;
}

// 🇺🇸 US New York Proxy (Port 12345 -> 38.154.185.97:6370)
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12345;
    ip = 38.154.185.97;
    port = 6370;
    type = socks5;
    login = "wvybfinb";
    password = "ky0dps1os6ir";
}

// 🇺🇸 US Los Angeles Proxy (Port 12346 -> 198.23.243.226:6361)
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12346;
    ip = 198.23.243.226;
    port = 6361;
    type = socks5;
    login = "wvybfinb";
    password = "ky0dps1os6ir";
}

// 🇬🇧 UK London Proxy (Port 12347 -> 31.59.20.176:6754)
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12347;
    ip = 31.59.20.176;
    port = 6754;
    type = socks5;
    login = "wvybfinb";
    password = "ky0dps1os6ir";
}

// 🇪🇸 Spain Madrid Proxy (Port 12348 -> 64.137.96.74:6641)
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12348;
    ip = 64.137.96.74;
    port = 6641;
    type = socks5;
    login = "wvybfinb";
    password = "ky0dps1os6ir";
}

// 🇯🇵 Japan Tokyo Proxy (Port 12349 -> 142.111.67.146:5611)
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12349;
    ip = 142.111.67.146;
    port = 5611;
    type = socks5;
    login = "wvybfinb";
    password = "ky0dps1os6ir";
}
EOF

# 3. Restart Redsocks
sudo systemctl restart redsocks
sudo systemctl enable redsocks

# 4. Configure IPTables Redirection for each Client Subnet
echo "[+] Configuring iptables redirection for multi-city exits..."

# Create REDSOCKS iptables chains
sudo iptables -t nat -N REDSOCKS_NY 2>/dev/null || true
sudo iptables -t nat -F REDSOCKS_NY
sudo iptables -t nat -A REDSOCKS_NY -d 0.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS_NY -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS_NY -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS_NY -d 169.254.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS_NY -d 172.16.0.0/12 -j RETURN
sudo iptables -t nat -A REDSOCKS_NY -d 192.168.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS_NY -p tcp -j REDIRECT --to-ports 12345

sudo iptables -t nat -N REDSOCKS_LA 2>/dev/null || true
sudo iptables -t nat -F REDSOCKS_LA
sudo iptables -t nat -A REDSOCKS_LA -d 0.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS_LA -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS_LA -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS_LA -d 169.254.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS_LA -d 172.16.0.0/12 -j RETURN
sudo iptables -t nat -A REDSOCKS_LA -d 192.168.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS_LA -p tcp -j REDIRECT --to-ports 12346

# Apply PREROUTING rules for WireGuard clients
sudo iptables -t nat -D PREROUTING -i wg0 -s 10.8.0.0/24 -p tcp -j REDSOCKS_NY 2>/dev/null || true
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.0.0/24 -p tcp -j REDSOCKS_NY

# Save iptables rules
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save | sudo tee /etc/iptables/rules.v4

echo ""
echo "=========================================================="
echo "  🎉 MULTI-CITY PROXY DISPATCHER ACTIVE & READY!          "
echo "=========================================================="
