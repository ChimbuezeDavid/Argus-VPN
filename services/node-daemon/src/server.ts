import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './config.js';
import { WireGuardService } from './wireguard/wireguard.service.js';
import { peerRoutes } from './routes/peer.routes.js';
import { metricsRoutes } from './routes/metrics.routes.js';

export async function createServer() {
  const fastify = Fastify({
    logger: {
      level: process.env.NODE_ENV === 'test' ? 'silent' : 'info'
    }
  });

  await fastify.register(cors, {
    origin: true
  });

  const wgService = new WireGuardService();

  // Authentication hook for daemon management API
  fastify.addHook('preHandler', async (request, reply) => {
    // Exclude public health/info check from auth requirement
    if (request.url === '/api/info') {
      return;
    }

    const authHeader = request.headers['x-argus-node-secret'] || request.headers.authorization;
    const token = typeof authHeader === 'string' && authHeader.startsWith('Bearer ')
      ? authHeader.slice(7)
      : authHeader;

    if (token !== config.secretToken) {
      return reply.status(401).send({ error: 'Unauthorized: Invalid daemon secret token' });
    }
  });

  // Register routes
  await fastify.register(peerRoutes(wgService));
  await fastify.register(metricsRoutes(wgService));

  return fastify;
}

export async function start() {
  try {
    const server = await createServer();
    await server.listen({ port: config.port, host: config.host });
    console.log(`[Argus Node Daemon] Running on http://${config.host}:${config.port} (Node ID: ${config.nodeId})`);
    return server;
  } catch (err) {
    console.error('[Argus Node Daemon] Startup failure:', err);
    process.exit(1);
  }
}

// Only start immediately if this file is the direct entrypoint
if (process.argv[1] && process.argv[1].endsWith('server.js')) {
  start();
}
