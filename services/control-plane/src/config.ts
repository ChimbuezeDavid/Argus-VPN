import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  host: process.env.HOST || '0.0.0.0',
  jwtSecret: process.env.JWT_SECRET || 'argus_super_secret_jwt_key_987654321',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  daemonSecretToken: process.env.DAEMON_SECRET_TOKEN || 'argus_node_secret_key_123',
  dns: {
    standard: ['1.1.1.1', '1.0.0.1'], // Cloudflare Standard
    malwareBlock: ['1.1.1.2', '9.9.9.9'], // Cloudflare Security / Quad9
    familyShield: ['1.1.1.3', '185.228.168.168'], // Cloudflare Family + CleanBrowsing (Adult blocked)
    gamblingBlock: ['185.228.168.10', '185.228.169.11'], // CleanBrowsing Adult + Gambling Filter
    strictCustom: ['185.228.168.168', '1.1.1.3']
  }
};
