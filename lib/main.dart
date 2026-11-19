import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'routes.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status bar and gesture bar (Android 15 does this anyway).
  // Each screen uses SafeArea to keep its content clear of them.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const AppLockApp());
}

class AppLockApp extends StatelessWidget {
  const AppLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Lock',
      debugShowCheckedModeBanner: false,
      // Follow the phone's dark/light setting.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: Routes.welcome,
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
