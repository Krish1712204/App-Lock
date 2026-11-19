import 'package:flutter/services.dart';

import '../data/app_info.dart';

/// The Dart side of the MethodChannel "app_lock/native".
/// Each method here calls the matching branch in NativeChannel.kt.
class NativeBridge {
  static const _channel = MethodChannel('app_lock/native');

  // Keep the app list in memory after the first load, so going back to
  // Home is instant. (Install a new app? Pull down on Home to refresh.)
  static List<AppInfo>? _appsCache;

  /// All apps with an icon in the app drawer, sorted A→Z.
  static Future<List<AppInfo>> getInstalledApps({bool refresh = false}) async {
    if (_appsCache != null && !refresh) return _appsCache!;
    final raw = await _channel.invokeListMethod<Object?>('getInstalledApps') ?? const [];
    final apps = [for (final item in raw) AppInfo.fromMap(item as Map<Object?, Object?>)]
      ..sort(AppInfo.byName);
    return _appsCache = apps;
  }

  /// Package names of the locked apps (saved in Kotlin's SharedPreferences).
  static Future<Set<String>> getLockedApps() async {
    final list = await _channel.invokeListMethod<String>('getLockedApps') ?? const [];
    return list.toSet();
  }

  static Future<void> setLockedApps(Set<String> packages) =>
      _channel.invokeMethod('setLockedApps', {'packages': packages.toList()});

  /// The master switch on Home.
  static Future<bool> isProtectionOn() async =>
      await _channel.invokeMethod<bool>('isProtectionOn') ?? true;

  static Future<void> setProtectionOn(bool on) =>
      _channel.invokeMethod('setProtectionOn', {'on': on});

  /// Real permission status from Kotlin (PermissionsHelper.kt):
  /// accessibility, watcherRunning, overlay, battery → true/false.
  static Future<Map<String, bool>> getPermissions() async {
    final map = await _channel.invokeMapMethod<String, bool>('getPermissions');
    return map ?? const {};
  }

  /// Opens Android's settings page for one permission
  /// ("accessibility", "overlay", "fingerprint", "battery" or "appInfo").
  static Future<void> openPermission(String name) =>
      _channel.invokeMethod('openPermission', {'name': name});
}
