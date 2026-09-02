#!/usr/bin/env bash
set -e

echo "=== Updating Multi-City Routing & Anti-Leak Rules on Oracle Gateway ==="

# 1. Flush and recreate all city chains
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

# 2. Clean previous PREROUTING rules on wg0
sudo iptables -t nat -F PREROUTING

# 3. WireGuard Client Subnet Redirections:
# Subnet 10.8.1.x -> US New York (38.154.185.97)
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.1.0/24 -p tcp -j REDSOCKS_NY
# Subnet 10.8.2.x -> US Los Angeles (198.23.243.226)
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.2.0/24 -p tcp -j REDSOCKS_LA
# Subnet 10.8.3.x -> UK London (31.59.20.176)
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.3.0/24 -p tcp -j REDSOCKS_UK
# Subnet 10.8.4.x -> Spain Madrid (64.137.96.74)
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.4.0/24 -p tcp -j REDSOCKS_ES
# Subnet 10.8.5.x -> Japan Tokyo (142.111.67.146)
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.5.0/24 -p tcp -j REDSOCKS_JP
# Default (10.8.0.x) -> US New York (38.154.185.97)
sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.0.0/24 -p tcp -j REDSOCKS_NY

# 4. ANTI-LEAK: Prevent QUIC / HTTP3 (UDP 443/80) from bypassing proxy and leaking Germany
sudo iptables -F FORWARD
sudo iptables -A FORWARD -i wg0 -p udp --dport 53 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -p udp --dport 443 -j REJECT --reject-with icmp-port-unreachable
sudo iptables -A FORWARD -i wg0 -p udp --dport 80 -j REJECT --reject-with icmp-port-unreachable
sudo iptables -A FORWARD -i wg0 -p udp -j REJECT --reject-with icmp-port-unreachable
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# 5. POSTROUTING Masquerade for DNS
sudo iptables -t nat -F POSTROUTING
sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

# 6. Ensure IP forwarding and Redsocks running
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
sudo systemctl restart redsocks

# Save rules
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null

echo "=== Anti-Leak & Proxy Routing Configured Successfully! ==="
