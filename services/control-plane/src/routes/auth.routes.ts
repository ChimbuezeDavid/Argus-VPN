import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AuthService } from '../services/auth.service.js';

const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  deviceName: z.string().optional()
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
  deviceName: z.string().optional()
});

export const authRoutes = (authService: AuthService): FastifyPluginAsync => {
  return async (fastify) => {
    fastify.post('/api/auth/register', async (request, reply) => {
      const parseResult = registerSchema.safeParse(request.body);
      if (!parseResult.success) {
        return reply.status(400).send({ error: 'Validation failed', details: parseResult.error.errors });
      }

      try {
        const result = await authService.register(fastify, parseResult.data);
        return reply.status(201).send(result);
      } catch (err: any) {
        return reply.status(400).send({ error: err.message });
      }
    });

    fastify.post('/api/auth/login', async (request, reply) => {
      const parseResult = loginSchema.safeParse(request.body);
      if (!parseResult.success) {
        return reply.status(400).send({ error: 'Validation failed', details: parseResult.error.errors });
      }

      try {
        const result = await authService.login(fastify, parseResult.data);
        return reply.send(result);
      } catch (err: any) {
        return reply.status(401).send({ error: err.message });
      }
    });

    fastify.post('/api/auth/guest', async (_request, reply) => {
      try {
        const result = await authService.createGuestSession(fastify);
        return reply.status(201).send(result);
      } catch (err: any) {
        return reply.status(500).send({ error: err.message });
      }
    });
  };
};
