import crypto from 'crypto';
import { MemoryDatabase } from '../db/memory-db.js';
import { ServerNodeService } from './server-node.service.js';
import { ShieldService } from '../shield/shield.service.js';
import { config } from '../config.js';
import {
  ConnectVpnRequestDto,
  ConnectVpnResponseDto,
  DisconnectVpnRequestDto,
  WireGuardFullConfig,
  VpnSession,
  ArgusShieldSettings
} from '@argus/shared-types';

export class VpnOrchestratorService {
  constructor(
    private db: MemoryDatabase,
    private serverNodeService: ServerNodeService,
    private shieldService: ShieldService
  ) {}

  public async connect(userId: string, dto: ConnectVpnRequestDto): Promise<ConnectVpnResponseDto> {
    const user = this.db.findUserById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // 1. Select optimal server node
    const server = this.serverNodeService.selectOptimalServer(
      dto.preferredServerId,
      dto.preferredCountryCode,
      user.tier
    );

    // 2. Resolve DNS based on Argus Shield settings (user profile or request override)
    const effectiveShieldSettings: ArgusShieldSettings = dto.shieldSettings || user.shieldSettings;
    const dnsServers = this.shieldService.resolveDnsServers(effectiveShieldSettings);

    // 3. Register peer with the target Server Node Daemon
    const { assignedIp, serverPublicKey } = await this.registerPeerOnNode(server, dto.clientPublicKey);

    // 4. Create VPN Session record
    const sessionId = crypto.randomUUID();
    const session: VpnSession = {
      sessionId,
      userId,
      serverId: server.id,
      clientVirtualIp: assignedIp,
      clientPublicKey: dto.clientPublicKey,
      connectedAt: new Date(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours session
    };
    this.db.createSession(session);

    // 5. Construct full WireGuard client profile
    const wgConfig: WireGuardFullConfig = {
      interface: {
        address: [`${assignedIp}/32`],
        dns: dnsServers,
        mtu: 1420
      },
      peer: {
        publicKey: serverPublicKey || server.publicKey,
        endpoint: `${server.publicIp}:${server.wireguardPort}`,
        allowedIps: ['0.0.0.0/0', '::/0'],
        persistentKeepalive: 25
      }
    };

    return {
      sessionId,
      server,
      config: wgConfig,
      assignedVirtualIp: assignedIp,
      shieldSettings: effectiveShieldSettings
    };
  }

  public async disconnect(userId: string, dto: DisconnectVpnRequestDto): Promise<{ success: boolean }> {
    const session = this.db.getSessionById(dto.sessionId);
    if (!session || session.userId !== userId) {
      return { success: false };
    }

    const server = this.db.getServerById(session.serverId);
    if (server) {
      await this.removePeerFromNode(server.publicIp, session.clientPublicKey);
    }

    this.db.removeSession(dto.sessionId);
    return { success: true };
  }

  private async registerPeerOnNode(server: ServerNode, clientPublicKey: string): Promise<{ assignedIp: string; serverPublicKey: string }> {
    const daemonUrl = `http://${server.publicIp === '127.0.0.1' ? '127.0.0.1:4001' : `${server.publicIp}:4001`}/api/peers`;
    try {
      const response = await fetch(daemonUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-argus-node-secret': config.daemonSecretToken
        },
        body: JSON.stringify({ clientPublicKey }),
        signal: AbortSignal.timeout(2500)
      });

      if (response.ok) {
        const data = await response.json() as any;
        return {
          assignedIp: data.assignedIp,
          serverPublicKey: data.serverPublicKey || server.publicKey
        };
      }
    } catch {
      // Fallback in local development if node daemon is on another port or mock
    }

    // Fallback simulation IP
    const randomHost = Math.floor(Math.random() * 200) + 2;
    return {
      assignedIp: `10.8.0.${randomHost}`,
      serverPublicKey: server.publicKey
    };
  }

  private async removePeerFromNode(nodeIp: string, clientPublicKey: string): Promise<void> {
    const daemonUrl = `http://${nodeIp === '127.0.0.1' ? '127.0.0.1:4001' : `${nodeIp}:4001`}/api/peers/${encodeURIComponent(clientPublicKey)}`;
    try {
      await fetch(daemonUrl, {
        method: 'DELETE',
        headers: {
          'x-argus-node-secret': config.daemonSecretToken
        },
        signal: AbortSignal.timeout(2000)
      });
    } catch {
      // Best effort cleanup
    }
  }

  public getAllServers() {
    return this.serverNodeService.getAvailableServers('PRO');
  }
}
