import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import os from 'os';
import crypto from 'crypto';
import { config } from '../config.js';
import { IpPool } from './ip-pool.js';
import { NodeMetrics } from '@argus/shared-types';

const execAsync = promisify(exec);

export interface PeerDetails {
  publicKey: string;
  assignedIp: string;
  endpoint?: string;
  latestHandshake?: number;
  transferRxBytes: number;
  transferTxBytes: number;
  addedAt: Date;
}

export class WireGuardService {
  private ipPool: IpPool;
  private serverPublicKey: string = '';
  private mockPeers: Map<string, PeerDetails> = new Map();

  constructor() {
    this.ipPool = new IpPool(config.wireguard.subnet);
    this.initServerKey();
  }

  private initServerKey() {
    if (config.wireguard.mockMode) {
      // Deterministic or generated key for mock mode
      this.serverPublicKey = 'ArgusServerMockPublicKey' + crypto.randomBytes(8).toString('base64');
      console.log(`[WireGuard] Running in MOCK mode. Server Public Key: ${this.serverPublicKey}`);
      return;
    }

    try {
      if (fs.existsSync(config.wireguard.publicKeyPath)) {
        this.serverPublicKey = fs.readFileSync(config.wireguard.publicKeyPath, 'utf8').trim();
      } else {
        console.warn(`[WireGuard] Public key file not found at ${config.wireguard.publicKeyPath}. Generating placeholder.`);
        this.serverPublicKey = 'ArgusServerNodeLiveKey' + crypto.randomBytes(8).toString('base64');
      }
    } catch (err) {
      console.error('[WireGuard] Error reading public key:', err);
      this.serverPublicKey = 'ArgusServerNodeFallbackKey' + crypto.randomBytes(8).toString('base64');
    }
  }

  public getServerPublicKey(): string {
    return this.serverPublicKey;
  }

  public async addPeer(publicKey: string, requestedIp?: string, presharedKey?: string): Promise<{ assignedIp: string }> {
    const assignedIp = requestedIp || this.ipPool.allocate(publicKey);

    if (config.wireguard.mockMode) {
      this.mockPeers.set(publicKey, {
        publicKey,
        assignedIp,
        transferRxBytes: 1024 * 10,
        transferTxBytes: 1024 * 50,
        latestHandshake: Math.floor(Date.now() / 1000),
        addedAt: new Date()
      });
      console.log(`[WireGuard Mock] Added peer ${publicKey.slice(0, 8)}... with IP ${assignedIp}`);
      return { assignedIp };
    }

    // Live WireGuard execution (Linux / Docker)
    // wg set <interface> peer <public_key> allowed-ips <ip>/32
    let cmd = `wg set ${config.wireguard.interface} peer ${publicKey} allowed-ips ${assignedIp}/32`;
    if (presharedKey) {
      cmd += ` preshared-key <(echo "${presharedKey}")`;
    }

    try {
      await execAsync(cmd, { shell: '/bin/bash' });
      console.log(`[WireGuard Live] Successfully added peer ${publicKey.slice(0, 8)}... with IP ${assignedIp}`);
      return { assignedIp };
    } catch (error: any) {
      console.error(`[WireGuard Live] Failed to add peer:`, error.message);
      throw new Error(`Failed to add WireGuard peer: ${error.message}`);
    }
  }

  public async removePeer(publicKey: string): Promise<boolean> {
    this.ipPool.release(publicKey);

    if (config.wireguard.mockMode) {
      const removed = this.mockPeers.delete(publicKey);
      console.log(`[WireGuard Mock] Removed peer ${publicKey.slice(0, 8)}...`);
      return removed;
    }

    // Live WireGuard execution
    const cmd = `wg set ${config.wireguard.interface} peer ${publicKey} remove`;
    try {
      await execAsync(cmd);
      console.log(`[WireGuard Live] Successfully removed peer ${publicKey.slice(0, 8)}...`);
      return true;
    } catch (error: any) {
      console.error(`[WireGuard Live] Failed to remove peer:`, error.message);
      return false;
    }
  }

  public async listPeers(): Promise<PeerDetails[]> {
    if (config.wireguard.mockMode) {
      return Array.from(this.mockPeers.values());
    }

    try {
      const { stdout } = await execAsync(`wg show ${config.wireguard.interface} dump`);
      const lines = stdout.trim().split('\n');
      const peers: PeerDetails[] = [];

      for (let i = 1; i < lines.length; i++) {
        const parts = lines[i].split('\t');
        if (parts.length >= 8) {
          const [pubKey, , endpoint, allowedIps, latestHandshake, rxBytes, txBytes] = parts;
          peers.push({
            publicKey: pubKey,
            assignedIp: allowedIps,
            endpoint: endpoint !== '(none)' ? endpoint : undefined,
            latestHandshake: latestHandshake !== '0' ? parseInt(latestHandshake, 10) : undefined,
            transferRxBytes: parseInt(rxBytes, 10),
            transferTxBytes: parseInt(txBytes, 10),
            addedAt: new Date()
          });
        }
      }
      return peers;
    } catch (err: any) {
      console.warn(`[WireGuard Live] Failed to dump peers:`, err.message);
      return [];
    }
  }

  public async getMetrics(): Promise<NodeMetrics> {
    const peers = await this.listPeers();
    let totalRx = 0;
    let totalTx = 0;

    for (const peer of peers) {
      totalRx += peer.transferRxBytes;
      totalTx += peer.transferTxBytes;
    }

    const freeMem = os.freemem();
    const totalMem = os.totalmem();
    const memoryUsagePercent = Math.round(((totalMem - freeMem) / totalMem) * 100);

    return {
      nodeId: config.nodeId,
      timestamp: Date.now(),
      cpuUsagePercent: Math.min(100, Math.round(os.loadavg()[0] * 10)),
      memoryUsagePercent,
      activePeers: peers.length,
      rxBytesTotal: totalRx,
      txBytesTotal: totalTx,
      rxBytesPerSec: 1024 * (peers.length + 1),
      txBytesPerSec: 1024 * 5 * (peers.length + 1)
    };
  }
}
