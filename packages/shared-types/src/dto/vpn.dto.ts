import { ServerNode } from '../models/server.js';
import { WireGuardFullConfig, ArgusShieldSettings } from '../models/vpn.js';

export interface ConnectVpnRequestDto {
  clientPublicKey: string; // Base64 encoded Curve25519 public key
  preferredServerId?: string; // Optional: User-selected server, or auto-selected
  preferredCountryCode?: string; // Optional: 'US', 'DE', etc.
  shieldSettings?: ArgusShieldSettings;
}

export interface ConnectVpnResponseDto {
  sessionId: string;
  server: ServerNode;
  config: WireGuardFullConfig;
  assignedVirtualIp: string;
  shieldSettings?: ArgusShieldSettings;
}

export interface DisconnectVpnRequestDto {
  sessionId: string;
  bytesReceived?: number;
  bytesSent?: number;
}

export interface ServerListResponseDto {
  servers: ServerNode[];
  recommendedServerId?: string;
}
