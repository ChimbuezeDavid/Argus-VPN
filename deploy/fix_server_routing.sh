#!/usr/bin/env bash
set -e

echo "=== Comprehensive Server Routing & Forwarding Fix ==="

# 1. Enable IPv4 Forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo sysctl -w net.ipv4.conf.all.forwarding=1
sudo sysctl -w net.ipv4.conf.wg0.forwarding=1
sudo sysctl -w net.ipv4.conf.ens3.forwarding=1

# 2. Flush FORWARD and NAT tables cleanly
sudo iptables -F FORWARD
sudo iptables -t nat -F PREROUTING
sudo iptables -t nat -F POSTROUTING
sudo iptables -t mangle -F

# 3. Mangle Table: MSS Clamping (Prevents website hanging/stalling on mobile networks)
sudo iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 4. FORWARD Table: Unrestricted Bi-directional Traffic
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wg0 -o ens3 -j ACCEPT
sudo iptables -A FORWARD -i ens3 -o wg0 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo iptables -A FORWARD -j ACCEPT

# 5. NAT Table: Set up City Proxy Chains
for city in NY LA UK ES JP; do
    sudo iptables -t nat -N REDSOCKS_${city} 2>/dev/null || true
    sudo iptables -t nat -F REDSOCKS_${city}
    sudo iptables -t nat -A REDSOCKS_${city} -d 0.0.0.0/8 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${city} -d 10.0.0.0/8 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${city} -d 127.0.0.0/8 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${city} -d 169.254.0.0/16 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${city} -d 172.16.0.0/12 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${city} -d 192.168.0.0/16 -j RETURN
done

sudo iptables -t nat -A REDSOCKS_NY -p tcp -j REDIRECT --to-ports 12345
sudo iptables -t nat -A REDSOCKS_LA -p tcp -j REDIRECT --to-ports 12346
sudo iptables -t nat -A REDSOCKS_UK -p tcp -j REDIRECT --to-ports 12347
sudo iptables -t nat -A REDSOCKS_ES -p tcp -j REDIRECT --to-ports 12348
sudo iptables -t nat -A REDSOCKS_JP -p tcp -j REDIRECT --to-ports 12349

# 6. Route wireguard subnets
# NY / Default
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.1.0/24 -p tcp -j REDSOCKS_NY
# LA
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.2.0/24 -p tcp -j REDSOCKS_LA
# UK
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.3.0/24 -p tcp -j REDSOCKS_UK
# ES
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.4.0/24 -p tcp -j REDSOCKS_ES
# JP
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.5.0/24 -p tcp -j REDSOCKS_JP
# Fallback / Default subnet (10.8.0.x) -> NY Proxy
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.0.0/24 -p tcp -j REDSOCKS_NY

# 7. POSTROUTING Masquerade for DNS (UDP 53) and general traffic
sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

# 8. Restart Redsocks
sudo systemctl restart redsocks

# 9. Save rules persistently
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null

echo "=== Server Routing & Forwarding Fix Applied Successfully! ==="
