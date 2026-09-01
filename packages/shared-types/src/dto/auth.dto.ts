import { User } from '../models/user.js';

export interface RegisterRequestDto {
  email: string;
  password: string;
  deviceName?: string;
}

export interface LoginRequestDto {
  email: string;
  password: string;
  deviceName?: string;
}

export interface AuthResponseDto {
  user: User;
  token: string;
  refreshToken: string;
  expiresIn: number; // in seconds
}
