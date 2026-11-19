// Pretend state that Phase 6 will make real (the Settings switches).
// Already real: the PIN (Phase 2, services/pin_store.dart), the apps +
// locked list (Phase 3, services/native_bridge.dart) and the permissions
// (Phase 5, services/permissions_service.dart).

/// Choices for "Lock again after".
enum RelockDelay {
  now('Right away'),
  oneMinute('1 min'),
  fiveMinutes('5 min');

  const RelockDelay(this.label);
  final String label;
}

/// Holds the remaining pretend state in memory while the app is open.
/// Everything here resets when the app is closed.
class FakeStore {
  FakeStore._();
  static final instance = FakeStore._(); // one shared copy for all screens

  // Settings screen (saved for real: Phase 6)
  bool fingerprintUnlock = true;
  RelockDelay relockDelay = RelockDelay.now;
  bool lockOnScreenOff = true;
  bool lockSettingsAndStore = true;
  bool hideRecentsPreview = true;
}
