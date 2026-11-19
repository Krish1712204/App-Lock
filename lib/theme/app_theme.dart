import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font family names. They must match the `family:` names in pubspec.yaml.
class AppFonts {
  static const body = 'Inter';
  static const heading = 'SpaceGrotesk';
}

/// Small helpers so text styles stay short in the screens.
/// Sizes are in "logical pixels", which match the px values in the designs.
class AppText {
  /// Space Grotesk: titles and keypad numbers.
  static TextStyle heading(
    double size, {
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 0,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: AppFonts.heading,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  /// Inter: everything else.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: AppFonts.body,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}

/// Builds the light and dark ThemeData. main.dart passes both to MaterialApp,
/// and `themeMode: ThemeMode.system` picks one based on the phone's setting.
class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.background,
      onSurface: c.text,
      error: c.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: AppFonts.body,
      extensions: [c], // makes `context.colors` work
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.3),
        selectionHandleColor: c.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surface2,
        contentTextStyle: AppText.body(14, color: c.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
