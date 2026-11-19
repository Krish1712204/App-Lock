import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// The row of 16px dots that shows how many digits were typed.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.total,
    required this.filled,
    this.error = false,
  });

  final int total; // how many dots to show
  final int filled; // how many are filled in
  final bool error; // true = all dots red (wrong PIN)

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'PIN digits entered: $filled',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Filled dot: solid color. Empty dot: just a 2px ring.
                color: error ? c.error : (i < filled ? c.accent : Colors.transparent),
                border: (error || i < filled) ? null : Border.all(color: c.borderStrong, width: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two keypad looks from the designs:
/// - [KeypadStyle.square]: Set PIN screen (wide keys, radius 20, 64px tall)
/// - [KeypadStyle.round]: lock PIN screen (76px circles, fingerprint key)
enum KeypadStyle { square, round }

/// The 0-9 keypad with a delete key.
///
/// Layout (both styles):
///   1 2 3
///   4 5 6
///   7 8 9
///   * 0 ⌫     (* = empty on square, fingerprint on round)
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.style,
    required this.onDigit,
    required this.onDelete,
    this.onFingerprint,
  });

  final KeypadStyle style;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onFingerprint; // only shown on the round style

  bool get _round => style == KeypadStyle.round;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    final rowGap = _round ? 14.0 : 12.0;

    return Column(
      children: [
        for (final row in rows) ...[
          _row(context, [for (final d in row) _DigitKey(d, round: _round, onTap: () => onDigit(d))]),
          SizedBox(height: rowGap),
        ],
        _row(context, [
          if (_round && onFingerprint != null)
            _IconKey(
              icon: AppIcons.fingerprint,
              label: 'Use fingerprint instead',
              round: true,
              accent: true,
              onTap: onFingerprint!,
            )
          else
            const SizedBox.shrink(), // empty bottom-left cell
          _DigitKey('0', round: _round, onTap: () => onDigit('0')),
          _IconKey(icon: AppIcons.backspace, label: 'Delete last digit', round: _round, onTap: onDelete),
        ]),
      ],
    );
  }

  /// Three equal-width cells with gaps between them.
  Widget _row(BuildContext context, List<Widget> keys) {
    final colGap = _round ? 20.0 : 12.0;
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) SizedBox(width: colGap),
          Expanded(child: Center(child: keys[i])),
        ],
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey(this.digit, {required this.round, required this.onTap});

  final String digit;
  final bool round;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Round key: 76x76 circle. Square key: full cell width, 64 tall.
    final radius = BorderRadius.circular(round ? 38 : 20);

    return Container(
      width: round ? 76 : double.infinity,
      height: round ? 76 : 64,
      decoration: BoxDecoration(color: c.surface, borderRadius: radius, boxShadow: c.keyShadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Center(
            child: Text(
              digit,
              style: AppText.heading(round ? 28 : 26, weight: FontWeight.w500, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({
    required this.icon,
    required this.label,
    required this.round,
    required this.onTap,
    this.accent = false,
  });

  final String icon;
  final String label;
  final bool round;
  final VoidCallback onTap;
  final bool accent; // fingerprint key is drawn in the accent color

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(round ? 38 : 20);
    final isFingerprint = icon == AppIcons.fingerprint;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: round ? 76 : double.infinity,
        height: round ? 76 : 64,
        child: Material(
          type: MaterialType.transparency, // no background, like the design
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: AppIcon(
                icon,
                size: isFingerprint ? 30 : (round ? 28 : 26),
                strokeWidth: 1.8,
                color: accent ? c.accent : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
