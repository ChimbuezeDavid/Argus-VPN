import { User, ServerNode, ServerStatus, VpnSession, ArgusShieldSettings } from '@argus/shared-types';

export interface UserRecord extends User {
  passwordHash: string;
  shieldSettings: ArgusShieldSettings;
}

export class MemoryDatabase {
  private users: Map<string, UserRecord> = new Map(); // userId -> UserRecord
  private usersByEmail: Map<string, string> = new Map(); // email -> userId
  private serverNodes: Map<string, ServerNode> = new Map(); // serverId -> ServerNode
  private sessions: Map<string, VpnSession> = new Map(); // sessionId -> VpnSession

  constructor() {
    this.seedDefaultServers();
  }

  private seedDefaultServers() {
    const defaultServers: ServerNode[] = [
      {
        id: 'node-de-frankfurt-1',
        hostname: 'de-fra-1.argusvpn.com',
        location: {
          city: 'Frankfurt',
          country: 'Germany',
          countryCode: 'DE',
          latitude: 50.1109,
          longitude: 8.6821
        },
        publicIp: '158.180.31.224',
        wireguardPort: 51820,
        publicKey: 'lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 12,
        activePeersCount: 1,
        maxCapacity: 500,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-us-newyork-1',
        hostname: 'us-nyc-1.argusvpn.com',
        location: {
          city: 'New York',
          country: 'United States',
          countryCode: 'US',
          latitude: 40.7128,
          longitude: -74.0060
        },
        publicIp: '127.0.0.1',
        wireguardPort: 51821,
        publicKey: 'ArgusServerNodeMockKeyNewYork1==',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 35,
        activePeersCount: 14,
        maxCapacity: 250,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-sg-singapore-1',
        hostname: 'sg-sin-1.argusvpn.com',
        location: {
          city: 'Singapore',
          country: 'Singapore',
          countryCode: 'SG',
          latitude: 1.3521,
          longitude: 103.8198
        },
        publicIp: '127.0.0.1',
        wireguardPort: 51822,
        publicKey: 'ArgusServerNodeMockKeySingapore1==',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 12,
        activePeersCount: 4,
        maxCapacity: 250,
        tierRequired: 'PRO',
        lastHeartbeat: new Date()
      }
    ];

    for (const server of defaultServers) {
      this.serverNodes.set(server.id, server);
    }
  }

  // User methods
  public createUser(user: UserRecord): UserRecord {
    this.users.set(user.id, user);
    this.usersByEmail.set(user.email.toLowerCase(), user.id);
    return user;
  }

  public findUserById(id: string): UserRecord | undefined {
    return this.users.get(id);
  }

  public findUserByEmail(email: string): UserRecord | undefined {
    const id = this.usersByEmail.get(email.toLowerCase());
    if (!id) return undefined;
    return this.users.get(id);
  }

  public updateUserShieldSettings(userId: string, settings: ArgusShieldSettings): ArgusShieldSettings | undefined {
    const user = this.users.get(userId);
    if (!user) return undefined;
    user.shieldSettings = { ...user.shieldSettings, ...settings };
    user.updatedAt = new Date();
    return user.shieldSettings;
  }

  // Server methods
  public getAllServers(): ServerNode[] {
    return Array.from(this.serverNodes.values());
  }

  public getServerById(id: string): ServerNode | undefined {
    return this.serverNodes.get(id);
  }

  public upsertServer(server: ServerNode): ServerNode {
    this.serverNodes.set(server.id, server);
    return server;
  }

  // Session methods
  public createSession(session: VpnSession): VpnSession {
    this.sessions.set(session.sessionId, session);
    return session;
  }

  public getSessionById(sessionId: string): VpnSession | undefined {
    return this.sessions.get(sessionId);
  }

  public removeSession(sessionId: string): boolean {
    return this.sessions.delete(sessionId);
  }
}
