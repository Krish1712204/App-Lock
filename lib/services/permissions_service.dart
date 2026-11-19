import 'biometric_service.dart';
import 'native_bridge.dart';

/// The 4 things App Lock needs (Permissions screen), plus "App info".
/// The names match the ones PermissionsHelper.kt understands.
enum AppPermission {
  accessibility,
  overlay,
  fingerprint,
  battery,
  appInfo,
}

/// A snapshot of the real permission status.
class PermissionStatus {
  const PermissionStatus({
    required this.accessibility,
    required this.watcherRunning,
    required this.overlay,
    required this.fingerprint,
    required this.battery,
  });

  final bool accessibility; // App Lock is switched on in Accessibility settings
  final bool watcherRunning; // ...and the watcher is actually running now
  final bool overlay; // Display over other apps
  final bool fingerprint; // at least one fingerprint saved on the phone
  final bool battery; // Battery: Unrestricted

  bool isAllowed(AppPermission p) => switch (p) {
        AppPermission.accessibility => accessibility,
        AppPermission.overlay => overlay,
        AppPermission.fingerprint => fingerprint,
        AppPermission.battery => battery,
        AppPermission.appInfo => true,
      };

  /// "N of 4 done" on the Permissions screen.
  int get doneCount => [accessibility, overlay, fingerprint, battery].where((ok) => ok).length;
}

class PermissionsService {
  /// Reads everything at once (Kotlin for 3, local_auth for fingerprint).
  static Future<PermissionStatus> check() async {
    final results = await Future.wait([
      NativeBridge.getPermissions(),
      BiometricService.instance.hasFingerprint(),
    ]);
    final native = results[0] as Map<String, bool>;
    return PermissionStatus(
      accessibility: native['accessibility'] ?? false,
      watcherRunning: native['watcherRunning'] ?? false,
      overlay: native['overlay'] ?? false,
      fingerprint: results[1] as bool,
      battery: native['battery'] ?? false,
    );
  }

  /// Opens the Android settings page where you can allow [p].
  static Future<void> open(AppPermission p) => NativeBridge.openPermission(p.name);
}
