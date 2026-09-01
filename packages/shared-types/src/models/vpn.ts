export enum ConnectionState {
  DISCONNECTED = 'DISCONNECTED',
  CONNECTING = 'CONNECTING',
  CONNECTED = 'CONNECTED',
  RECONNECTING = 'RECONNECTING',
  DISCONNECTING = 'DISCONNECTING',
  ERROR = 'ERROR'
}

export interface ArgusShieldSettings {
  blockMalware: boolean;
  blockAdsAndTrackers: boolean;
  blockAdultContent: boolean;
  blockGambling: boolean;
  blockSocialMedia: boolean;
}

export interface WireGuardPeerConfig {
  publicKey: string;
  presharedKey?: string;
  allowedIps: string[];
  endpoint: string; // "hostname_or_ip:port"
  persistentKeepalive?: number; // default: 25
}

export interface WireGuardInterfaceConfig {
  privateKey?: string; // Kept strictly on the client device
  address: string[]; // e.g. ["10.8.0.2/32", "fd86:ea04:1115::2/128"]
  dns: string[]; // e.g. ["1.1.1.1", "1.0.0.1"]
  mtu?: number; // default: 1420
}

export interface WireGuardFullConfig {
  interface: WireGuardInterfaceConfig;
  peer: WireGuardPeerConfig;
}

export interface VpnSession {
  sessionId: string;
  userId: string;
  serverId: string;
  clientVirtualIp: string;
  clientPublicKey: string;
  connectedAt: Date | string;
  expiresAt: Date | string;
}
