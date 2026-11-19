import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The 48x28 on/off switch from the designs.
///
/// We draw our own instead of Flutter's Switch so it matches the design
/// exactly. The touch area is bigger (44px tall) so it's easy to hit.
/// Pass `onChanged: null` to show it disabled.
class PillSwitch extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tapWidth = 52,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label; // read aloud by TalkBack
  final double tapWidth;

  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;

    return Semantics(
      label: label,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: tapWidth,
          height: 44,
          child: Center(
            // AnimatedContainer smoothly fades the track color.
            child: AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOut,
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? c.accent : c.switchOff,
                borderRadius: BorderRadius.circular(14),
              ),
              // AnimatedAlign slides the knob from left to right.
              child: AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? c.thumbOn : c.thumbOff,
                    shape: BoxShape.circle,
                    boxShadow: c.thumbShadow,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
