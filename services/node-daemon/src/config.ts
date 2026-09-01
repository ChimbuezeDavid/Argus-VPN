import dotenv from 'dotenv';
dotenv.config();

export const config = {
  nodeId: process.env.NODE_ID || 'node-local-1',
  port: parseInt(process.env.PORT || '4001', 10),
  host: process.env.HOST || '0.0.0.0',
  secretToken: process.env.DAEMON_SECRET_TOKEN || 'argus_node_secret_key_123',
  wireguard: {
    interface: process.env.WG_INTERFACE || 'wg0',
    port: parseInt(process.env.WG_PORT || '51820', 10),
    privateKeyPath: process.env.WG_PRIVATE_KEY_PATH || '/etc/wireguard/private.key',
    publicKeyPath: process.env.WG_PUBLIC_KEY_PATH || '/etc/wireguard/public.key',
    subnet: process.env.WG_SUBNET || '10.8.0.0/24',
    serverVirtualIp: process.env.WG_SERVER_IP || '10.8.0.1',
    mockMode: process.env.WG_MOCK_MODE === 'true' || process.platform === 'win32'
  }
};
