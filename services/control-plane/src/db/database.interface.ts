import { ServerNode, VpnSession, ArgusShieldSettings } from '@argus/shared-types';
import { UserRecord } from './memory-db.js';

export interface IArgusDatabase {
  createUser(user: UserRecord): Promise<UserRecord> | UserRecord;
  findUserById(id: string): Promise<UserRecord | undefined> | UserRecord | undefined;
  findUserByEmail(email: string): Promise<UserRecord | undefined> | UserRecord | undefined;
  updateUserShieldSettings(userId: string, settings: ArgusShieldSettings): Promise<ArgusShieldSettings | undefined> | ArgusShieldSettings | undefined;
  getAllServers(): Promise<ServerNode[]> | ServerNode[];
  getServerById(id: string): Promise<ServerNode | undefined> | ServerNode | undefined;
  upsertServer(server: ServerNode): Promise<ServerNode> | ServerNode;
  createSession(session: VpnSession): Promise<VpnSession> | VpnSession;
  getSessionById(sessionId: string): Promise<VpnSession | undefined> | VpnSession | undefined;
  removeSession(sessionId: string): Promise<boolean> | boolean;
}
