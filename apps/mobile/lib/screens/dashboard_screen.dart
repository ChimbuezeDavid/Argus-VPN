import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/vpn_profile.dart';
import '../providers/vpn_provider.dart';
import 'auth_screen.dart';
import 'server_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(double kbps) {
    if (kbps < 1000) {
      return '${kbps.toStringAsFixed(0)} KB/s';
    } else {
      return '${(kbps / 1000).toStringAsFixed(1)} MB/s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isConnected = vpn.vpnState == VpnState.connected;
    final isConnecting = vpn.vpnState == VpnState.connecting;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBgLight = isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.2 : 0.12)
                    : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: isConnected ? AppColors.primaryEmerald : textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Argus VPN',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                if (!vpn.isAuthenticated) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: vpn.isAuthenticated
                      ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.15 : 0.1)
                      : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: vpn.isAuthenticated
                        ? AppColors.primaryEmerald.withValues(alpha: 0.3)
                        : border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vpn.isAuthenticated ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                      size: 14,
                      color: vpn.isAuthenticated ? AppColors.primaryEmerald : textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vpn.isAuthenticated
                          ? (vpn.currentUser?.tier ?? 'Pro')
                          : 'Sign In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: vpn.isAuthenticated ? AppColors.primaryEmerald : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!vpn.isAuthenticated) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.warningOrange, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View Mode • Tap to sign in and activate protection',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.warningOrange, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                isConnected
                    ? "You're protected"
                    : (isConnecting ? "Connecting to VPN..." : "You're not protected"),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isConnected
                      ? AppColors.primaryEmerald
                      : (isConnecting ? AppColors.warningOrange : textPrimary),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isConnected
                    ? "Encrypted WireGuard tunnel active"
                    : (isConnecting ? "Negotiating secure handshake" : "Your IP address and traffic are exposed"),
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    if (isConnecting) return;
                    if (!vpn.isAuthenticated) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                    } else {
                      vpn.toggleVpnConnection();
                    }
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedScale(
                    scale: _isPressed ? 0.94 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? AppColors.primaryEmerald
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        border: Border.all(
                          color: isConnected
                              ? AppColors.primaryEmerald
                              : (isConnecting ? AppColors.warningOrange : border),
                          width: isConnected ? 4 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isConnected
                                ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.35 : 0.25)
                                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: isConnected ? 28 : 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isConnecting
                            ? const SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  color: AppColors.warningOrange,
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new_rounded,
                                size: 68,
                                color: isConnected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(vpn.trafficStats.duration),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryEmerald,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Tap to connect',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: isConnecting
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ServerListScreen()),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isConnected
                          ? AppColors.primaryEmerald.withValues(alpha: 0.35)
                          : border,
                      width: isConnected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cardBgLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            vpn.selectedServer?.flagEmoji ?? '🇩🇪',
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vpn.selectedServer != null
                                  ? '${vpn.selectedServer!.location.city}, ${vpn.selectedServer!.location.country}'
                                  : 'Frankfurt, Germany',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (vpn.selectedServer?.pingMs ?? 38) < 60
                                        ? AppColors.primaryEmerald
                                        : AppColors.warningOrange,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${vpn.selectedServer?.pingMs ?? 38} ms ping • WireGuard',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (!isConnected && vpn.servers.isNotEmpty)
                GestureDetector(
                  onTap: isConnecting
                      ? null
                      : () {
                          if (!vpn.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                          } else {
                            vpn.quickConnectFastestServer();
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBgLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.primaryEmerald, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fastest Location',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Auto-select lowest latency server',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Quick Connect',
                          style: TextStyle(
                            color: AppColors.primaryEmerald,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Download',
                          speed: _formatSpeed(vpn.trafficStats.downloadSpeedKbps),
                          total: _formatBytes(vpn.trafficStats.bytesReceived),
                          icon: Icons.arrow_downward_rounded,
                          iconColor: AppColors.primaryCyan,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      Container(width: 1, height: 36, color: border),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Upload',
                          speed: _formatSpeed(vpn.trafficStats.uploadSpeedKbps),
                          total: _formatBytes(vpn.trafficStats.bytesSent),
                          icon: Icons.arrow_upward_rounded,
                          iconColor: AppColors.primaryEmerald,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String speed,
    required String total,
    required IconData icon,
    required Color iconColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          speed,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          total,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
