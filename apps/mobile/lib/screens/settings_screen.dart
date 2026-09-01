import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/vpn_provider.dart';
import 'auth_screen.dart';
import 'split_tunneling_screen.dart';
import 'dns_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS & SECURITY',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. Account / Tier Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded, color: AppColors.primaryEmerald, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vpn.isAuthenticated ? vpn.currentUser!.email : 'Guest (View Only)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                vpn.isAuthenticated ? vpn.currentUser!.tier.toUpperCase() : 'VIEW ONLY',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryEmerald,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '• 50+ Global Nodes',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (vpn.isAuthenticated) {
                        vpn.logout();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                    },
                    child: Text(
                      vpn.isAuthenticated ? 'Logout' : 'Sign In',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 2. Appearance & Theme Section
            _buildSectionHeader('APPEARANCE & THEME'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildThemeOption(
                        context: context,
                        title: 'Dark Mode',
                        icon: Icons.dark_mode_rounded,
                        mode: ThemeMode.dark,
                        currentMode: vpn.themeMode,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOption(
                        context: context,
                        title: 'Light Mode',
                        icon: Icons.light_mode_rounded,
                        mode: ThemeMode.light,
                        currentMode: vpn.themeMode,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOption(
                        context: context,
                        title: 'System',
                        icon: Icons.brightness_auto_rounded,
                        mode: ThemeMode.system,
                        currentMode: vpn.themeMode,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 3. Network & Security Section
            _buildSectionHeader('NETWORK & TUNNEL SUITE'),
            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'Always-On Kill Switch',
              subtitle: 'Blocks internet traffic automatically if the VPN disconnects unexpectedly.',
              icon: Icons.shield_rounded,
              iconColor: AppColors.alertRed,
              trailing: Switch(
                value: vpn.killSwitchEnabled,
                activeThumbColor: AppColors.primaryEmerald,
                activeTrackColor: AppColors.primaryEmerald.withValues(alpha: 0.3),
                inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                inactiveTrackColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                onChanged: (val) => vpn.setKillSwitch(val),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildSettingTile(
              title: 'Local LAN Traffic Access',
              subtitle: 'Allows accessing smart TVs, Chromecast, local printers, and Samba/Plex shares while connected.',
              icon: Icons.lan_rounded,
              iconColor: AppColors.primaryCyan,
              trailing: Switch(
                value: vpn.shieldSettings.localLanAccess,
                activeThumbColor: AppColors.primaryEmerald,
                activeTrackColor: AppColors.primaryEmerald.withValues(alpha: 0.3),
                inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                inactiveTrackColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                onChanged: (val) => vpn.toggleLocalLanAccess(val),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () => _showMtuTunerDialog(context, vpn, isDark),
              child: _buildSettingTile(
                title: 'Packet MTU Tuner',
                subtitle: 'Manual MTU sizing (1280–1500 bytes) to prevent packet fragmentation on cellular networks.',
                icon: Icons.tune_rounded,
                iconColor: AppColors.primaryEmerald,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${vpn.shieldSettings.packetMtu} B',
                      style: const TextStyle(
                        color: AppColors.primaryEmerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () => _showTrustedWifiDialog(context, vpn, isDark),
              child: _buildSettingTile(
                title: 'Trusted Wi-Fi Networks',
                subtitle: 'Auto-secure untrusted Wi-Fi hotspots and bypass VPN on verified home/work networks.',
                icon: Icons.wifi_protected_setup_rounded,
                iconColor: AppColors.warningOrange,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${vpn.shieldSettings.trustedWifiNetworks.length} Trusted',
                      style: const TextStyle(
                        color: AppColors.warningOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () => _showPortForwardingDialog(context, vpn, isDark),
              child: _buildSettingTile(
                title: 'Ephemeral Port Forwarding',
                subtitle: 'Lease high-speed temporary ports (49152–65535) for fast P2P and gaming hosting.',
                icon: Icons.swap_vert_rounded,
                iconColor: AppColors.accentPurple,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vpn.activePortForward != null ? 'Port ${vpn.activePortForward}' : 'Disabled',
                      style: TextStyle(
                        color: vpn.activePortForward != null ? AppColors.accentPurple : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingTile(
              title: 'VPN Protocol',
              subtitle: 'Hardware-tuned WireGuard UDP engine with Curve25519 cryptography.',
              icon: Icons.hub_rounded,
              iconColor: AppColors.primaryCyan,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'WireGuard',
                  style: TextStyle(
                    color: AppColors.primaryEmerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DnsSettingsScreen()),
                );
              },
              child: _buildSettingTile(
                title: 'Custom DNS Provider',
                subtitle: 'Configure private resolvers (Pi-hole, AdGuard Home, Google, NextDNS).',
                icon: Icons.dns_rounded,
                iconColor: AppColors.accentPurple,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vpn.activeDnsServers.first,
                      style: const TextStyle(
                        color: AppColors.primaryCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingTile(
              title: 'MAC Address & Anti-Tracking',
              subtitle: 'Layer 2/3 hardware isolation. Hides device physical MAC from local Wi-Fi hotspots and remote networks.',
              icon: Icons.fingerprint_rounded,
              iconColor: AppColors.primaryEmerald,
              trailing: Switch(
                value: vpn.shieldSettings.macAddressMasking,
                activeThumbColor: AppColors.primaryEmerald,
                activeTrackColor: AppColors.primaryEmerald.withValues(alpha: 0.3),
                inactiveThumbColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                inactiveTrackColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                onChanged: (val) {
                  vpn.updateShieldSetting(macAddressMasking: val);
                },
              ),
              isDark: isDark,
            ),

            const SizedBox(height: 22),

            // 4. Smart Automations Section
            _buildSectionHeader('SMART AUTOMATIONS'),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SplitTunnelingScreen()),
                );
              },
              child: _buildSettingTile(
                title: 'Split Tunneling',
                subtitle: vpn.bypassedPackages.isEmpty
                    ? 'All apps routed through VPN'
                    : '${vpn.bypassedPackages.length} apps bypassing VPN directly to local ISP',
                icon: Icons.call_split_rounded,
                iconColor: AppColors.primaryEmerald,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 24),

            // 5. Version Info
            Center(
              child: Text(
                'Argus VPN • v2.0 Enterprise Release (2026.2)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
  }) {
    final isSelected = currentMode == mode;
    final vpn = context.read<VpnProvider>();

    return Expanded(
      child: InkWell(
        onTap: () => vpn.setThemeMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.2 : 0.15)
                : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryEmerald : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primaryEmerald : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primaryEmerald : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
          trailing,
        ],
      ),
    );
  }

  void _showMtuTunerDialog(BuildContext context, VpnProvider vpn, bool isDark) {
    int selectedMtu = vpn.shieldSettings.packetMtu;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primaryEmerald),
                  const SizedBox(width: 10),
                  Text(
                    'Packet MTU & MSS Tuner',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust WireGuard Maximum Transmission Unit to eliminate packet fragmentation and TCP retransmissions.',
                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '$selectedMtu Bytes',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryEmerald,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Slider(
                value: selectedMtu.toDouble(),
                min: 1280,
                max: 1500,
                divisions: 22,
                activeColor: AppColors.primaryEmerald,
                inactiveColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                label: '$selectedMtu B',
                onChanged: (val) {
                  setModalState(() {
                    selectedMtu = val.round();
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMtuPresetButton('Safe (1280)', 1280, selectedMtu, isDark, (mtu) {
                    setModalState(() => selectedMtu = mtu);
                  }),
                  _buildMtuPresetButton('Optimal (1420)', 1420, selectedMtu, isDark, (mtu) {
                    setModalState(() => selectedMtu = mtu);
                  }),
                  _buildMtuPresetButton('Max LAN (1500)', 1500, selectedMtu, isDark, (mtu) {
                    setModalState(() => selectedMtu = mtu);
                  }),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    vpn.setPacketMtu(selectedMtu);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply MTU Setting', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMtuPresetButton(String label, int mtu, int current, bool isDark, ValueChanged<int> onSelect) {
    final isSelected = current == mtu;
    return OutlinedButton(
      onPressed: () => onSelect(mtu),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isSelected ? AppColors.primaryEmerald : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        backgroundColor: isSelected ? AppColors.primaryEmerald.withValues(alpha: 0.15) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.primaryEmerald : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
      ),
    );
  }

  void _showTrustedWifiDialog(BuildContext context, VpnProvider vpn, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final trusted = vpn.shieldSettings.trustedWifiNetworks;
          final currentSsid = vpn.currentWifiSsid;
          final isCurrentTrusted = trusted.contains(currentSsid);

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.wifi_protected_setup_rounded, color: AppColors.warningOrange),
                    const SizedBox(width: 10),
                    Text(
                      'Trusted Wi-Fi Networks',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Argus VPN automatically protects you on public Wi-Fi and pauses encryption on trusted SSIDs.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                ),
                const SizedBox(height: 16),

                // Current Connected Wi-Fi Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_rounded, color: AppColors.primaryCyan, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONNECTED WI-FI',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8),
                            ),
                            Text(
                              currentSsid,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isCurrentTrusted) {
                            vpn.removeTrustedWifi(currentSsid);
                          } else {
                            vpn.addTrustedWifi(currentSsid);
                          }
                          setModalState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentTrusted ? AppColors.alertRed : AppColors.primaryEmerald,
                          foregroundColor: isCurrentTrusted ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          isCurrentTrusted ? 'Untrust' : 'Trust SSID',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-Secure Toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-Secure Untrusted Wi-Fi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                          Text('Connects immediately upon detecting unknown Wi-Fi hotspots', style: TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: vpn.shieldSettings.autoSecureUntrustedWifi,
                      activeThumbColor: AppColors.primaryEmerald,
                      activeTrackColor: AppColors.primaryEmerald.withValues(alpha: 0.3),
                      onChanged: (val) {
                        vpn.toggleAutoSecureUntrustedWifi(val);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'TRUSTED NETWORKS LIST (${trusted.length})',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),

                if (trusted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No trusted networks added yet.', style: TextStyle(fontSize: 12, color: textSecondary)),
                  )
                else
                  ...trusted.map(
                    (ssid) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.primaryEmerald, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(ssid, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.alertRed),
                            onPressed: () {
                              vpn.removeTrustedWifi(ssid);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPortForwardingDialog(BuildContext context, VpnProvider vpn, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final activePort = vpn.activePortForward;
          final expiresAt = vpn.portForwardExpiresAt;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.swap_vert_rounded, color: AppColors.accentPurple),
                    const SizedBox(width: 10),
                    Text(
                      'Ephemeral Port Forwarding',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Dynamically open an ephemeral port on the active WireGuard node for BitTorrent, high-speed P2P, or game hosting.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                ),
                const SizedBox(height: 20),

                if (activePort != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ACTIVE FORWARDED PORT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$activePort',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentPurple,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (expiresAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Lease expires in 23h 59m',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        vpn.cancelEphemeralPort();
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.stop_circle_outlined, color: AppColors.alertRed, size: 18),
                      label: const Text('Release Port Lease', style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.alertRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_open_rounded, size: 32, color: textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'No Active Port Leased',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Click below to generate a dynamic 24-hour port lease.',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await vpn.requestEphemeralPort();
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.bolt_rounded, color: Colors.black),
                      label: const Text('Request 24h Port Lease', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
