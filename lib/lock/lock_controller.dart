import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../services/lock_channel.dart';

/// The lock screens (lock_screen.dart, lock_pin_screen.dart) are used in
/// two places:
///  1. the PREVIEW, opened from Home inside App Lock (main engine), and
///  2. the REAL lock, inside LockActivity (the pre-warmed lock engine).
/// This class hides the differences, so the screens stay simple.
class LockController {
  /// True only inside the lock engine (set by lockMain() in main.dart).
  static bool isRealLock = false;

  /// Real lock only: true while LockActivity is on screen. The fingerprint
  /// popup can only be opened then.
  static final activityResumed = ValueNotifier<bool>(false);

  /// Fingerprint or PIN was correct.
  static Future<void> unlocked(BuildContext context, AppInfo app) async {
    if (isRealLock) {
      // Kotlin closes LockActivity, and the locked app appears.
      await LockChannel.unlocked(app.packageName);
    } else {
      // Preview: just go back to Home.
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${app.name} unlocked')),
      );
    }
  }

  /// Back was pressed on a lock screen.
  /// Real lock: go to the home screen (never into the locked app).
  static void back() {
    if (isRealLock) LockChannel.goHome();
  }
}
