import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/vpn_provider.dart';

class SplitTunnelingScreen extends StatefulWidget {
  const SplitTunnelingScreen({super.key});

  @override
  State<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'bypassed', 'user', 'system'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VpnProvider>().loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bypassedCount = vpn.bypassedPackages.length;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceLight = isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight;

    final filteredApps = vpn.installedApps.where((app) {
      final matchesSearch = app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      switch (_activeFilter) {
        case 'bypassed':
          return app.isBypassed;
        case 'user':
          return !app.isSystemApp;
        case 'system':
          return app.isSystemApp;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SPLIT TUNNELING',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
        actions: [
          if (bypassedCount > 0)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Reset Split Tunneling?', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800)),
                    content: Text(
                      'All apps will route through the VPN again.',
                      style: TextStyle(color: textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: TextStyle(color: textSecondary)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          vpn.clearAllBypasses();
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.alertRed),
              label: const Text('Reset', style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info Header Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withValues(alpha: isDark ? 0.15 : 0.10),
                      AppColors.primaryEmerald.withValues(alpha: isDark ? 0.08 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.alt_route_rounded, color: AppColors.primaryCyan, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'App Bypass Control',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (vpn.isReloadingShield)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.primaryEmerald),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 8,
                                        height: 8,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.primaryEmerald,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'RELOADING',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryEmerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bypassedCount > 0 ? AppColors.primaryCyan : surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$bypassedCount Bypassed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: bypassedCount > 0 ? Colors.black : textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Bypassed apps use your physical ISP/cellular connection directly.',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search installed applications...',
                  hintStyle: TextStyle(color: textMuted),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryEmerald),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${vpn.installedApps.length})', isDark, cardBg, cardBorder, textSecondary),
                  const SizedBox(width: 8),
                  _buildFilterChip('bypassed', 'Bypassed ($bypassedCount)', isDark, cardBg, cardBorder, textSecondary),
                  const SizedBox(width: 8),
                  _buildFilterChip('user', 'User Apps', isDark, cardBg, cardBorder, textSecondary),
                  const SizedBox(width: 8),
                  _buildFilterChip('system', 'System Apps', isDark, cardBg, cardBorder, textSecondary),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // List of Installed Applications
            Expanded(
              child: vpn.isLoadingApps
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : filteredApps.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty ? 'No applications match "$_searchQuery"' : 'No applications found',
                            style: TextStyle(color: textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: app.isBypassed ? AppColors.primaryCyan.withValues(alpha: 0.5) : cardBorder,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  padding: app.iconBytes != null ? EdgeInsets.zero : const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: app.isBypassed
                                        ? AppColors.primaryCyan.withValues(alpha: 0.15)
                                        : surfaceLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: app.iconBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            app.iconBytes!,
                                            width: 42,
                                            height: 42,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              app.isSystemApp ? Icons.settings_applications_rounded : Icons.android_rounded,
                                              color: app.isBypassed ? AppColors.primaryCyan : AppColors.primaryEmerald,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          app.isSystemApp ? Icons.settings_applications_rounded : Icons.android_rounded,
                                          color: app.isBypassed ? AppColors.primaryCyan : AppColors.primaryEmerald,
                                          size: 20,
                                        ),
                                ),
                                title: Text(
                                  app.name,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  app.packageName,
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Switch(
                                  value: app.isBypassed,
                                  activeThumbColor: AppColors.primaryCyan,
                                  activeTrackColor: AppColors.primaryCyan.withValues(alpha: 0.3),
                                  onChanged: (val) {
                                    vpn.toggleAppBypass(app.packageName, val);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String filterId,
    String label,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textSecondary,
  ) {
    final isSelected = _activeFilter == filterId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryCyan.withValues(alpha: 0.2) : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryCyan : textSecondary,
          ),
        ),
      ),
    );
  }
}
