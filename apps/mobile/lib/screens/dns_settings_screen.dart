import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/dns_option.dart';
import '../providers/vpn_provider.dart';

class DnsSettingsScreen extends StatefulWidget {
  const DnsSettingsScreen({super.key});

  @override
  State<DnsSettingsScreen> createState() => _DnsSettingsScreenState();
}

class _DnsSettingsScreenState extends State<DnsSettingsScreen> {
  late TextEditingController _primaryController;
  late TextEditingController _secondaryController;

  @override
  void initState() {
    super.initState();
    final vpn = context.read<VpnProvider>();
    _primaryController = TextEditingController(text: vpn.customPrimaryDns);
    _secondaryController = TextEditingController(text: vpn.customSecondaryDns);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final inputBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CUSTOM DNS SETTINGS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppColors.primaryEmerald, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DNS Resolver Protection',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose the upstream DNS provider to resolve domain names and block malicious domains.',
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

            const SizedBox(height: 20),

            // DNS Preset Options
            ...DnsOption.presetOptions.map((option) {
              final isSelected = vpn.selectedDnsId == option.id;
              final isCustom = option.id == 'custom';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryEmerald : cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        vpn.selectDnsOption(option.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: option.id,
                              groupValue: vpn.selectedDnsId,
                              activeColor: AppColors.primaryEmerald,
                              onChanged: (val) {
                                if (val != null) vpn.selectDnsOption(val);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        option.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryEmerald,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                  if (option.servers.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Servers: ${option.servers.join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: AppColors.primaryCyan,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // If Custom is selected, show Input Fields
                    if (isCustom && isSelected) ...[
                      Divider(height: 1, color: cardBorder),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIMARY DNS SERVER (IPV4)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _primaryController,
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'e.g. 1.1.1.1',
                                hintStyle: TextStyle(color: textMuted),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.primaryEmerald),
                                ),
                              ),
                              onChanged: (val) {
                                vpn.setCustomDns(primary: val, secondary: _secondaryController.text);
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'SECONDARY DNS SERVER (OPTIONAL)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _secondaryController,
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'e.g. 1.0.0.1',
                                hintStyle: TextStyle(color: textMuted),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.primaryEmerald),
                                ),
                              ),
                              onChanged: (val) {
                                vpn.setCustomDns(primary: _primaryController.text, secondary: val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

