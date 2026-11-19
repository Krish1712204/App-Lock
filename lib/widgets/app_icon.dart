import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The icon shapes, copied exactly from the SVGs in the HTML designs.
/// Each one is only the inside of a 24x24 `<svg>` (paths, lines, circles).
class AppIcons {
  /// Big fingerprint (Welcome logo, lock screen, PIN keypad key).
  static const fingerprint =
      '<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/>'
      '<path d="M14 13.12c0 2.38 0 6.38-1 8.88"/>'
      '<path d="M17.29 21.02c.12-.6.43-2.3.5-3.02"/>'
      '<path d="M2 12a10 10 0 0 1 18-6"/>'
      '<path d="M2 16h.01"/>'
      '<path d="M21.8 16c.2-2 .131-5.354 0-6"/>'
      '<path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/>'
      '<path d="M8.65 22c.21-.66.45-1.32.57-2"/>'
      '<path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>';

  /// Simpler fingerprint with fewer lines (small 20-22px sizes).
  static const fingerprintSmall =
      '<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/>'
      '<path d="M14 13.12c0 2.38 0 6.38-1 8.88"/>'
      '<path d="M2 12a10 10 0 0 1 18-6"/>'
      '<path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/>'
      '<path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>';

  static const key =
      '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4"/>'
      '<path d="m21 2-9.6 9.6"/>'
      '<circle cx="7.5" cy="15.5" r="5.5"/>';

  static const shieldCheck =
      '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>'
      '<path d="m9 12 2 2 4-4"/>';

  static const arrowLeft = '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>';

  static const chevronRight = '<path d="m9 18 6-6-6-6"/>';

  static const eye =
      '<path d="M2.06 12.35a1 1 0 0 1 0-.7 10.75 10.75 0 0 1 19.88 0 1 1 0 0 1 0 .7 10.75 10.75 0 0 1-19.88 0"/>'
      '<circle cx="12" cy="12" r="3"/>';

  static const layers =
      '<path d="M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/>'
      '<path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/>'
      '<path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>';

  static const battery =
      '<rect width="16" height="10" x="2" y="7" rx="2" ry="2"/>'
      '<line x1="22" x2="22" y1="11" y2="13"/>';

  static const check = '<path d="M20 6 9 17l-5-5"/>';

  /// An "x" (not in the designs; used when a health check fails).
  static const cross = '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>';

  static const info =
      '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>';

  static const sliders =
      '<line x1="21" x2="14" y1="4" y2="4"/><line x1="10" x2="3" y1="4" y2="4"/>'
      '<line x1="21" x2="12" y1="12" y2="12"/><line x1="8" x2="3" y1="12" y2="12"/>'
      '<line x1="21" x2="16" y1="20" y2="20"/><line x1="12" x2="3" y1="20" y2="20"/>'
      '<line x1="14" x2="14" y1="2" y2="6"/><line x1="8" x2="8" y1="10" y2="14"/>'
      '<line x1="16" x2="16" y1="18" y2="22"/>';

  static const search =
      '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>';

  static const lock =
      '<rect x="3" y="11" width="18" height="11" rx="2"/>'
      '<path d="M7 11V7a5 5 0 0 1 10 0v4"/>';

  static const backspace =
      '<path d="M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z"/>'
      '<path d="m12 9 6 6"/><path d="m18 9-6 6"/>';

  static const alertTriangle =
      '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>'
      '<path d="M12 9v4"/><path d="M12 17h.01"/>';

  static const camera =
      '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/>'
      '<circle cx="12" cy="13" r="3"/>';
}

/// Draws one of the [AppIcons] shapes as a line icon.
///
/// Example: `AppIcon(AppIcons.lock, size: 18, color: c.accent)`
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.shape, {
    super.key,
    required this.color,
    this.size = 24,
    this.strokeWidth = 2,
  });

  final String shape;
  final Color color;
  final double size;
  final double strokeWidth; // line thickness, same as stroke-width in the HTML

  @override
  Widget build(BuildContext context) {
    // Wrap the shape in a full <svg> tag. We draw it in black, then the
    // colorFilter repaints every visible pixel in [color].
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="none" stroke="#000" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">$shape</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
