import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/vpn_provider.dart';

class ShieldScreen extends StatelessWidget {
  const ShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final shield = vpn.shieldSettings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    int activeCount = 0;
    if (shield.blockMalware) activeCount++;
    if (shield.blockAdsAndTrackers) activeCount++;
    if (shield.blockAdultContent) activeCount++;
    if (shield.blockGambling) activeCount++;
    if (shield.blockSocialMedia) activeCount++;
    if (shield.macAddressMasking) activeCount++;
    if (shield.decoyTraffic) activeCount++;
    if (shield.stealthMode) activeCount++;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Privacy & Shield',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Protection Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: isDark ? 0.18 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.primaryEmerald,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeCount >= 6
                                  ? 'Comprehensive Protection'
                                  : (activeCount >= 3 ? 'Standard Protection' : 'Minimal Protection'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$activeCount of 8 privacy filters active',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (vpn.isReloadingShield)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryEmerald),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Protection Presets
                  Text(
                    'Quick Presets',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildPresetChip(
                          title: 'Maximum',
                          icon: Icons.security_rounded,
                          color: AppColors.primaryEmerald,
                          onTap: () {
                            vpn.updateShieldSetting(
                              blockMalware: true,
                              blockAdsAndTrackers: true,
                              blockAdultContent: true,
                              blockGambling: true,
                              blockSocialMedia: false,
                              macAddressMasking: true,
                              decoyTraffic: true,
                              stealthMode: false,
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildPresetChip(
                          title: 'Balanced',
                          icon: Icons.shield_outlined,
                          color: AppColors.primaryCyan,
                          onTap: () {
                            vpn.updateShieldSetting(
                              blockMalware: true,
                              blockAdsAndTrackers: true,
                              blockAdultContent: false,
                              blockGambling: false,
                              blockSocialMedia: false,
                              macAddressMasking: true,
                              decoyTraffic: false,
                              stealthMode: false,
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildPresetChip(
                          title: 'Focus',
                          icon: Icons.do_not_disturb_on_rounded,
                          color: AppColors.accentPurple,
                          onTap: () {
                            vpn.updateShieldSetting(
                              blockMalware: true,
                              blockAdsAndTrackers: true,
                              blockAdultContent: true,
                              blockGambling: true,
                              blockSocialMedia: true,
                              macAddressMasking: true,
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildPresetChip(
                          title: 'Minimal',
                          icon: Icons.tune_rounded,
                          color: AppColors.warningOrange,
                          onTap: () {
                            vpn.updateShieldSetting(
                              blockMalware: true,
                              blockAdsAndTrackers: false,
                              blockAdultContent: false,
                              blockGambling: false,
                              blockSocialMedia: false,
                              macAddressMasking: false,
                              decoyTraffic: false,
                              stealthMode: false,
                            );
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Security & Threat Filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Module 1: Malware & Dangerous Sites
            _buildModuleTile(
              title: 'Malware & Dangerous Sites',
              subtitle: 'Blocks known phishing domains, malicious links, and infected file downloads.',
              icon: Icons.security_rounded,
              iconColor: AppColors.primaryEmerald,
              value: shield.blockMalware,
              onChanged: (val) => vpn.updateShieldSetting(blockMalware: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 2: Ads & Trackers
            _buildModuleTile(
              title: 'Ads & Web Trackers',
              subtitle: 'Stops intrusive advertisements, banners, popups, and analytics tracking cookies.',
              icon: Icons.block_rounded,
              iconColor: AppColors.primaryCyan,
              value: shield.blockAdsAndTrackers,
              onChanged: (val) => vpn.updateShieldSetting(blockAdsAndTrackers: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 3: Device Fingerprint Masking
            _buildModuleTile(
              title: 'Device Hardware Masking',
              subtitle: 'Hides Wi-Fi hardware MAC address and network fingerprint from local hotspots.',
              icon: Icons.fingerprint_rounded,
              iconColor: AppColors.primaryIndigo,
              value: shield.macAddressMasking,
              onChanged: (val) => vpn.updateShieldSetting(macAddressMasking: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 4: Traffic Camouflage
            _buildModuleTile(
              title: 'Traffic Camouflage (Anti-Correlation)',
              subtitle: 'Transmits subtle randomized dummy packets to prevent ISP traffic-flow inspection.',
              icon: Icons.grain_rounded,
              iconColor: AppColors.accentPurple,
              value: shield.decoyTraffic,
              onChanged: (val) => vpn.toggleDecoyTraffic(val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 5: Stealth VPN
            _buildModuleTile(
              title: 'Stealth VPN (Bypass Firewalls)',
              subtitle: 'Disguises WireGuard traffic in port 443 TLS framing to bypass restricted networks.',
              icon: Icons.visibility_off_rounded,
              iconColor: AppColors.warningOrange,
              value: shield.stealthMode,
              onChanged: (val) => vpn.toggleStealthMode(val),
              isDark: isDark,
            ),

            const SizedBox(height: 22),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Content & Focus Controls',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Module 6: Adult Content
            _buildModuleTile(
              title: 'Adult & Explicit Content',
              subtitle: 'Filters adult portals, explicit imagery, and unsafe search engine results.',
              icon: Icons.no_adult_content_rounded,
              iconColor: AppColors.alertRed,
              value: shield.blockAdultContent,
              onChanged: (val) => vpn.updateShieldSetting(blockAdultContent: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 7: Gambling & Betting
            _buildModuleTile(
              title: 'Gambling & Sports Betting',
              subtitle: 'Restricts online casinos, sportsbooks, lottery websites, and betting portals.',
              icon: Icons.casino_rounded,
              iconColor: AppColors.warningOrange,
              value: shield.blockGambling,
              onChanged: (val) => vpn.updateShieldSetting(blockGambling: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 8: Social Media
            _buildModuleTile(
              title: 'Social Media Apps',
              subtitle: 'Blocks TikTok, Instagram, Facebook, X/Twitter to minimize digital distractions.',
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.primaryIndigo,
              value: shield.blockSocialMedia,
              onChanged: (val) => vpn.updateShieldSetting(blockSocialMedia: val),
              isDark: isDark,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primaryEmerald.withValues(alpha: 0.3) : border,
          width: value ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: AppColors.primaryEmerald,
            activeTrackColor: AppColors.primaryEmerald.withValues(alpha: 0.3),
            inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            inactiveTrackColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
