import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'buttons.dart';

/// Lets a screen's Column use Spacer/Expanded to fill the screen, but scroll
/// instead of breaking if the screen is too short (small phone, big text).
class FillScroll extends StatelessWidget {
  const FillScroll({super.key, required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          // At least as tall as the screen, so Spacers have room to grow.
          constraints: BoxConstraints(minHeight: box.maxHeight - padding.vertical),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}

/// A card: surface color, thin border, radius 16 by default,
/// plus a soft shadow in light mode.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 16,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor; // default: the normal border color
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias, // keeps ripples and dividers inside the corners
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: shadow ? c.cardShadow : null,
      ),
      child: child,
    );
  }
}

/// A rounded square with an icon in the middle (40px tiles in lists).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.iconColor,
    this.size = 40,
    this.radius = 12,
    this.iconSize = 22,
    this.strokeWidth = 2,
  });

  final String icon;
  final Color iconColor;
  final double size;
  final double radius;
  final double iconSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: AppIcon(icon, size: iconSize, color: iconColor, strokeWidth: strokeWidth),
      ),
    );
  }
}

/// A colored square with the app's first letter (stand-in for app icons).
class LetterTile extends StatelessWidget {
  const LetterTile({
    super.key,
    required this.app,
    this.size = 44,
    this.radius = 14,
    this.fontSize = 19,
  });

  final FakeApp app;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: app.color, borderRadius: BorderRadius.circular(radius)),
      child: Center(
        child: Text(
          app.letter,
          style: AppText.heading(fontSize, color: Colors.white),
        ),
      ),
    );
  }
}

/// Small grey UPPERCASE section label ("LOCKED · 6", "SECURITY").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.body(12, weight: FontWeight.w600, letterSpacing: 1, color: context.colors.muted),
    );
  }
}

/// Top bar of the setup steps: back arrow on the left, "Step 1 of 2" on the right.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, this.stepLabel});

  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The design pulls the back button 10px left, so the arrow
          // lines up with the text below it.
          Transform.translate(
            offset: const Offset(-10, 0),
            child: RoundIconButton(
              icon: AppIcons.arrowLeft,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          if (stepLabel != null)
            Text(
              stepLabel!,
              style: AppText.body(13, weight: FontWeight.w500, color: context.colors.muted),
            ),
        ],
      ),
    );
  }
}

/// The 2-part progress bar under the step header.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.done, this.total = 2});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < done ? c.accent : c.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
