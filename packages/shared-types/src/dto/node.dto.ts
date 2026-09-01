import { NodeMetrics } from '../models/telemetry.js';

export interface RegisterPeerOnNodeDto {
  clientPublicKey: string;
  assignedIp: string; // e.g. "10.8.0.5/32"
  presharedKey?: string;
}

export interface RemovePeerFromNodeDto {
  clientPublicKey: string;
}

export interface NodeHeartbeatDto {
  nodeId: string;
  secretToken: string;
  metrics: NodeMetrics;
}

export interface NodeInfoResponseDto {
  nodeId: string;
  publicKey: string;
  listenPort: number;
  activePeers: number;
  version: string;
}
