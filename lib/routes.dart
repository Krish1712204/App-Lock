import 'package:flutter/material.dart';

import 'data/fake_data.dart';
import 'screens/home_screen.dart';
import 'screens/lock_pin_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/set_pin_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';

/// Names of all screens. Use them like:
///   Navigator.pushNamed(context, Routes.settings);
class Routes {
  static const welcome = '/';
  static const setPin = '/set-pin';
  static const permissions = '/permissions';
  static const home = '/home';
  static const settings = '/settings';
  static const lock = '/lock';
  static const lockPin = '/lock-pin';
}

/// Turns a route name (and optional arguments) into a screen.
/// MaterialApp calls this every time we navigate.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  // The two lock screens need to know which app is locked.
  // In Phase 1 we fall back to WhatsApp, like the design.
  final app = settings.arguments is FakeApp ? settings.arguments as FakeApp : fakeApps.first;

  final Widget screen = switch (settings.name) {
    Routes.setPin => SetPinScreen(changing: settings.arguments == SetPinScreen.changeMode),
    Routes.permissions => const PermissionsScreen(),
    Routes.home => const HomeScreen(),
    Routes.settings => const SettingsScreen(),
    Routes.lock => LockScreen(app: app),
    Routes.lockPin => LockPinScreen(app: app),
    _ => const WelcomeScreen(),
  };

  return MaterialPageRoute(builder: (_) => screen, settings: settings);
}
