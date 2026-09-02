#!/usr/bin/env bash
set -e

echo "=== Updating Multi-City Routing & Anti-Leak Rules on Oracle Gateway ==="

# 1. Ensure wg0 has IP aliases for subnets 10.8.0.1 through 10.8.9.1
for i in $(seq 0 9); do
    sudo ip addr add 10.8.${i}.1/24 dev wg0 2>/dev/null || true
done

# 2. INPUT Chain: CRITICAL! Allow redirected traffic to reach Redsocks ports
sudo iptables -I INPUT 1 -i wg0 -j ACCEPT 2>/dev/null || true
sudo iptables -I INPUT 1 -p tcp -m multiport --dports 12345:12355 -j ACCEPT 2>/dev/null || true

# 3. Recreate NAT chains for all 9 Webshare proxies
for i in $(seq 1 9); do
    sudo iptables -t nat -N REDSOCKS_${i} 2>/dev/null || true
    sudo iptables -t nat -F REDSOCKS_${i}
    sudo iptables -t nat -A REDSOCKS_${i} -d 0.0.0.0/8 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${i} -d 10.0.0.0/8 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${i} -d 127.0.0.0/8 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${i} -d 169.254.0.0/16 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${i} -d 172.16.0.0/12 -j RETURN
    sudo iptables -t nat -A REDSOCKS_${i} -d 192.168.0.0/16 -j RETURN
    port=$((12344 + i))
    sudo iptables -t nat -A REDSOCKS_${i} -p tcp -j REDIRECT --to-ports ${port}
done

# 4. Clean and populate PREROUTING rules on wg0
sudo iptables -t nat -F PREROUTING

# Map subnets 10.8.1.x through 10.8.9.x to REDSOCKS_1 through REDSOCKS_9
for i in $(seq 1 9); do
    sudo iptables -t nat -A PREROUTING -i wg0 -s 10.8.${i}.0/24 -p tcp -j REDSOCKS_${i}
done

# 5. FORWARD CHAIN & ANTI-LEAK:
# Prevent QUIC (UDP 443/80) from leaking Frankfurt IP
sudo iptables -F FORWARD
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wg0 -p udp --dport 53 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -p udp --dport 443 -j REJECT --reject-with icmp-port-unreachable
sudo iptables -A FORWARD -i wg0 -p udp --dport 80 -j REJECT --reject-with icmp-port-unreachable
sudo iptables -A FORWARD -i wg0 -p udp -j REJECT --reject-with icmp-port-unreachable
# Direct Germany traffic (10.8.0.x) is allowed through ens3 (Oracle Gateway)
sudo iptables -A FORWARD -i wg0 -s 10.8.0.0/24 -o ens3 -j ACCEPT
# Proxy subnets MUST NOT leak directly through ens3:
for i in $(seq 1 9); do
    sudo iptables -A FORWARD -i wg0 -s 10.8.${i}.0/24 -o ens3 -j REJECT --reject-with icmp-host-prohibited
done
sudo iptables -A FORWARD -i ens3 -o wg0 -j ACCEPT

# 6. POSTROUTING Masquerade for outbound traffic
sudo iptables -t nat -F POSTROUTING
sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

# 7. Kernel forwarding & Redsocks
sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null
sudo sysctl -w net.ipv4.conf.all.route_localnet=1 > /dev/null
sudo systemctl restart redsocks

# 8. Persist rules
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null || true

echo "=== Anti-Leak & Proxy Routing Configured Successfully! ==="
