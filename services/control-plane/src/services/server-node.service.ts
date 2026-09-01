import { MemoryDatabase } from '../db/memory-db.js';
import { ServerNode, ServerStatus, NodeHeartbeatDto } from '@argus/shared-types';

export class ServerNodeService {
  constructor(private db: MemoryDatabase) {}

  public getAvailableServers(userTier: string = 'FREE'): ServerNode[] {
    const servers = this.db.getAllServers();
    return servers.filter(server => {
      if (server.status === ServerStatus.OFFLINE) return false;
      if (userTier === 'FREE' && server.tierRequired !== 'FREE') return false;
      return true;
    });
  }

  public selectOptimalServer(preferredServerId?: string, preferredCountryCode?: string, userTier: string = 'FREE'): ServerNode {
    const availableServers = this.getAvailableServers(userTier);

    if (availableServers.length === 0) {
      throw new Error('No VPN servers are currently available');
    }

    // 1. If explicit server requested and available
    if (preferredServerId) {
      const server = availableServers.find(s => s.id === preferredServerId);
      if (server) return server;
    }

    // 2. If preferred country requested
    if (preferredCountryCode) {
      const countryServers = availableServers.filter(
        s => s.location.countryCode.toUpperCase() === preferredCountryCode.toUpperCase()
      );
      if (countryServers.length > 0) {
        // Sort by lowest load
        countryServers.sort((a, b) => a.currentLoadPercentage - b.currentLoadPercentage);
        return countryServers[0];
      }
    }

    // 3. Fallback: Server with lowest load percentage
    availableServers.sort((a, b) => a.currentLoadPercentage - b.currentLoadPercentage);
    return availableServers[0];
  }

  public handleNodeHeartbeat(dto: NodeHeartbeatDto): void {
    const existing = this.db.getServerById(dto.nodeId);
    if (existing) {
      existing.lastHeartbeat = new Date();
      existing.currentLoadPercentage = dto.metrics.cpuUsagePercent;
      existing.activePeersCount = dto.metrics.activePeers;
      existing.status = ServerStatus.ONLINE;
      this.db.upsertServer(existing);
    }
  }
}
