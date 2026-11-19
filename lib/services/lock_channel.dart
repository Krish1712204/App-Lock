import 'package:flutter/services.dart';

import '../data/app_info.dart';

/// The Dart side of the lock engine's channel "app_lock/lock"
/// (Kotlin side: LockEngine.kt). Only used inside the lock engine.
class LockChannel {
  static const _channel = MethodChannel('app_lock/lock');

  /// Start listening for messages from Kotlin.
  /// - showLock: a locked app was opened, show the lock for [AppInfo].
  /// - resumed / paused: LockActivity came on screen / went away.
  static void listen({
    required void Function(AppInfo app) onShowLock,
    required void Function(bool resumed) onResumedChanged,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'showLock':
          onShowLock(AppInfo.fromMap(call.arguments as Map<Object?, Object?>));
        case 'resumed':
          onResumedChanged(true);
        case 'paused':
          onResumedChanged(false);
      }
      return null;
    });
  }

  /// The app being locked right now, if any. Used once at start-up, in case
  /// Kotlin sent "showLock" before Dart was listening.
  static Future<AppInfo?> currentLock() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('currentLock');
    return map == null ? null : AppInfo.fromMap(map);
  }

  /// Fingerprint/PIN was right: Kotlin remembers it and closes the lock.
  static Future<void> unlocked(String packageName) =>
      _channel.invokeMethod('unlocked', {'packageName': packageName});

  /// Back was pressed: Kotlin shows the phone's home screen.
  static Future<void> goHome() => _channel.invokeMethod('goHome');
}
