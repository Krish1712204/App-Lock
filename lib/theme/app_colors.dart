import 'package:flutter/material.dart';

/// Every color used in the designs, for one theme (dark or light).
///
/// This is a "ThemeExtension": Flutter keeps it inside the app's ThemeData,
/// so any widget can read the current colors with `context.colors`
/// (see the extension at the bottom of this file). When the phone switches
/// between dark and light mode, every screen redraws with the other set.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.track,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.error,
    required this.switchOff,
    required this.thumbOn,
    required this.thumbOff,
    required this.infoBg,
    required this.segmentTrack,
    required this.segmentSelected,
    required this.cardShadow,
    required this.keyShadow,
    required this.thumbShadow,
    required this.segmentShadow,
  });

  final Color background; // page background
  final Color surface; // cards, keypad keys
  final Color surface2; // icon tiles, disabled button
  final Color border; // card borders, dividers
  final Color borderStrong; // empty PIN dots, outline button, "to do" cards
  final Color track; // empty progress bar, rings around big icons
  final Color text; // main text
  final Color muted; // secondary text
  final Color accent; // teal brand color
  final Color onAccent; // text/icons drawn on top of the accent color
  final Color error; // wrong PIN
  final Color switchOff; // switch track when off
  final Color thumbOn; // switch knob when on
  final Color thumbOff; // switch knob when off
  final Color infoBg; // the small "info" box and the glow ring on Welcome
  final Color segmentTrack; // background of the "Lock again after" picker
  final Color segmentSelected; // the selected option in that picker

  // Light mode adds soft shadows; dark mode has none (empty lists).
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> keyShadow;
  final List<BoxShadow> thumbShadow;
  final List<BoxShadow> segmentShadow;

  /// Colors from design/dark.
  static const dark = AppColors(
    background: Color(0xFF0D1014),
    surface: Color(0xFF161A20),
    surface2: Color(0xFF1E232B),
    border: Color(0xFF232831),
    borderStrong: Color(0xFF3A414D),
    track: Color(0xFF2A303A),
    text: Color(0xFFEEF1F5),
    muted: Color(0xFF9AA3AF),
    accent: Color(0xFF5EEAD4),
    onAccent: Color(0xFF0D1014),
    error: Color(0xFFFF8A8A),
    switchOff: Color(0xFF2A303A),
    thumbOn: Color(0xFF0D1014),
    thumbOff: Color(0xFF9AA3AF),
    infoBg: Color(0xFF12161B),
    segmentTrack: Color(0xFF0D1014),
    segmentSelected: Color(0xFF2A303A),
    cardShadow: [],
    keyShadow: [],
    thumbShadow: [],
    segmentShadow: [],
  );

  /// Colors from design/light. Shadow colors are rgba(16,24,40, alpha).
  static const light = AppColors(
    background: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF1F4),
    border: Color(0xFFE3E7EC),
    borderStrong: Color(0xFFB8C0CB),
    track: Color(0xFFD5DAE1),
    text: Color(0xFF12161C),
    muted: Color(0xFF5B6573),
    accent: Color(0xFF0F766E),
    onAccent: Color(0xFFFFFFFF),
    error: Color(0xFFC42B2B),
    switchOff: Color(0xFFCBD2DB),
    thumbOn: Color(0xFFFFFFFF),
    thumbOff: Color(0xFFFFFFFF),
    infoBg: Color(0xFFEDF0F3),
    segmentTrack: Color(0xFFEEF1F4),
    segmentSelected: Color(0xFFFFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x0A101828), offset: Offset(0, 1), blurRadius: 2),
    ],
    keyShadow: [
      BoxShadow(color: Color(0x1A101828), offset: Offset(0, 1), blurRadius: 3),
    ],
    thumbShadow: [
      BoxShadow(color: Color(0x40101828), offset: Offset(0, 1), blurRadius: 2),
    ],
    segmentShadow: [
      BoxShadow(color: Color(0x1F101828), offset: Offset(0, 1), blurRadius: 3),
    ],
  );

  // Flutter requires these two methods. We never edit colors at runtime,
  // and we just snap between themes, so they stay very simple.
  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Lets any widget write `context.colors.accent` instead of the long version.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
