import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_icon.dart';

/// The unlock animation ("option C"): a teal circle with a check mark that
/// pops in (grows a little too big, then settles).
///
/// The lock screens show it for [hold] after a correct fingerprint or PIN,
/// then close. Android then fades the lock screen away (LockActivity.kt).
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, required this.size});

  final double size;

  /// How long the check is shown before the lock screen closes.
  static const hold = Duration(milliseconds: 250);

  /// Waits [hold], or not at all if "Remove animations" is on in the
  /// phone's settings. Call it right after showing the check.
  static Future<void> pause(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Future.value();
    return Future.delayed(hold);
  }

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> with SingleTickerProviderStateMixin {
  // Starts playing as soon as the check appears on screen.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  // Size over time: 0 → 115% (first 60% of the time) → 100%.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Unlocked',
      liveRegion: true, // TalkBack says "Unlocked"
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          child: Center(
            child: AppIcon(AppIcons.check, size: widget.size * 0.46, strokeWidth: 3, color: c.onAccent),
          ),
        ),
      ),
    );
  }
}
