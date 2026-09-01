#!/usr/bin/env bash
# ==============================================================================
# Argus VPN - 1-Click Production Node VPS Deployment Script
# Supports: Ubuntu 22.04 LTS / 24.04 LTS / Debian 12
# ==============================================================================

set -euo pipefail

echo "========================================================"
echo "          ARGUS VPN EXIT NODE DEPLOYMENT                "
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root (sudo ./setup-vps.sh)"
  exit 1
fi

# 1. Update and install packages
echo "[+] Updating system packages..."
apt-get update && apt-get install -y \
  wireguard \
  wireguard-tools \
  iptables \
  iptables-persistent \
  curl \
  ufw \
  nodejs \
  npm \
  git

# 2. Enable IP Forwarding
echo "[+] Enabling IPv4 and IPv6 forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf || true

# 3. Generate WireGuard Keys
echo "[+] Generating WireGuard server cryptographic keys..."
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cd /etc/wireguard

if [ ! -f "private.key" ]; then
  wg genkey | tee private.key | wg pubkey > public.key
  chmod 600 private.key
fi

SERVER_PRIVKEY=$(cat private.key)
SERVER_PUBKEY=$(cat public.key)
DEFAULT_INTERFACE=$(ip route show default | awk '{print $5}')
WG_PORT=51820

# 4. Generate wg0.conf
echo "[+] Generating /etc/wireguard/wg0.conf..."
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.8.0.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVKEY
SaveConfig = false

# Masquerade outbound traffic from WireGuard clients
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEFAULT_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEFAULT_INTERFACE -j MASQUERADE
EOF

chmod 600 /etc/wireguard/wg0.conf

# 5. Enable and start WireGuard systemd service
echo "[+] Starting WireGuard service (wg-quick@wg0)..."
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# 6. Configure UFW Firewall
echo "[+] Configuring Firewall rules..."
ufw allow $WG_PORT/udp
ufw allow 22/tcp
ufw --force enable

echo "========================================================"
echo "  ARGUS VPN NODE INSTALLED SUCCESSFULLY!                "
echo "  Public Key: $SERVER_PUBKEY                            "
echo "  Listen Port: $WG_PORT                                 "
echo "========================================================"
