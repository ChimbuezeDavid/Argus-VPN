import mongoose, { Schema, Document } from 'mongoose';
import { ServerNode, ServerStatus, VpnSession, ArgusShieldSettings } from '@argus/shared-types';
import { UserRecord } from './memory-db.js';

// User Mongoose Document
export interface IUserDocument extends Document {
  id: string;
  email: string;
  passwordHash: string;
  tier: 'FREE' | 'PRO';
  activeDevicesCount: number;
  maxAllowedDevices: number;
  shieldSettings: ArgusShieldSettings;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUserDocument>(
  {
    id: { type: String, required: true, unique: true, index: true },
    email: { type: String, required: true, unique: true, index: true, lowercase: true },
    passwordHash: { type: String, required: true },
    tier: { type: String, enum: ['FREE', 'PRO'], default: 'FREE' },
    activeDevicesCount: { type: Number, default: 0 },
    maxAllowedDevices: { type: Number, default: 5 },
    shieldSettings: {
      blockAdultContent: { type: Boolean, default: false },
      blockGambling: { type: Boolean, default: false },
      blockSocialMedia: { type: Boolean, default: false },
      blockAdsAndTrackers: { type: Boolean, default: true },
      blockMalware: { type: Boolean, default: true },
      autoSecureUntrustedWifi: { type: Boolean, default: true },
      trustedWifiNetworks: { type: [String], default: [] },
      bypassedApplications: { type: [String], default: [] },
    },
  },
  { timestamps: true }
);

// Server Node Mongoose Document
export interface IServerNodeDocument extends Document, Omit<ServerNode, 'id'> {
  id: string;
}

const ServerNodeSchema = new Schema<IServerNodeDocument>(
  {
    id: { type: String, required: true, unique: true, index: true },
    hostname: { type: String, required: true },
    location: {
      city: { type: String, required: true },
      country: { type: String, required: true },
      countryCode: { type: String, required: true },
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },
    publicIp: { type: String, required: true },
    wireguardPort: { type: Number, default: 51820 },
    publicKey: { type: String, required: true },
    allowedIps: { type: [String], default: ['0.0.0.0/0', '::/0'] },
    dnsServers: { type: [String], default: ['1.1.1.1', '1.0.0.1'] },
    status: { type: String, enum: Object.values(ServerStatus), default: ServerStatus.ONLINE },
    currentLoadPercentage: { type: Number, default: 0 },
    activePeersCount: { type: Number, default: 0 },
    maxCapacity: { type: Number, default: 500 },
    tierRequired: { type: String, enum: ['FREE', 'PRO'], default: 'FREE' },
    lastHeartbeat: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

// Session Mongoose Document
export interface ISessionDocument extends Document, Omit<VpnSession, 'sessionId'> {
  sessionId: string;
}

const SessionSchema = new Schema<ISessionDocument>(
  {
    sessionId: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    serverId: { type: String, required: true },
    clientVirtualIp: { type: String, required: true },
    clientPublicKey: { type: String, required: true },
    connectedAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true }
);

export const UserModel = mongoose.models.User || mongoose.model<IUserDocument>('User', UserSchema);
export const ServerNodeModel = mongoose.models.ServerNode || mongoose.model<IServerNodeDocument>('ServerNode', ServerNodeSchema);
export const SessionModel = mongoose.models.Session || mongoose.model<ISessionDocument>('Session', SessionSchema);

import { IArgusDatabase } from './database.interface.js';

export class MongoDatabase implements IArgusDatabase {
  private isConnected = false;

  public async connect(uri: string): Promise<boolean> {
    try {
      if (mongoose.connection.readyState === 1) {
        this.isConnected = true;
        return true;
      }
      await mongoose.connect(uri, {
        serverSelectionTimeoutMS: 5000,
      });
      this.isConnected = true;
      console.log('🍃 [Argus Database] MongoDB Connected Successfully!');
      await this.seedDefaultServers();
      return true;
    } catch (err) {
      console.warn('⚠️ [Argus Database] Could not connect to MongoDB, running memory fallback:', (err as Error).message);
      this.isConnected = false;
      return false;
    }
  }

  public get connected(): boolean {
    return this.isConnected;
  }

  private async seedDefaultServers() {
    const count = await ServerNodeModel.countDocuments();
    if (count === 0) {
      const defaultServers: Partial<ServerNode>[] = [
        {
          id: 'node-de-frankfurt-1',
          hostname: 'de-fra-1.argusvpn.com',
          location: {
            city: 'Frankfurt',
            country: 'Germany',
            countryCode: 'DE',
            latitude: 50.1109,
            longitude: 8.6821,
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
          lastHeartbeat: new Date(),
        },
        {
          id: 'node-us-newyork-1',
          hostname: 'us-nyc-1.argusvpn.com',
          location: {
            city: 'New York',
            country: 'United States',
            countryCode: 'US',
            latitude: 40.7128,
            longitude: -74.0060,
          },
          publicIp: '38.154.185.97',
          wireguardPort: 51820,
          publicKey: 'xK50wOWhZwUzbmExxv8bN+tmpr62itAKtgDh7e/z1GU=',
          allowedIps: ['0.0.0.0/0', '::/0'],
          dnsServers: ['1.1.1.1', '1.0.0.1'],
          status: ServerStatus.ONLINE,
          currentLoadPercentage: 18,
          activePeersCount: 0,
          maxCapacity: 500,
          tierRequired: 'FREE',
          lastHeartbeat: new Date(),
        },
        {
          id: 'node-us-losangeles-1',
          hostname: 'us-lax-1.argusvpn.com',
          location: {
            city: 'Los Angeles',
            country: 'United States',
            countryCode: 'US',
            latitude: 34.0522,
            longitude: -118.2437,
          },
          publicIp: '198.23.243.226',
          wireguardPort: 51820,
          publicKey: 'lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ=',
          allowedIps: ['0.0.0.0/0', '::/0'],
          dnsServers: ['1.1.1.1', '1.0.0.1'],
          status: ServerStatus.ONLINE,
          currentLoadPercentage: 22,
          activePeersCount: 0,
          maxCapacity: 500,
          tierRequired: 'FREE',
          lastHeartbeat: new Date(),
        },
        {
          id: 'node-uk-london-1',
          hostname: 'uk-lon-1.argusvpn.com',
          location: {
            city: 'London',
            country: 'United Kingdom',
            countryCode: 'GB',
            latitude: 51.5074,
            longitude: -0.1278,
          },
          publicIp: '31.59.20.176',
          wireguardPort: 51820,
          publicKey: 'lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ=',
          allowedIps: ['0.0.0.0/0', '::/0'],
          dnsServers: ['1.1.1.1', '1.0.0.1'],
          status: ServerStatus.ONLINE,
          currentLoadPercentage: 16,
          activePeersCount: 0,
          maxCapacity: 500,
          tierRequired: 'FREE',
          lastHeartbeat: new Date(),
        },
      ];
      await ServerNodeModel.insertMany(defaultServers);
      console.log('🌱 [Argus Database] Default VPN Server fleet seeded into MongoDB');
    }
  }

  // User methods
  public async createUser(user: UserRecord): Promise<UserRecord> {
    const doc = await UserModel.create({
      id: user.id,
      email: user.email.toLowerCase(),
      passwordHash: user.passwordHash,
      tier: user.tier,
      activeDevicesCount: user.activeDevicesCount,
      maxAllowedDevices: user.maxAllowedDevices,
      shieldSettings: user.shieldSettings,
    });
    return {
      id: doc.id,
      email: doc.email,
      passwordHash: doc.passwordHash,
      tier: doc.tier,
      activeDevicesCount: doc.activeDevicesCount,
      maxAllowedDevices: doc.maxAllowedDevices,
      shieldSettings: doc.shieldSettings,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  public async findUserById(id: string): Promise<UserRecord | undefined> {
    const doc = await UserModel.findOne({ id });
    if (!doc) return undefined;
    return {
      id: doc.id,
      email: doc.email,
      passwordHash: doc.passwordHash,
      tier: doc.tier,
      activeDevicesCount: doc.activeDevicesCount,
      maxAllowedDevices: doc.maxAllowedDevices,
      shieldSettings: doc.shieldSettings,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  public async findUserByEmail(email: string): Promise<UserRecord | undefined> {
    const doc = await UserModel.findOne({ email: email.toLowerCase() });
    if (!doc) return undefined;
    return {
      id: doc.id,
      email: doc.email,
      passwordHash: doc.passwordHash,
      tier: doc.tier,
      activeDevicesCount: doc.activeDevicesCount,
      maxAllowedDevices: doc.maxAllowedDevices,
      shieldSettings: doc.shieldSettings,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  public async updateUserShieldSettings(userId: string, settings: ArgusShieldSettings): Promise<ArgusShieldSettings | undefined> {
    const doc = await UserModel.findOneAndUpdate(
      { id: userId },
      { $set: { shieldSettings: settings, updatedAt: new Date() } },
      { new: true }
    );
    return doc?.shieldSettings;
  }

  // Server methods
  public async getAllServers(): Promise<ServerNode[]> {
    const docs = await ServerNodeModel.find();
    return docs.map((d: any) => ({
      id: d.id,
      hostname: d.hostname,
      location: d.location,
      publicIp: d.publicIp,
      wireguardPort: d.wireguardPort,
      publicKey: d.publicKey,
      allowedIps: d.allowedIps,
      dnsServers: d.dnsServers,
      status: d.status,
      currentLoadPercentage: d.currentLoadPercentage,
      activePeersCount: d.activePeersCount,
      maxCapacity: d.maxCapacity,
      tierRequired: d.tierRequired,
      lastHeartbeat: d.lastHeartbeat,
    }));
  }

  public async getServerById(id: string): Promise<ServerNode | undefined> {
    const doc = await ServerNodeModel.findOne({ id });
    if (!doc) return undefined;
    return {
      id: doc.id,
      hostname: doc.hostname,
      location: doc.location,
      publicIp: doc.publicIp,
      wireguardPort: doc.wireguardPort,
      publicKey: doc.publicKey,
      allowedIps: doc.allowedIps,
      dnsServers: doc.dnsServers,
      status: doc.status,
      currentLoadPercentage: doc.currentLoadPercentage,
      activePeersCount: doc.activePeersCount,
      maxCapacity: doc.maxCapacity,
      tierRequired: doc.tierRequired,
      lastHeartbeat: doc.lastHeartbeat,
    };
  }

  public async upsertServer(server: ServerNode): Promise<ServerNode> {
    await ServerNodeModel.findOneAndUpdate(
      { id: server.id },
      { $set: server },
      { upsert: true, new: true }
    );
    return server;
  }

  // Session methods
  public async createSession(session: VpnSession): Promise<VpnSession> {
    await SessionModel.create({
      sessionId: session.sessionId,
      userId: session.userId,
      serverId: session.serverId,
      clientVirtualIp: session.clientVirtualIp,
      clientPublicKey: session.clientPublicKey,
      connectedAt: session.connectedAt,
      expiresAt: session.expiresAt,
    });
    return session;
  }

  public async getSessionById(sessionId: string): Promise<VpnSession | undefined> {
    const doc = await SessionModel.findOne({ sessionId });
    if (!doc) return undefined;
    return {
      sessionId: doc.sessionId,
      userId: doc.userId,
      serverId: doc.serverId,
      clientVirtualIp: doc.clientVirtualIp,
      clientPublicKey: doc.clientPublicKey,
      connectedAt: doc.connectedAt,
      expiresAt: doc.expiresAt,
    };
  }

  public async removeSession(sessionId: string): Promise<boolean> {
    const res = await SessionModel.deleteOne({ sessionId });
    return (res.deletedCount ?? 0) > 0;
  }
}
