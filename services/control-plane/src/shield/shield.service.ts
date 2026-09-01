import { ArgusShieldSettings } from '@argus/shared-types';
import { config } from '../config.js';

export class ShieldService {
  /**
   * Resolves the optimal DNS server list tailored to the user's Argus Shield preferences
   */
  public resolveDnsServers(settings?: ArgusShieldSettings): string[] {
    if (!settings) {
      return config.dns.standard;
    }

    const { blockAdultContent, blockGambling, blockMalware } = settings;

    // Highest protection level: Adult + Gambling blocked
    if (blockAdultContent && blockGambling) {
      return config.dns.gamblingBlock;
    }

    // Adult / Porn blocked
    if (blockAdultContent) {
      return config.dns.familyShield;
    }

    // Malware / Phishing blocked
    if (blockMalware) {
      return config.dns.malwareBlock;
    }

    // Default fast/secure DNS
    return config.dns.standard;
  }

  /**
   * Default shield configuration for new users
   */
  public getDefaultShieldSettings(): ArgusShieldSettings {
    return {
      blockMalware: true,
      blockAdsAndTrackers: true,
      blockAdultContent: false,
      blockGambling: false,
      blockSocialMedia: false
    };
  }
}
