#!/usr/bin/env bash
# ==============================================================================
# Argus VPN - 1-Click Production WireGuard Node Deployment Script
# Supports: Ubuntu 22.04 LTS / 24.04 LTS / Debian 12 / Vultr / DigitalOcean / AWS
# ==============================================================================

set -euo pipefail

echo "========================================================"
echo "          ARGUS VPN EXIT NODE DEPLOYMENT                "
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run as root: sudo bash setup_node.sh"
  exit 1
fi

# 1. Update and install packages
echo "[+] Updating system packages & installing WireGuard..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wireguard wireguard-tools iptables curl ufw nodejs

# 2. Enable IPv4 & IPv6 Forwarding
echo "[+] Enabling IPv4 and IPv6 forwarding..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard-forward.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.d/99-wireguard-forward.conf
sysctl -p /etc/sysctl.d/99-wireguard-forward.conf

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
DEFAULT_INTERFACE=$(ip route show default | awk '{print $5}' | head -n1)
WG_PORT=51820
DAEMON_PORT=4001
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || hostname -I | awk '{print $1}')

# 4. Generate wg0.conf
echo "[+] Configuring /etc/wireguard/wg0.conf (Interface: $DEFAULT_INTERFACE)..."
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.8.0.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVKEY
SaveConfig = false

# NAT Masquerading for outbound internet traffic
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEFAULT_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEFAULT_INTERFACE -j MASQUERADE
EOF

chmod 600 /etc/wireguard/wg0.conf

# 5. Enable and start WireGuard systemd service
echo "[+] Starting WireGuard service (wg-quick@wg0)..."
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# 6. Deploy Argus Node Registration Microservice (Port 4001)
echo "[+] Setting up Argus Peer Registration Microservice..."
mkdir -p /opt/argus-node
cat << 'EOF' > /opt/argus-node/index.js
const http = require('http');
const { execSync } = require('child_process');
const fs = require('fs');

const PORT = process.env.PORT || 4001;
let currentIpIndex = 2;

function getServerPublicKey() {
  try {
    return fs.readFileSync('/etc/wireguard/public.key', 'utf8').trim();
  } catch (e) {
    return '';
  }
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/api/info' || req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'online',
      node: 'argus-node',
      port: PORT,
      serverPublicKey: getServerPublicKey()
    }));
    return;
  }

  if (req.method === 'POST' && (req.url === '/api/peers' || req.url === '/register')) {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body || '{}');
        const clientPublicKey = data.clientPublicKey || data.publicKey;

        if (!clientPublicKey) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'clientPublicKey required' }));
          return;
        }

        // Allocate IP (10.8.0.2 to 10.8.0.254)
        currentIpIndex = (currentIpIndex % 250) + 1;
        if (currentIpIndex < 2) currentIpIndex = 2;
        const assignedIp = `10.8.0.${currentIpIndex}`;

        // Register peer with WireGuard in kernel
        try {
          execSync(`wg set wg0 peer "${clientPublicKey}" allowed-ips ${assignedIp}/32`, { stdio: 'pipe' });
          console.log(`[Argus Node] Registered peer ${clientPublicKey} -> ${assignedIp}`);
        } catch (err) {
          console.error(`[Argus Node] wg set error:`, err.message);
        }

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          clientPublicKey,
          assignedIp,
          serverPublicKey: getServerPublicKey()
        }));
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not Found' }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[Argus Node Daemon] Listening on 0.0.0.0:${PORT}`);
});
EOF

# 7. Create Systemd Service for Argus Node Daemon
cat <<EOF > /etc/systemd/system/argus-node.service
[Unit]
Description=Argus VPN Node Peer Registration Daemon
After=network.target wg-quick@wg0.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/argus-node
ExecStart=/usr/bin/node /opt/argus-node/index.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable argus-node.service
systemctl restart argus-node.service

# 8. Configure UFW Firewall
echo "[+] Configuring Firewall rules..."
ufw allow 22/tcp || true
ufw allow $WG_PORT/udp || true
ufw allow $DAEMON_PORT/tcp || true
ufw --force enable || true

echo ""
echo "========================================================"
echo "  🎉 ARGUS VPN NODE INSTALLED & ACTIVE!                 "
echo "========================================================"
echo "  Public IP:          $PUBLIC_IP"
echo "  WireGuard Port:     $WG_PORT (UDP)"
echo "  Peer API Port:      $DAEMON_PORT (TCP)"
echo "  Server Public Key:  $SERVER_PUBKEY"
echo "========================================================"
echo ""
