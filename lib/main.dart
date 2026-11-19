import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'routes.dart';
import 'services/pin_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status bar and gesture bar (Android 15 does this anyway).
  // Each screen uses SafeArea to keep its content clear of them.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // If a PIN was already set up, skip the Welcome/setup screens.
  final setupDone = await PinStore.instance.hasPin();

  runApp(AppLockApp(startAtHome: setupDone));
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
