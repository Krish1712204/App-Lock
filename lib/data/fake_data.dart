import 'package:flutter/material.dart';

// PHASE 1 ONLY: pretend data, so every screen can be tried out.
// Later phases replace this with real storage and real installed apps.

/// One app in the Home list.
class FakeApp {
  const FakeApp(this.id, this.name, this.color);

  final String id;
  final String name;
  final Color color; // tile color (real app icons come in Phase 3)

  String get letter => name.substring(0, 1);
}

/// The 12 apps from design/Home.html, with the same tile colors.
const fakeApps = <FakeApp>[
  FakeApp('whatsapp', 'WhatsApp', Color(0xFF2F7D55)),
  FakeApp('gallery', 'Gallery', Color(0xFF9C5B1E)),
  FakeApp('instagram', 'Instagram', Color(0xFFA63D6B)),
  FakeApp('gpay', 'Google Pay', Color(0xFF2B5FA8)),
  FakeApp('phonepe', 'PhonePe', Color(0xFF5B3FA6)),
  FakeApp('settings', 'Settings', Color(0xFF4A5361)),
  FakeApp('gmail', 'Gmail', Color(0xFFA83A32)),
  FakeApp('telegram', 'Telegram', Color(0xFF24719C)),
  FakeApp('files', 'Files', Color(0xFF2D6E6A)),
  FakeApp('chrome', 'Chrome', Color(0xFF8A6A14)),
  FakeApp('youtube', 'YouTube', Color(0xFFA33030)),
  FakeApp('messages', 'Messages', Color(0xFF3A5A9C)),
];

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
/// (The PIN is real since Phase 2: see services/pin_store.dart.)
class FakeStore {
  FakeStore._();
  static final instance = FakeStore._(); // one shared copy for all screens

  // Home (real apps + saving: Phase 3)
  bool protectionOn = true;
  final Set<String> lockedIds = {
    'whatsapp', 'gallery', 'instagram', 'gpay', 'phonepe', 'settings',
  };

  // Permissions screen (real checks: Phase 5)
  bool accessibilityAllowed = true;
  bool overlayAllowed = true;
  bool fingerprintAllowed = false;
  bool batteryAllowed = false;

  // Settings screen (saved for real: Phase 6)
  bool fingerprintUnlock = true;
  RelockDelay relockDelay = RelockDelay.now;
  bool lockOnScreenOff = true;
  bool lockSettingsAndStore = true;
  bool hideRecentsPreview = true;
}
