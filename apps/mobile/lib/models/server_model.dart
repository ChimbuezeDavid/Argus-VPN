class ServerLocation {
  final String city;
  final String country;
  final String countryCode;
  final String region;
  final double? latitude;
  final double? longitude;

  const ServerLocation({
    required this.city,
    required this.country,
    required this.countryCode,
    this.region = 'Europe',
    this.latitude,
    this.longitude,
  });

  factory ServerLocation.fromJson(Map<String, dynamic> json) {
    return ServerLocation(
      city: json['city'] as String,
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
      region: json['region'] as String? ?? 'Europe',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class ServerNode {
  final String id;
  final String hostname;
  final ServerLocation location;
  final String publicIp;
  final int wireguardPort;
  final String publicKey;
  final int currentLoadPercentage;
  final String tierRequired;
  final int pingMs;

  const ServerNode({
    required this.id,
    required this.hostname,
    required this.location,
    required this.publicIp,
    required this.wireguardPort,
    required this.publicKey,
    required this.currentLoadPercentage,
    required this.tierRequired,
    this.pingMs = 42,
  });

  factory ServerNode.fromJson(Map<String, dynamic> json) {
    return ServerNode(
      id: json['id'] as String,
      hostname: json['hostname'] as String,
      location: ServerLocation.fromJson(json['location'] as Map<String, dynamic>),
      publicIp: json['publicIp'] as String,
      wireguardPort: json['wireguardPort'] as int,
      publicKey: json['publicKey'] as String,
      currentLoadPercentage: json['currentLoadPercentage'] as int? ?? 15,
      tierRequired: json['tierRequired'] as String? ?? 'FREE',
      pingMs: (json['id'].toString().hashCode % 50).abs() + 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostname': hostname,
      'location': {
        'city': location.city,
        'country': location.country,
        'countryCode': location.countryCode,
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'publicIp': publicIp,
      'wireguardPort': wireguardPort,
      'publicKey': publicKey,
      'currentLoadPercentage': currentLoadPercentage,
      'tierRequired': tierRequired,
      'pingMs': pingMs,
    };
  }

  ServerNode copyWith({
    String? id,
    String? hostname,
    ServerLocation? location,
    String? publicIp,
    int? wireguardPort,
    String? publicKey,
    int? currentLoadPercentage,
    String? tierRequired,
    int? pingMs,
  }) {
    return ServerNode(
      id: id ?? this.id,
      hostname: hostname ?? this.hostname,
      location: location ?? this.location,
      publicIp: publicIp ?? this.publicIp,
      wireguardPort: wireguardPort ?? this.wireguardPort,
      publicKey: publicKey ?? this.publicKey,
      currentLoadPercentage: currentLoadPercentage ?? this.currentLoadPercentage,
      tierRequired: tierRequired ?? this.tierRequired,
      pingMs: pingMs ?? this.pingMs,
    );
  }

  String get flagEmoji {
    final country = location.countryCode.toUpperCase();
    if (country.length != 2) return '🌐';
    final int firstLetter = country.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = country.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
