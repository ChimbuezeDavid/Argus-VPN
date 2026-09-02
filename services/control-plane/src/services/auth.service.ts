import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { FastifyInstance } from 'fastify';
import { IArgusDatabase } from '../db/database.interface.js';
import { UserRecord } from '../db/memory-db.js';
import { UserTier, RegisterRequestDto, LoginRequestDto, AuthResponseDto } from '@argus/shared-types';
import { ShieldService } from '../shield/shield.service.js';

export class AuthService {
  constructor(
    private db: IArgusDatabase,
    private shieldService: ShieldService
  ) {}

  public async register(fastify: FastifyInstance, dto: RegisterRequestDto): Promise<AuthResponseDto> {
    const existing = await this.db.findUserByEmail(dto.email);
    if (existing) {
      throw new Error('An account with this email address already exists');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const userId = crypto.randomUUID();
    const newUser: UserRecord = {
      id: userId,
      email: dto.email.toLowerCase(),
      tier: UserTier.FREE,
      createdAt: new Date(),
      updatedAt: new Date(),
      activeDevicesCount: 1,
      maxAllowedDevices: 5,
      passwordHash,
      shieldSettings: this.shieldService.getDefaultShieldSettings()
    };

    await this.db.createUser(newUser);

    const token = fastify.jwt.sign({ userId: newUser.id, email: newUser.email, tier: newUser.tier });
    const refreshToken = crypto.randomBytes(32).toString('hex');

    const { passwordHash: _, ...userWithoutHash } = newUser;

    return {
      user: userWithoutHash,
      token,
      refreshToken,
      expiresIn: 7 * 24 * 60 * 60 // 7 days
    };
  }

  public async login(fastify: FastifyInstance, dto: LoginRequestDto): Promise<AuthResponseDto> {
    const user = await this.db.findUserByEmail(dto.email);
    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new Error('Invalid email or password');
    }

    const token = fastify.jwt.sign({ userId: user.id, email: user.email, tier: user.tier });
    const refreshToken = crypto.randomBytes(32).toString('hex');

    const { passwordHash: _, ...userWithoutHash } = user;

    return {
      user: userWithoutHash,
      token,
      refreshToken,
      expiresIn: 7 * 24 * 60 * 60
    };
  }

  public async createGuestSession(fastify: FastifyInstance, _deviceName?: string): Promise<AuthResponseDto> {
    const guestId = crypto.randomUUID();
    const guestEmail = `guest_${guestId.substring(0, 8)}@argusvpn.internal`;
    const passwordHash = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);

    const newUser: UserRecord = {
      id: guestId,
      email: guestEmail,
      tier: UserTier.FREE,
      createdAt: new Date(),
      updatedAt: new Date(),
      activeDevicesCount: 1,
      maxAllowedDevices: 1,
      passwordHash,
      shieldSettings: this.shieldService.getDefaultShieldSettings()
    };

    await this.db.createUser(newUser);

    const token = fastify.jwt.sign({ userId: newUser.id, email: newUser.email, tier: newUser.tier });
    const refreshToken = crypto.randomBytes(32).toString('hex');
    const { passwordHash: _, ...userWithoutHash } = newUser;

    return {
      user: userWithoutHash,
      token,
      refreshToken,
      expiresIn: 30 * 24 * 60 * 60 // 30 days guest session
    };
  }
}
