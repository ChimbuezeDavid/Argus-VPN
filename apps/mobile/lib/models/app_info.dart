import 'dart:typed_data';

class AppInfo {
  final String name;
  final String packageName;
  final bool isSystemApp;
  final bool isBypassed; // True = bypasses VPN
  final Uint8List? iconBytes;

  const AppInfo({
    required this.name,
    required this.packageName,
    required this.isSystemApp,
    this.isBypassed = false,
    this.iconBytes,
  });

  AppInfo copyWith({bool? isBypassed}) {
    return AppInfo(
      name: name,
      packageName: packageName,
      isSystemApp: isSystemApp,
      isBypassed: isBypassed ?? this.isBypassed,
      iconBytes: iconBytes,
    );
  }

  factory AppInfo.fromMap(Map<dynamic, dynamic> map, {bool isBypassed = false}) {
    return AppInfo(
      name: map['name'] as String? ?? 'Unknown App',
      packageName: map['packageName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isBypassed: isBypassed,
      iconBytes: map['icon'] as Uint8List?,
    );
  }
}
