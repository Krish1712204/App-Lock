import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../routes.dart';
import '../services/lock_channel.dart';
import '../theme/app_theme.dart';
import 'lock_controller.dart';

/// The whole app inside the lock engine. It shows ONLY the lock screens.
///
/// It starts in the background (pre-warmed) and waits. When Kotlin says
/// "showLock" for an app, it builds a fresh lock screen for that app.
class LockApp extends StatefulWidget {
  const LockApp({super.key});

  @override
  State<LockApp> createState() => _LockAppState();
}

class _LockAppState extends State<LockApp> {
  AppInfo? _app; // the app being locked (null = nothing to show yet)
  int _lockNumber = 0; // goes up for every new lock request

  @override
  void initState() {
    super.initState();
    LockChannel.listen(
      onShowLock: _show,
      onResumedChanged: (resumed) => LockController.activityResumed.value = resumed,
    );
    // In case Kotlin asked before we were listening.
    LockChannel.currentLock().then((lock) {
      if (lock != null && mounted && _app == null) _show(lock.$1, lock.$2);
    });
  }

  void _show(AppInfo app, bool fingerprint) {
    LockController.fingerprintEnabled = fingerprint;
    setState(() {
      _app = app;
      // A new number = a new key below = Flutter throws away the old lock
      // screen (half-typed PIN, error message...) and starts clean.
      _lockNumber++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    return MaterialApp(
      key: ValueKey(_lockNumber),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      onGenerateInitialRoutes: (_) => [
        app == null
            // Nothing to lock yet: an empty page in our background color.
            ? MaterialPageRoute<void>(builder: (_) => const Scaffold())
            // Fingerprint off in Settings → straight to the PIN pad.
            : onGenerateRoute(RouteSettings(
                name: LockController.fingerprintEnabled ? Routes.lock : Routes.lockPin,
                arguments: app,
              )),
      ],
      onGenerateRoute: onGenerateRoute,
    );
  }
}
