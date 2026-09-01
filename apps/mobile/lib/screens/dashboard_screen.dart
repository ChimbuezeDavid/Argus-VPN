import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/vpn_profile.dart';
import '../providers/vpn_provider.dart';
import '../widgets/globe_3d_background.dart';
import 'auth_screen.dart';
import 'server_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(double kbps) {
    if (kbps < 1000) {
      return '${kbps.toStringAsFixed(1)} KB/s';
    } else {
      return '${(kbps / 1000).toStringAsFixed(2)} MB/s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isConnected = vpn.vpnState == VpnState.connected;
    final isConnecting = vpn.vpnState == VpnState.connecting;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    String statusText = 'PROTECTION OFF';

    if (isConnected) {
      statusColor = AppColors.connected;
      statusText = 'SECURE & ENCRYPTED';
    } else if (isConnecting) {
      statusColor = AppColors.connecting;
      statusText = 'ESTABLISHING TUNNEL...';
    }

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.primaryEmerald, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'ARGUS VPN',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Dynamic 3D Spherical Rotating Globe in the Background
            Positioned.fill(
              child: Globe3DBackground(
                servers: vpn.servers,
                selectedServer: vpn.selectedServer,
                isConnected: isConnected,
                isConnecting: isConnecting,
              ),
            ),

            // Foreground Interactive Dashboard Controls
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // View Only Mode Banner
                  if (!vpn.isAuthenticated) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: AppColors.warningOrange, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'VIEW ONLY MODE • Sign in to connect',
                              style: TextStyle(
                                color: AppColors.warningOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.warningOrange, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Top Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Tactical Glowing Power Core Button
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
                              vpn.toggleVpnConnection();
                            }
                          },
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final glowSpread = isConnected ? 6.0 + (_glowController.value * 10.0) : 2.0;
                        final glowAlpha = isConnected ? 0.35 + (_glowController.value * 0.25) : 0.08;

                        return Container(
                          width: 175,
                          height: 175,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                isConnected
                                    ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.35 : 0.20)
                                    : (isDark ? AppColors.darkSurfaceLight.withValues(alpha: 0.9) : AppColors.lightSurfaceLight.withValues(alpha: 0.9)),
                                isDark ? AppColors.darkSurface.withValues(alpha: 0.95) : AppColors.lightSurface.withValues(alpha: 0.95),
                              ],
                            ),
                            border: Border.all(
                              color: isConnected
                                  ? AppColors.primaryEmerald
                                  : (isConnecting ? AppColors.warningOrange : cardBorder),
                              width: isConnected ? 3.5 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: glowAlpha),
                                blurRadius: isConnected ? 32 : 12,
                                spreadRadius: glowSpread,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isConnecting
                                ? const SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3.5,
                                      color: AppColors.warningOrange,
                                    ),
                                  )
                                : Icon(
                                    Icons.power_settings_new_rounded,
                                    size: 72,
                                    color: isConnected ? AppColors.primaryEmerald : textSecondary,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Connection Timer / Status Subtitle
                  if (isConnected)
                    Text(
                      _formatDuration(vpn.trafficStats.duration),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: 1.5,
                      ),
                    )
                  else
                    Text(
                      'Tap Power to Connect',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Live Traffic Metrics Card (Telemetry Data)
                  if (isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'DOWNLOAD',
                            _formatSpeed(vpn.trafficStats.downloadSpeedKbps),
                            _formatBytes(vpn.trafficStats.bytesReceived),
                            Icons.arrow_downward_rounded,
                            AppColors.primaryCyan,
                            textPrimary,
                            textSecondary,
                          ),
                          Container(width: 1, height: 42, color: cardBorder),
                          _buildStatColumn(
                            'UPLOAD',
                            _formatSpeed(vpn.trafficStats.uploadSpeedKbps),
                            _formatBytes(vpn.trafficStats.bytesSent),
                            Icons.arrow_upward_rounded,
                            AppColors.primaryEmerald,
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Server Selection Card (Windscribe Style Target Node)
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
                        color: cardBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isConnected
                              ? AppColors.primaryEmerald.withValues(alpha: 0.4)
                              : cardBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            vpn.selectedServer?.flagEmoji ?? '🇩🇪',
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SERVER LOCATION',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  vpn.selectedServer != null
                                      ? '${vpn.selectedServer!.location.city}, ${vpn.selectedServer!.location.country}'
                                      : 'Frankfurt (Main), Germany',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'WireGuard Tunnel • ${vpn.selectedServer?.pingMs ?? 38} ms',
                                  style: const TextStyle(
                                    color: AppColors.primaryEmerald,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Connect to Best Location (Auto) Action Banner
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
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryEmerald.withValues(alpha: isDark ? 0.20 : 0.12),
                              AppColors.primaryCyan.withValues(alpha: isDark ? 0.12 : 0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryEmerald, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connect to Best Location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Auto-picks lowest ping node (${vpn.servers.first.location.city} • ${vpn.servers.first.pingMs} ms)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryEmerald,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'AUTO',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String speed,
    String total,
    IconData icon,
    Color iconColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          speed,
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          total,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
