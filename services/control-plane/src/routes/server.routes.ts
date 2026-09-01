import { FastifyPluginAsync } from 'fastify';
import { ServerNodeService } from '../services/server-node.service.js';

export const serverRoutes = (serverNodeService: ServerNodeService): FastifyPluginAsync => {
  return async (fastify) => {
    // List all available servers for client
    fastify.get('/api/servers', async (request, reply) => {
      // Optional user tier from JWT auth if present
      let userTier = 'FREE';
      try {
        await request.jwtVerify();
        const payload = request.user as { tier?: string };
        if (payload.tier) userTier = payload.tier;
      } catch {
        // Unauthenticated can still view FREE server list
      }

      const servers = serverNodeService.getAvailableServers(userTier);
      const recommended = serverNodeService.selectOptimalServer(undefined, undefined, userTier);

      return reply.send({
        servers,
        recommendedServerId: recommended ? recommended.id : undefined
      });
    });
  };
};
