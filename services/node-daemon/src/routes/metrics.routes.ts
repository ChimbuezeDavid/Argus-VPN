import { FastifyPluginAsync } from 'fastify';
import { WireGuardService } from '../wireguard/wireguard.service.js';
import { config } from '../config.js';

export const metricsRoutes = (wgService: WireGuardService): FastifyPluginAsync => {
  return async (fastify) => {
    // Health check / info
    fastify.get('/api/info', async () => {
      const peers = await wgService.listPeers();
      return {
        nodeId: config.nodeId,
        version: '1.0.0',
        publicKey: wgService.getServerPublicKey(),
        wireguardPort: config.wireguard.port,
        activePeers: peers.length,
        mockMode: config.wireguard.mockMode,
        status: 'ONLINE'
      };
    });

    // Real-time telemetry metrics
    fastify.get('/api/metrics', async () => {
      const metrics = await wgService.getMetrics();
      return metrics;
    });
  };
};
