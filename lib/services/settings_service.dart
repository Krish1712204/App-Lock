import 'native_bridge.dart';

/// Choices for "Lock again after" (seconds are what Kotlin stores).
enum RelockDelay {
  now(0, 'Right away'),
  oneMinute(60, '1 min'),
  fiveMinutes(300, '5 min');

  const RelockDelay(this.seconds, this.label);
  final int seconds;
  final String label;

  static RelockDelay fromSeconds(int s) =>
      values.firstWhere((d) => d.seconds == s, orElse: () => RelockDelay.now);
}

/// All settings, as saved in Kotlin (SettingsStore.kt).
class AppSettings {
  const AppSettings({
    this.fingerprintUnlock = true,
    this.relockDelay = RelockDelay.now,
    this.lockOnScreenOff = true,
    this.lockSystemApps = false,
    this.hideRecents = true,
  });

  factory AppSettings.fromMap(Map<String, Object?> m) => AppSettings(
        fingerprintUnlock: m[SettingsKeys.fingerprint] as bool? ?? true,
        relockDelay: RelockDelay.fromSeconds(m[SettingsKeys.relockSeconds] as int? ?? 0),
        lockOnScreenOff: m[SettingsKeys.lockOnScreenOff] as bool? ?? true,
        lockSystemApps: m[SettingsKeys.lockSystemApps] as bool? ?? false,
        hideRecents: m[SettingsKeys.hideRecents] as bool? ?? true,
      );

  final bool fingerprintUnlock;
  final RelockDelay relockDelay;
  final bool lockOnScreenOff;
  final bool lockSystemApps; // "Lock Settings & Play Store"
  final bool hideRecents; // "Hide previews in Recent apps"
}

/// The key names. They must match the constants in SettingsStore.kt.
class SettingsKeys {
  static const fingerprint = 'fingerprintUnlock';
  static const relockSeconds = 'relockSeconds';
  static const lockOnScreenOff = 'lockOnScreenOff';
  static const lockSystemApps = 'lockSystemApps';
  static const hideRecents = 'hideRecents';
}

class SettingsService {
  static Future<AppSettings> load() async => AppSettings.fromMap(await NativeBridge.getSettings());

  /// Saves one setting (value must be a bool or an int).
  static Future<void> set(String key, Object value) => NativeBridge.setSetting(key, value);
}
