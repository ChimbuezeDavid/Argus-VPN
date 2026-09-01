import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { WireGuardService } from '../wireguard/wireguard.service.js';

const registerPeerSchema = z.object({
  clientPublicKey: z.string().min(10, 'Invalid WireGuard public key'),
  assignedIp: z.string().optional(),
  presharedKey: z.string().optional()
});

export const peerRoutes = (wgService: WireGuardService): FastifyPluginAsync => {
  return async (fastify) => {
    // Register new client peer
    fastify.post('/api/peers', async (request, reply) => {
      const parseResult = registerPeerSchema.safeParse(request.body);
      if (!parseResult.success) {
        return reply.status(400).send({ error: 'Validation failed', details: parseResult.error.errors });
      }

      const { clientPublicKey, assignedIp: requestedIp, presharedKey } = parseResult.data;

      try {
        const { assignedIp } = await wgService.addPeer(clientPublicKey, requestedIp, presharedKey);
        return reply.status(201).send({
          success: true,
          clientPublicKey,
          assignedIp,
          serverPublicKey: wgService.getServerPublicKey()
        });
      } catch (err: any) {
        return reply.status(500).send({ error: err.message || 'Failed to add peer' });
      }
    });

    // Remove client peer
    fastify.delete('/api/peers/:publicKey', async (request, reply) => {
      const { publicKey } = request.params as { publicKey: string };
      if (!publicKey) {
        return reply.status(400).send({ error: 'Public key is required' });
      }

      const success = await wgService.removePeer(decodeURIComponent(publicKey));
      return reply.send({ success, publicKey });
    });

    // List all active peers on this node
    fastify.get('/api/peers', async (_request, reply) => {
      const peers = await wgService.listPeers();
      return reply.send({ count: peers.length, peers });
    });
  };
};
