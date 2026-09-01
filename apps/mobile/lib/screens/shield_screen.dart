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

    final score = vpn.shieldScore;
    final percentText = '${(score * 100).toInt()}%';

    Color scoreColor;
    if (score >= 0.8) {
      scoreColor = AppColors.primaryEmerald;
    } else if (score >= 0.4) {
      scoreColor = AppColors.primaryCyan;
    } else if (score > 0) {
      scoreColor = AppColors.warningOrange;
    } else {
      scoreColor = AppColors.alertRed;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ARGUS SHIELD',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Cybersecurity Score & Status Gauge Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    AppColors.primaryCyan.withValues(alpha: isDark ? 0.06 : 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Radial Progress Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: score,
                              strokeWidth: 6,
                              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                              color: scoreColor,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            percentText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  vpn.shieldGradeTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: scoreColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                if (vpn.isReloadingShield)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningOrange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.warningOrange, width: 0.8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: AppColors.warningOrange,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'RELOADING',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.warningOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vpn.activeShieldProfileSummary,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Active Resolvers Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.dns_rounded, size: 14, color: AppColors.primaryCyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Resolvers: ${vpn.activeDnsServers.join(" • ")}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Quick Security Presets
            const Text(
              'QUICK SECURITY PROFILES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(
                    title: 'Family Guard',
                    icon: Icons.family_restroom_rounded,
                    color: AppColors.primaryEmerald,
                    onTap: () => vpn.applyShieldPreset('family'),
                    isDark: isDark,
                  ),
                  _buildPresetChip(
                    title: 'Max Privacy',
                    icon: Icons.vpn_lock_rounded,
                    color: AppColors.primaryCyan,
                    onTap: () => vpn.applyShieldPreset('max_privacy'),
                    isDark: isDark,
                  ),
                  _buildPresetChip(
                    title: 'Deep Focus',
                    icon: Icons.lock_clock_rounded,
                    color: AppColors.accentPurple,
                    onTap: () => vpn.applyShieldPreset('focus'),
                    isDark: isDark,
                  ),
                  _buildPresetChip(
                    title: 'Performance',
                    icon: Icons.flash_on_rounded,
                    color: AppColors.warningOrange,
                    onTap: () => vpn.applyShieldPreset('performance'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 3. Granular Modules
            const Text(
              'PROTECTION MODULES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Module 1: Malware
            _buildModuleTile(
              title: 'Malware & Phishing Armor',
              subtitle: 'Blocks known malicious domains, ransomware, and credential harvesters.',
              icon: Icons.security_rounded,
              iconColor: AppColors.primaryEmerald,
              value: shield.blockMalware,
              onChanged: (val) => vpn.updateShieldSetting(blockMalware: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 2: Ads & Trackers
            _buildModuleTile(
              title: 'Ads & Cross-Site Trackers',
              subtitle: 'Stops intrusive ad networks, telemetry beacons, and analytics trackers.',
              icon: Icons.block_rounded,
              iconColor: AppColors.accentPurple,
              value: shield.blockAdsAndTrackers,
              onChanged: (val) => vpn.updateShieldSetting(blockAdsAndTrackers: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 3: Adult Content
            _buildModuleTile(
              title: 'Adult & Explicit Filter',
              subtitle: 'Restricts adult websites, explicit domains, and NSFW content.',
              icon: Icons.explicit_rounded,
              iconColor: AppColors.alertRed,
              value: shield.blockAdultContent,
              onChanged: (val) => vpn.updateShieldSetting(blockAdultContent: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 4: Gambling
            _buildModuleTile(
              title: 'Betting & Gambling Lock',
              subtitle: 'Blocks online casinos, sports betting, and digital poker rooms.',
              icon: Icons.casino_rounded,
              iconColor: AppColors.warningOrange,
              value: shield.blockGambling,
              onChanged: (val) => vpn.updateShieldSetting(blockGambling: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 5: Social Media
            _buildModuleTile(
              title: 'Social Network Blocker',
              subtitle: 'Limits access to social media feeds for focus and battery savings.',
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.primaryCyan,
              value: shield.blockSocialMedia,
              onChanged: (val) => vpn.updateShieldSetting(blockSocialMedia: val),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Module 6: MAC Address Masking
            _buildModuleTile(
              title: 'Hardware & MAC Masking',
              subtitle: 'Hides physical Layer-2 MAC address and hardware fingerprint from local Wi-Fi and ISP sniffing.',
              icon: Icons.fingerprint_rounded,
              iconColor: AppColors.primaryEmerald,
              value: shield.macAddressMasking,
              onChanged: (val) => vpn.updateShieldSetting(macAddressMasking: val),
              isDark: isDark,
            ),

            const SizedBox(height: 10),

            // Module 7: Decoy Traffic (Anti-Correlation)
            _buildModuleTile(
              title: 'Decoy Traffic (Chaff Injector)',
              subtitle: 'Transmits randomized background dummy bursts over the tunnel to defeat ISP AI traffic correlation & timing analysis.',
              icon: Icons.grain_rounded,
              iconColor: AppColors.primaryCyan,
              value: shield.decoyTraffic,
              onChanged: (val) => vpn.toggleDecoyTraffic(val),
              isDark: isDark,
            ),

            const SizedBox(height: 10),

            // Module 8: Stealth Censorship Bypass
            _buildModuleTile(
              title: 'Stealth Censorship Bypass',
              subtitle: 'Camouflages WireGuard packets inside port 443 TLS/WebSocket framing to bypass Deep Packet Inspection (DPI).',
              icon: Icons.visibility_off_rounded,
              iconColor: AppColors.warningOrange,
              value: shield.stealthMode,
              onChanged: (val) => vpn.toggleStealthMode(val),
              isDark: isDark,
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
    final borderColor = value ? iconColor.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: value ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
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
