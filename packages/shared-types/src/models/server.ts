export enum ServerStatus {
  ONLINE = 'ONLINE',
  DEGRADED = 'DEGRADED',
  OFFLINE = 'OFFLINE',
  MAINTENANCE = 'MAINTENANCE'
}

export interface ServerLocation {
  city: string;
  country: string;
  countryCode: string; // ISO 3166-1 alpha-2 (e.g., 'US', 'DE', 'SG')
  latitude?: number;
  longitude?: number;
}

export interface ServerNode {
  id: string;
  hostname: string;
  location: ServerLocation;
  publicIp: string;
  wireguardPort: number;
  publicKey: string; // WireGuard Server Public Key
  allowedIps: string[]; // e.g. ["0.0.0.0/0", "::/0"]
  dnsServers: string[]; // e.g. ["1.1.1.1", "1.0.0.1"]
  status: ServerStatus;
  currentLoadPercentage: number; // 0 - 100
  activePeersCount: number;
  maxCapacity: number;
  tierRequired: 'FREE' | 'PRO' | 'ENTERPRISE';
  lastHeartbeat: Date | string;
}
