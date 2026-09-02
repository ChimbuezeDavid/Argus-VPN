import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/server_model.dart';
import '../providers/vpn_provider.dart';
import 'auth_screen.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRegion = 'All';

  final List<String> _regions = ['All', 'Europe', 'Americas', 'Asia-Pacific', 'Middle East', 'Africa'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VpnProvider>().pingAllServers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBgLight = isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Filter servers based on search and region
    final filteredServers = vpn.servers.where((s) {
      final matchesQuery = _searchQuery.isEmpty ||
          s.location.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.location.country.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRegion = _selectedRegion == 'All' || s.location.region == _selectedRegion;

      return matchesQuery && matchesRegion;
    }).toList();

    // Group servers by country (Windscribe hierarchy)
    final Map<String, List<ServerNode>> groupedByCountry = {};
    for (final server in filteredServers) {
      groupedByCountry.putIfAbsent(server.location.country, () => []).add(server);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Server Locations',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
        actions: [
          IconButton(
            onPressed: vpn.isPingingServers ? null : () => vpn.pingAllServers(),
            icon: vpn.isPingingServers
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryEmerald),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Ping',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search country or city...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),

            // Regional Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _regions.map((region) {
                    final isSelected = _selectedRegion == region;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedRegion = region),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryEmerald
                                : cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryEmerald : cardBorder,
                            ),
                          ),
                          child: Text(
                            region,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Country Accordions List
            Expanded(
              child: vpn.isLoadingServers
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: groupedByCountry.keys.length,
                      itemBuilder: (context, index) {
                        final country = groupedByCountry.keys.elementAt(index);
                        final countryServers = groupedByCountry[country]!;
                        final flag = countryServers.first.flagEmoji;

                        // Find lowest ping among country nodes
                        int bestPing = 999;
                        for (final s in countryServers) {
                          if (s.pingMs < bestPing) bestPing = s.pingMs;
                        }

                        Color pingColor;
                        if (bestPing < 80) {
                          pingColor = AppColors.primaryEmerald;
                        } else if (bestPing < 160) {
                          pingColor = AppColors.warningOrange;
                        } else {
                          pingColor = AppColors.alertRed;
                        }

                        final bool isAnyNodeSelected = countryServers.any((s) => s.id == vpn.selectedServer?.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAnyNodeSelected
                                  ? AppColors.primaryEmerald.withValues(alpha: 0.4)
                                  : cardBorder,
                              width: isAnyNodeSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: isAnyNodeSelected || _searchQuery.isNotEmpty,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cardBgLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(flag, style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                              title: Text(
                                country,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    '${countryServers.length} ${countryServers.length == 1 ? "location" : "locations"}',
                                    style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: pingColor),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$bestPing ms',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pingColor),
                                  ),
                                ],
                              ),
                              children: countryServers.map((server) {
                                final isSelected = vpn.selectedServer?.id == server.id;

                                Color serverPingColor;
                                if (server.pingMs < 80) {
                                  serverPingColor = AppColors.primaryEmerald;
                                } else if (server.pingMs < 160) {
                                  serverPingColor = AppColors.warningOrange;
                                } else {
                                  serverPingColor = AppColors.alertRed;
                                }

                                return Material(
                                  color: isSelected
                                      ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.12 : 0.06)
                                      : Colors.transparent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                      title: Text(
                                        server.location.city,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? AppColors.primaryEmerald : textPrimary,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: serverPingColor),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${server.pingMs} ms',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: serverPingColor),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${server.currentLoadPercentage}% load',
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                          const SizedBox(width: 8),
                                          if (server.tierRequired == 'PRO')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryIndigo.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'PRO',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryIndigo),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryEmerald, size: 22)
                                          : Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                                      onTap: () {
                                        if (!vpn.isAuthenticated) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                                          );
                                        } else {
                                          vpn.selectServer(server);
                                          vpn.connect(server: server);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
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
}
