#!/usr/bin/env bash
set -e

echo "=== Creating systemd service for Argus Node Daemon ==="

sudo tee /etc/systemd/system/argus-daemon.service > /dev/null << 'EOF'
[Unit]
Description=Argus VPN Server Node Daemon
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/ubuntu/Argus-VPN/services/node-daemon
ExecStart=/usr/bin/node /home/ubuntu/Argus-VPN/services/node-daemon/dist/server.js
Restart=always
RestartSec=3
Environment=NODE_ENV=production
Environment=PORT=4001
Environment=DAEMON_SECRET_TOKEN=argus_node_secret_key_123

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable argus-daemon
sudo systemctl restart argus-daemon
sleep 2
sudo systemctl status argus-daemon --no-pager
