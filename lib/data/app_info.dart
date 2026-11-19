import 'package:flutter/services.dart';

/// One installed app, as sent from Kotlin (InstalledApps.kt).
class AppInfo {
  const AppInfo({required this.packageName, required this.name, this.icon});

  /// Builds an AppInfo from the map Kotlin sends over the MethodChannel:
  /// `{"packageName": "com.whatsapp", "name": "WhatsApp", "icon": <PNG bytes>}`
  factory AppInfo.fromMap(Map<Object?, Object?> map) {
    final packageName = map['packageName'] as String;
    final name = (map['name'] as String?)?.trim();
    return AppInfo(
      packageName: packageName,
      name: (name == null || name.isEmpty) ? packageName : name,
      icon: map['icon'] as Uint8List?,
    );
  }

  final String packageName; // unique id, e.g. "com.whatsapp"
  final String name; // what you see, e.g. "WhatsApp"
  final Uint8List? icon; // PNG image, or null if there's none

  String get letter => name.substring(0, 1).toUpperCase();

  /// A stable tile color for apps without an icon (picked from the
  /// design's palette, based on the package name).
  Color get fallbackColor => _palette[packageName.hashCode.abs() % _palette.length];

  static const _palette = [
    Color(0xFF2F7D55), Color(0xFF9C5B1E), Color(0xFFA63D6B), Color(0xFF2B5FA8),
    Color(0xFF5B3FA6), Color(0xFF4A5361), Color(0xFFA83A32), Color(0xFF24719C),
  ];

  /// Sort apps A→Z by name, ignoring upper/lower case.
  static int byName(AppInfo a, AppInfo b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
