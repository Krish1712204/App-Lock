import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lock/lock_app.dart';
import 'lock/lock_controller.dart';
import 'routes.dart';
import 'services/pin_store.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status bar and gesture bar (Android 15 does this anyway).
  // Each screen uses SafeArea to keep its content clear of them.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // If a PIN was already set up, skip the Welcome/setup screens.
  final setupDone = await PinStore.instance.hasPin();
  if (setupDone) {
    try {
      // Tell Kotlin a PIN exists (so App Lock locks itself), and read the
      // fingerprint setting for the lock preview.
      await SettingsService.set(SettingsKeys.setupDone, true);
      LockController.fingerprintEnabled = (await SettingsService.load()).fingerprintUnlock;
    } catch (_) {
      // Kotlin not reachable (shouldn't happen): keep the defaults.
    }
  }

  runApp(AppLockApp(startAtHome: setupDone));
}

/// The SECOND entry point, used only by the pre-warmed lock engine
/// (LockEngine.kt runs it by name). It shows just the lock screens.
///
/// @pragma('vm:entry-point') tells the Dart compiler to keep this function
/// even though no Dart code calls it (only Kotlin does).
@pragma('vm:entry-point')
void lockMain() {
  WidgetsFlutterBinding.ensureInitialized();
  LockController.isRealLock = true;
  runApp(const LockApp());
}

class AppLockApp extends StatelessWidget {
  const AppLockApp({super.key, this.startAtHome = false});

  final bool startAtHome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Lock',
      debugShowCheckedModeBanner: false,
      // Follow the phone's dark/light setting.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // Open exactly ONE first screen. (With a plain initialRoute of '/home',
      // Flutter would also put Welcome ('/') underneath it, and Back on Home
      // would go to Welcome.)
      onGenerateInitialRoutes: (_) => [
        onGenerateRoute(RouteSettings(name: startAtHome ? Routes.home : Routes.welcome)),
      ],
      onGenerateRoute: onGenerateRoute,
      // Make the status bar and gesture bar transparent, with icons that
      // are readable on our background (light icons on dark, and vice versa).
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final style = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(value: style, child: child!);
      },
    );
  }
}
