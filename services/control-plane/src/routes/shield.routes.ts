import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { MemoryDatabase } from '../db/memory-db.js';
import { ShieldService } from '../shield/shield.service.js';

const updateShieldSchema = z.object({
  blockMalware: z.boolean().optional(),
  blockAdsAndTrackers: z.boolean().optional(),
  blockAdultContent: z.boolean().optional(),
  blockGambling: z.boolean().optional(),
  blockSocialMedia: z.boolean().optional()
});

export const shieldRoutes = (db: MemoryDatabase, shieldService: ShieldService): FastifyPluginAsync => {
  return async (fastify) => {
    // Get user's current Argus Shield content filtering settings
    fastify.get('/api/shield/settings', {
      preHandler: [fastify.authenticate]
    }, async (request, reply) => {
      const userPayload = request.user as { userId: string };
      const user = db.findUserById(userPayload.userId);
      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      return reply.send({
        settings: user.shieldSettings,
        availableCategories: [
          { key: 'blockAdultContent', title: 'Adult & Explicit Content', description: 'Blocks pornography and sexually explicit websites.' },
          { key: 'blockGambling', title: 'Betting & Gambling Sites', description: 'Blocks online casinos, sports betting, and lottery portals.' },
          { key: 'blockSocialMedia', title: 'Social Media Networks', description: 'Restricts access to social media platforms for productivity.' },
          { key: 'blockAdsAndTrackers', title: 'Ad & Tracker Blocker', description: 'Blocks invasive advertisements, popups, and user analytics.' },
          { key: 'blockMalware', title: 'Malware & Phishing Guard', description: 'Prevents access to known malware domains and fraud sites.' }
        ]
      });
    });

    // Update user's Argus Shield settings
    fastify.put('/api/shield/settings', {
      preHandler: [fastify.authenticate]
    }, async (request, reply) => {
      const parseResult = updateShieldSchema.safeParse(request.body);
      if (!parseResult.success) {
        return reply.status(400).send({ error: 'Validation failed', details: parseResult.error.errors });
      }

      const userPayload = request.user as { userId: string };
      const current = db.findUserById(userPayload.userId)?.shieldSettings || shieldService.getDefaultShieldSettings();
      const updated = db.updateUserShieldSettings(userPayload.userId, {
        ...current,
        ...parseResult.data
      });

      return reply.send({ success: true, settings: updated });
    });
  };
};
