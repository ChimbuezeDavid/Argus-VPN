import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { VpnOrchestratorService } from '../services/vpn-orchestrator.service.js';

const shieldSchema = z.object({
  blockMalware: z.boolean(),
  blockAdsAndTrackers: z.boolean(),
  blockAdultContent: z.boolean(),
  blockGambling: z.boolean(),
  blockSocialMedia: z.boolean()
}).optional();

const connectVpnSchema = z.object({
  clientPublicKey: z.string().min(10, 'Valid WireGuard public key is required'),
  preferredServerId: z.string().optional(),
  preferredCountryCode: z.string().optional(),
  shieldSettings: shieldSchema
});

const disconnectVpnSchema = z.object({
  sessionId: z.string().min(1, 'Session ID is required'),
  bytesReceived: z.number().optional(),
  bytesSent: z.number().optional()
});

export const vpnRoutes = (vpnService: VpnOrchestratorService): FastifyPluginAsync => {
  return async (fastify) => {
    // Authenticated endpoint: Request VPN Connection Profile
    fastify.post('/api/vpn/connect', {
      preHandler: [fastify.authenticate]
    }, async (request, reply) => {
      const parseResult = connectVpnSchema.safeParse(request.body);
      if (!parseResult.success) {
        return reply.status(400).send({ error: 'Validation failed', details: parseResult.error.errors });
      }

      const user = request.user as { userId: string };

      try {
        const response = await vpnService.connect(user.userId, parseResult.data);
        return reply.status(200).send(response);
      } catch (err: any) {
        return reply.status(500).send({ error: err.message || 'VPN Connection negotiation failed' });
      }
    });

    // Authenticated endpoint: Disconnect VPN Session
    fastify.post('/api/vpn/disconnect', {
      preHandler: [fastify.authenticate]
    }, async (request, reply) => {
      const parseResult = disconnectVpnSchema.safeParse(request.body);
      if (!parseResult.success) {
        return reply.status(400).send({ error: 'Validation failed', details: parseResult.error.errors });
      }

      const user = request.user as { userId: string };

      const result = await vpnService.disconnect(user.userId, parseResult.data);
      return reply.send(result);
    });

    // List all available VPN Servers
    fastify.get('/api/vpn/servers', async (request, reply) => {
      const servers = vpnService.getAllServers();
      return reply.status(200).send({ servers });
    });

    fastify.get('/api/servers', async (request, reply) => {
      const servers = vpnService.getAllServers();
      return reply.status(200).send({ servers });
    });
  };
};
