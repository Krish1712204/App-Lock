// Makes the README screenshots from the real screens, with demo data.
//
// Run:  flutter test tool/screenshots/screenshots_test.dart --update-goldens
// Then: python tool/screenshots/round_corners.py
//
// It lives in tool/ (not test/), so a normal `flutter test` skips it.

import 'package:applock/data/app_info.dart';
import 'package:applock/lock/lock_controller.dart';
import 'package:applock/routes.dart';
import 'package:applock/services/pin_store.dart';
import 'package:applock/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

/// Pretends a fingerprint is saved, and never shows a popup.
class _FakeLocalAuth extends LocalAuthPlatform {
  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => [BiometricType.strong];
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<bool> deviceSupportsBiometrics() async => true;
}

// Demo apps (letter tiles, no real icons).
const _apps = [
  'WhatsApp:com.whatsapp', 'Instagram:com.instagram.android', 'Photos:com.google.android.apps.photos',
  'Gmail:com.google.android.gm', 'Chrome:com.android.chrome', 'Maps:com.google.android.apps.maps',
  'Spotify:com.spotify.music', 'Telegram:org.telegram.messenger', 'YouTube:com.google.android.youtube',
  'Netflix:com.netflix.mediaclient', 'Drive:com.google.android.apps.docs',
];
const _locked = ['com.whatsapp', 'com.instagram.android', 'com.google.android.apps.photos', 'com.google.android.gm'];

Future<void> _loadFonts() async {
  final fonts = {
    'Inter': ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold'],
    'SpaceGrotesk': ['SpaceGrotesk-Medium', 'SpaceGrotesk-SemiBold', 'SpaceGrotesk-Bold'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }
}

void _mockNative() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('app_lock/native'),
    (call) async => switch (call.method) {
      'getInstalledApps' => [
          for (final a in _apps) {'name': a.split(':')[0], 'packageName': a.split(':')[1]},
        ],
      'getLockedApps' => _locked,
      'isProtectionOn' => true,
      'getSettings' => <String, Object?>{'relockSeconds': 60},
      'getPermissions' => {'accessibility': true, 'watcherRunning': true, 'overlay': true, 'battery': false},
      _ => null,
    },
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    LocalAuthPlatform.instance = _FakeLocalAuth();
  });

  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member (this IS a test, just outside test/)
    FlutterSecureStorage.setMockInitialValues({});
    _mockNative();
    // Like the real lock, but the fingerprint popup never opens
    // (it only opens once the lock window is "resumed").
    LockController.isRealLock = true;
    LockController.activityResumed.value = false;
    LockController.fingerprintEnabled = true;
  });

  for (final dark in [true, false]) {
    final theme = dark ? 'dark' : 'light';

    Future<void> show(WidgetTester tester, String route, {Object? args}) async {
      // 390 x 844 like the design files, at 3x for sharp images.
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      // Room for the status bar (top) and gesture bar (bottom), like a phone.
      tester.view.padding = const FakeViewPadding(top: 40 * 3, bottom: 16 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 40 * 3, bottom: 16 * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        onGenerateInitialRoutes: (_) => [onGenerateRoute(RouteSettings(name: route, arguments: args))],
        onGenerateRoute: onGenerateRoute,
      ));
      await _settle(tester);
    }

    Future<void> shoot(WidgetTester tester, String name) =>
        expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$theme-$name.png'));

    testWidgets('$theme welcome', (tester) async {
      await show(tester, Routes.welcome);
      await shoot(tester, 'welcome');
    });

    testWidgets('$theme set pin', (tester) async {
      await show(tester, Routes.setPin);
      for (final d in ['2', '5', '8']) {
        await tester.tap(find.text(d));
      }
      await _settle(tester);
      await shoot(tester, 'set-pin');
    });

    testWidgets('$theme permissions', (tester) async {
      await show(tester, Routes.permissions);
      await shoot(tester, 'permissions');
    });

    testWidgets('$theme home', (tester) async {
      await show(tester, Routes.home);
      await shoot(tester, 'home');
    });

    testWidgets('$theme lock', (tester) async {
      await show(tester, Routes.lock, args: _whatsApp);
      await shoot(tester, 'lock');
    });

    testWidgets('$theme lock pin', (tester) async {
      // Save PIN 2580 and leave 4 tries, so one wrong PIN shows "3 tries left".
      await tester.runAsync(() async {
        await PinStore.instance.savePin('2580');
        await const FlutterSecureStorage().write(key: 'pin_tries_left', value: '4');
      });
      await show(tester, Routes.lockPin, args: _whatsApp);
      for (final d in ['1', '1', '1', '1']) {
        await tester.tap(find.text(d));
      }
      // The PIN check runs in a background isolate: give it real time.
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await _settle(tester);
      await shoot(tester, 'lock-pin');
    });

    testWidgets('$theme settings', (tester) async {
      await show(tester, Routes.settings);
      await shoot(tester, 'settings');
    });
  }
}

const _whatsApp = AppInfo(packageName: 'com.whatsapp', name: 'WhatsApp');

/// Pumps frames (with a little real time for async loads) without waiting
/// for the never-ending pulse animation to stop.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}
