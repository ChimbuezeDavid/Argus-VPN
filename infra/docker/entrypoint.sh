#!/bin/bash
set -e

WG_DIR="/etc/wireguard"
mkdir -p "$WG_DIR"

WG_INTERFACE=${WG_INTERFACE:-wg0}
WG_PORT=${WG_PORT:-51820}
WG_SUBNET=${WG_SUBNET:-10.8.0.0/24}
WG_SERVER_IP=${WG_SERVER_IP:-10.8.0.1}

# Generate Server Keys if not present
if [ ! -f "$WG_DIR/private.key" ]; then
    echo "[Entrypoint] Generating WireGuard server private & public keys..."
    wg genkey | tee "$WG_DIR/private.key" | wg pubkey > "$WG_DIR/public.key"
    chmod 600 "$WG_DIR/private.key"
fi

SERVER_PRIVKEY=$(cat "$WG_DIR/private.key")
SERVER_PUBKEY=$(cat "$WG_DIR/public.key")

echo "[Entrypoint] WireGuard Server Public Key: $SERVER_PUBKEY"

# Check if WireGuard kernel / userspace is available
if [ "$WG_MOCK_MODE" != "true" ]; then
    echo "[Entrypoint] Configuring WireGuard interface $WG_INTERFACE..."
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1 || true
    sysctl -w net.ipv6.conf.all.forwarding=1 || true

    # Create wg0 configuration file
    cat <<EOF > "$WG_DIR/$WG_INTERFACE.conf"
[Interface]
Address = $WG_SERVER_IP/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVKEY
SaveConfig = false

# NAT Masquerading & Packet Forwarding
PostUp = iptables -A FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

    # Bring up WireGuard interface
    if wg-quick up "$WG_INTERFACE" 2>/dev/null; then
        echo "[Entrypoint] WireGuard interface $WG_INTERFACE started successfully!"
    else
        echo "[Entrypoint] Kernel WireGuard not available. Falling back to userspace or mock mode."
    fi
fi

echo "[Entrypoint] Starting Argus Node Daemon..."
cd /app/services/node-daemon
exec node dist/server.js
