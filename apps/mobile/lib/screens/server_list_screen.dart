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
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
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
      appBar: AppBar(
        title: const Text(
          'SERVER LOCATIONS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0),
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
            tooltip: 'Refresh Latencies',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: TextField(
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search 35+ locations or countries...',
                  hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
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

            // Regional Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _regions.map((region) {
                    final isSelected = _selectedRegion == region;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(region),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: cardBg,
                        selectedColor: AppColors.primaryEmerald,
                        checkmarkColor: Colors.black,
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryEmerald : cardBorder,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (_) {
                          setState(() {
                            _selectedRegion = region;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Windscribe-Style Country Accordions List
            Expanded(
              child: vpn.isLoadingServers
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : ListView.builder(
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
                              color: isAnyNodeSelected ? AppColors.primaryEmerald : cardBorder,
                              width: isAnyNodeSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: isAnyNodeSelected || _searchQuery.isNotEmpty,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Text(flag, style: const TextStyle(fontSize: 26)),
                              title: Text(
                                country,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${countryServers.length} ${countryServers.length == 1 ? "Location" : "Locations"}',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.bolt_rounded, size: 13, color: pingColor),
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

                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: cardBorder.withValues(alpha: 0.5)),
                                    ),
                                    color: isSelected
                                        ? AppColors.primaryEmerald.withValues(alpha: isDark ? 0.15 : 0.08)
                                        : Colors.transparent,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                    title: Text(
                                      server.location.city,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? AppColors.primaryEmerald : textPrimary,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(Icons.signal_cellular_alt_rounded, size: 13, color: serverPingColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${server.pingMs} ms',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: serverPingColor),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Load ${server.currentLoadPercentage}%',
                                          style: TextStyle(fontSize: 10, color: textSecondary),
                                        ),
                                        const SizedBox(width: 8),
                                        if (server.tierRequired == 'PRO')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentPurple.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'PRO',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.accentPurple),
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
