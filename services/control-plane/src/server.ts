import Fastify, { FastifyRequest, FastifyReply } from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { config } from './config.js';
import { MemoryDatabase } from './db/memory-db.js';
import { ShieldService } from './shield/shield.service.js';
import { AuthService } from './services/auth.service.js';
import { ServerNodeService } from './services/server-node.service.js';
import { VpnOrchestratorService } from './services/vpn-orchestrator.service.js';
import { authRoutes } from './routes/auth.routes.js';
import { serverRoutes } from './routes/server.routes.js';
import { vpnRoutes } from './routes/vpn.routes.js';
import { shieldRoutes } from './routes/shield.routes.js';

// Extend FastifyInstance with authenticate decorator
declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

export async function createServer() {
  const fastify = Fastify({
    logger: {
      level: process.env.NODE_ENV === 'test' ? 'silent' : 'info'
    }
  });

  await fastify.register(cors, {
    origin: true
  });

  await fastify.register(jwt, {
    secret: config.jwtSecret
  });

  // Decorate fastify with JWT authentication helper
  fastify.decorate('authenticate', async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized: Invalid or expired token' });
    }
  });

  // Instantiate services
  const db = new MemoryDatabase();
  const shieldService = new ShieldService();
  const authService = new AuthService(db, shieldService);
  const serverNodeService = new ServerNodeService(db);
  const vpnOrchestratorService = new VpnOrchestratorService(db, serverNodeService, shieldService);

  // Health check
  fastify.get('/health', async () => {
    return { status: 'OK', service: 'Argus Control Plane', timestamp: Date.now() };
  });

  // Register route groups
  await fastify.register(authRoutes(authService));
  await fastify.register(serverRoutes(serverNodeService));
  await fastify.register(vpnRoutes(vpnOrchestratorService));
  await fastify.register(shieldRoutes(db, shieldService));

  return fastify;
}

export async function start() {
  try {
    const server = await createServer();
    await server.listen({ port: config.port, host: config.host });
    console.log(`[Argus Control Plane] Running on http://${config.host}:${config.port}`);
    return server;
  } catch (err) {
    console.error('[Argus Control Plane] Startup failure:', err);
    process.exit(1);
  }
}

if (process.argv[1] && process.argv[1].endsWith('server.js')) {
  start();
}
