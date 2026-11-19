import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// Screen 1 (design/Main.html): big fingerprint logo, 3 features, "Get started".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: FillScroll(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            children: [
              // Top part: logo + title, centered in the free space.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: c.track),
                        // A solid 14px ring around the box (box-shadow in the design).
                        boxShadow: [BoxShadow(color: c.infoBg, spreadRadius: 14)],
                      ),
                      child: Center(
                        child: AppIcon(AppIcons.fingerprint, size: 64, strokeWidth: 1.5, color: c.accent),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Lock any app with your fingerprint',
                      textAlign: TextAlign.center,
                      style: AppText.heading(32, letterSpacing: -0.5, height: 1.15, color: c.text),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep your chats, photos and payment apps private.',
                      textAlign: TextAlign.center,
                      style: AppText.body(16, height: 1.5, color: c.muted),
                    ),
                    const SizedBox(height: 24), // breathing room above the list
                  ],
                ),
              ),
              const _Feature(
                icon: AppIcons.fingerprintSmall,
                title: 'Fingerprint unlock',
                subtitle: 'Opens in one touch, no typing',
              ),
              const SizedBox(height: 10),
              const _Feature(
                icon: AppIcons.key,
                title: 'Backup PIN',
                subtitle: 'For when the sensor can’t read your finger',
              ),
              const SizedBox(height: 10),
              const _Feature(
                icon: AppIcons.shieldCheck,
                title: 'Stays on your phone',
                subtitle: 'Works offline. No account, no cloud.',
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Get started',
                onPressed: () => Navigator.pushNamed(context, Routes.setPin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the feature list: icon tile + title + subtitle.
class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.subtitle});

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconTile(icon: icon, iconColor: c.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(15, weight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.body(13, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
