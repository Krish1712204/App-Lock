import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// The big 56px pill button ("Get started", "Continue", "Finish setup").
/// When [onPressed] is null it shows the grey disabled look.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: enabled ? c.accent : c.surface2,
        shape: const StadiumBorder(), // pill shape (radius 28)
        clipBehavior: Clip.antiAlias, // keeps the tap ripple inside the pill
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: AppText.body(
                16,
                weight: FontWeight.w600,
                color: enabled ? c.onAccent : c.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 52px outlined pill button with an icon ("Use PIN instead").
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String icon; // one of AppIcons
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: c.borderStrong)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 18, color: c.text),
              const SizedBox(width: 8),
              Text(label, style: AppText.body(15, weight: FontWeight.w600, color: c.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small 36px "Allow" button on the Permissions screen.
class SmallAccentButton extends StatelessWidget {
  const SmallAccentButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 36,
      child: Material(
        color: c.accent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: AppText.body(14, weight: FontWeight.w600, color: c.onAccent)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round 44px icon button (back arrow, settings).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.background,
    this.iconSize = 22,
  });

  final String icon;
  final VoidCallback onPressed;
  final String tooltip; // also read aloud by TalkBack
  final Color? background; // null = transparent
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: AppIcon(icon, size: iconSize, color: c.text)),
          ),
        ),
      ),
    );
  }
}
