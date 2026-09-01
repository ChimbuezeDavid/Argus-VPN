class ArgusShieldSettings {
  final bool blockMalware;
  final bool blockAdsAndTrackers;
  final bool blockAdultContent;
  final bool blockGambling;
  final bool blockSocialMedia;
  final bool macAddressMasking;
  final bool decoyTraffic;
  final bool stealthMode;
  final bool localLanAccess;
  final int packetMtu;
  final bool autoSecureUntrustedWifi;
  final List<String> trustedWifiNetworks;

  const ArgusShieldSettings({
    this.blockMalware = true,
    this.blockAdsAndTrackers = true,
    this.blockAdultContent = false,
    this.blockGambling = false,
    this.blockSocialMedia = false,
    this.macAddressMasking = true,
    this.decoyTraffic = false,
    this.stealthMode = false,
    this.localLanAccess = true,
    this.packetMtu = 1420,
    this.autoSecureUntrustedWifi = true,
    this.trustedWifiNetworks = const [],
  });

  ArgusShieldSettings copyWith({
    bool? blockMalware,
    bool? blockAdsAndTrackers,
    bool? blockAdultContent,
    bool? blockGambling,
    bool? blockSocialMedia,
    bool? macAddressMasking,
    bool? decoyTraffic,
    bool? stealthMode,
    bool? localLanAccess,
    int? packetMtu,
    bool? autoSecureUntrustedWifi,
    List<String>? trustedWifiNetworks,
  }) {
    return ArgusShieldSettings(
      blockMalware: blockMalware ?? this.blockMalware,
      blockAdsAndTrackers: blockAdsAndTrackers ?? this.blockAdsAndTrackers,
      blockAdultContent: blockAdultContent ?? this.blockAdultContent,
      blockGambling: blockGambling ?? this.blockGambling,
      blockSocialMedia: blockSocialMedia ?? this.blockSocialMedia,
      macAddressMasking: macAddressMasking ?? this.macAddressMasking,
      decoyTraffic: decoyTraffic ?? this.decoyTraffic,
      stealthMode: stealthMode ?? this.stealthMode,
      localLanAccess: localLanAccess ?? this.localLanAccess,
      packetMtu: packetMtu ?? this.packetMtu,
      autoSecureUntrustedWifi: autoSecureUntrustedWifi ?? this.autoSecureUntrustedWifi,
      trustedWifiNetworks: trustedWifiNetworks ?? this.trustedWifiNetworks,
    );
  }

  factory ArgusShieldSettings.fromJson(Map<String, dynamic> json) {
    return ArgusShieldSettings(
      blockMalware: json['blockMalware'] as bool? ?? true,
      blockAdsAndTrackers: json['blockAdsAndTrackers'] as bool? ?? true,
      blockAdultContent: json['blockAdultContent'] as bool? ?? false,
      blockGambling: json['blockGambling'] as bool? ?? false,
      blockSocialMedia: json['blockSocialMedia'] as bool? ?? false,
      macAddressMasking: json['macAddressMasking'] as bool? ?? true,
      decoyTraffic: json['decoyTraffic'] as bool? ?? false,
      stealthMode: json['stealthMode'] as bool? ?? false,
      localLanAccess: json['localLanAccess'] as bool? ?? true,
      packetMtu: json['packetMtu'] as int? ?? 1420,
      autoSecureUntrustedWifi: json['autoSecureUntrustedWifi'] as bool? ?? true,
      trustedWifiNetworks: (json['trustedWifiNetworks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockMalware': blockMalware,
      'blockAdsAndTrackers': blockAdsAndTrackers,
      'blockAdultContent': blockAdultContent,
      'blockGambling': blockGambling,
      'blockSocialMedia': blockSocialMedia,
      'macAddressMasking': macAddressMasking,
      'decoyTraffic': decoyTraffic,
      'stealthMode': stealthMode,
      'localLanAccess': localLanAccess,
      'packetMtu': packetMtu,
      'autoSecureUntrustedWifi': autoSecureUntrustedWifi,
      'trustedWifiNetworks': trustedWifiNetworks,
    };
  }
}
