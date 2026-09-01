export enum UserTier {
  FREE = 'FREE',
  PRO = 'PRO',
  ENTERPRISE = 'ENTERPRISE'
}

export interface User {
  id: string;
  email: string;
  tier: UserTier;
  createdAt: Date | string;
  updatedAt: Date | string;
  activeDevicesCount: number;
  maxAllowedDevices: number;
}
