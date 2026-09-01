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
        currentLoadPercentage: 14,
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
        publicIp: '104.207.157.40',
        wireguardPort: 51820,
        publicKey: '7rP7olxgT/I3gd0QD0CeTuToUeD1oVKxOCyTryKpkBE=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 18,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-gb-london-1',
        hostname: 'gb-lon-1.argusvpn.com',
        location: {
          city: 'London',
          country: 'United Kingdom',
          countryCode: 'GB',
          latitude: 51.5074,
          longitude: -0.1278
        },
        publicIp: '95.179.237.53',
        wireguardPort: 51820,
        publicKey: '/cBFdtwRHjz56m38Kh0QsgIeVGtlKJD1W3A43UVCnXs=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 15,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-jp-tokyo-1',
        hostname: 'jp-tyo-1.argusvpn.com',
        location: {
          city: 'Tokyo',
          country: 'Japan',
          countryCode: 'JP',
          latitude: 35.6762,
          longitude: 139.6503
        },
        publicIp: '202.182.99.236',
        wireguardPort: 51820,
        publicKey: 'QBpooU7ib72cJeMEWtrlr29P7ahh6H658xoFM3/XQQQ=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 20,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'PRO',
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
        publicIp: '45.77.40.191',
        wireguardPort: 51820,
        publicKey: 'M/IfG8NKoDBQLEjkX+vFBJZtdMjx89rFn6Wh36vjY3I=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 16,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'PRO',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-ca-toronto-1',
        hostname: 'ca-tor-1.argusvpn.com',
        location: {
          city: 'Toronto',
          country: 'Canada',
          countryCode: 'CA',
          latitude: 43.6532,
          longitude: -79.3832
        },
        publicIp: '155.138.146.27',
        wireguardPort: 51820,
        publicKey: 's75vnbjZOqSY7aA++nQ/ChGQQP0m/WF33ZyueBgnWxs=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 14,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-fr-paris-1',
        hostname: 'fr-par-1.argusvpn.com',
        location: {
          city: 'Paris',
          country: 'France',
          countryCode: 'FR',
          latitude: 48.8566,
          longitude: 2.3522
        },
        publicIp: '95.179.209.115',
        wireguardPort: 51820,
        publicKey: 'f1KCU2i2AKZuXvqfnNg7S0nHqQALuLIsXBvkRB1eRWs=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 19,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-nl-amsterdam-1',
        hostname: 'nl-ams-1.argusvpn.com',
        location: {
          city: 'Amsterdam',
          country: 'Netherlands',
          countryCode: 'NL',
          latitude: 52.3676,
          longitude: 4.9041
        },
        publicIp: '95.179.187.203',
        wireguardPort: 51820,
        publicKey: 'cISZpVm+EGkMRbAyGyHqyhO57rMA/St/Zt6R3iGvE3Q=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 17,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'FREE',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-au-sydney-1',
        hostname: 'au-syd-1.argusvpn.com',
        location: {
          city: 'Sydney',
          country: 'Australia',
          countryCode: 'AU',
          latitude: -33.8688,
          longitude: 151.2093
        },
        publicIp: '45.76.125.99',
        wireguardPort: 51820,
        publicKey: 's0rt6OSOf4FcEjMGsKwryT7Bu7OcQCG0+rAWBP5NC2Y=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 13,
        activePeersCount: 0,
        maxCapacity: 500,
      {
        id: 'node-kr-seoul-1',
        hostname: 'kr-sel-1.argusvpn.com',
        location: {
          city: 'Seoul',
          country: 'South Korea',
          countryCode: 'KR',
          latitude: 37.5665,
          longitude: 126.9780
        },
        publicIp: '158.247.237.34',
        wireguardPort: 51820,
        publicKey: '6OnTu1E3f8LCw3UQwEAammb0PbDeF9bb2FqFFPaI3zA=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 22,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'PRO',
        lastHeartbeat: new Date()
      },
      {
        id: 'node-in-mumbai-1',
        hostname: 'in-bom-1.argusvpn.com',
        location: {
          city: 'Mumbai',
          country: 'India',
          countryCode: 'IN',
          latitude: 19.0760,
          longitude: 72.8777
        },
        publicIp: '65.20.69.107',
        wireguardPort: 51820,
        publicKey: 'oDunRwA6oR8SboucdrvsUOqw+yd3Rf7Zn2ae2gtW5nE=',
        allowedIps: ['0.0.0.0/0', '::/0'],
        dnsServers: ['1.1.1.1', '1.0.0.1'],
        status: ServerStatus.ONLINE,
        currentLoadPercentage: 26,
        activePeersCount: 0,
        maxCapacity: 500,
        tierRequired: 'FREE',
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
