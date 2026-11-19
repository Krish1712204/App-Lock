import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// Screen 3 (design/Permissions.html): the 4 permissions App Lock needs.
///
/// Phase 1: the status is fake. Tapping "Allow" just flips it to "Allowed".
/// Phase 5 will check the real status and open the right Android settings page.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _store = FakeStore.instance;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // Each permission: icon, title, subtitle, is it allowed?, what Allow does.
    final items = [
      _Permission(AppIcons.eye, 'Accessibility', 'Notices when a locked app opens',
          _store.accessibilityAllowed, () => _store.accessibilityAllowed = true),
      _Permission(AppIcons.layers, 'Display over other apps', 'Shows the lock screen on top',
          _store.overlayAllowed, () => _store.overlayAllowed = true),
      _Permission(AppIcons.fingerprintSmall, 'Fingerprint', 'Uses fingerprints saved on your phone',
          _store.fingerprintAllowed, () => _store.fingerprintAllowed = true),
      _Permission(AppIcons.battery, 'Battery: Unrestricted', 'Stops the phone from closing App Lock',
          _store.batteryAllowed, () => _store.batteryAllowed = true),
    ];
    final doneCount = items.where((p) => p.allowed).length;

    return Scaffold(
      body: SafeArea(
        child: FillScroll(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepHeader(stepLabel: 'Step 2 of 2'),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 32),
                child: StepProgress(done: 2),
              ),
              Text(
                'Allow 4 permissions',
                style: AppText.heading(28, letterSpacing: -0.4, height: 1.2, color: c.text),
              ),
              const SizedBox(height: 10),
              Text(
                'App Lock needs these to spot when a locked app opens and cover it. '
                'You can turn them off anytime.',
                style: AppText.body(15, height: 1.5, color: c.muted),
              ),
              const SizedBox(height: 24),
              for (final p in items) ...[
                _PermissionCard(
                  permission: p,
                  onAllow: () => setState(p.allow),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6), // 10 + 6 = 16px gap, like the design
              _PrivacyNote(),
              const Spacer(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Text(
                  '$doneCount of 4 done',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: c.muted),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Finish setup',
                // Go to Home and remove the setup screens from the back stack,
                // so the back button doesn't return to setup.
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain data for one permission row.
class _Permission {
  _Permission(this.icon, this.title, this.subtitle, this.allowed, this.allow);

  final String icon;
  final String title;
  final String subtitle;
  final bool allowed;
  final VoidCallback allow;
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.permission, required this.onAllow});

  final _Permission permission;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = permission;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      // Not-yet-allowed cards get a stronger border to stand out.
      borderColor: p.allowed ? c.border : c.borderStrong,
      shadow: p.allowed,
      child: Row(
        children: [
          IconTile(icon: p.icon, iconColor: c.text, iconSize: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: AppText.body(15, weight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 2),
                Text(p.subtitle, style: AppText.body(13, height: 1.4, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (p.allowed)
            Row(
              children: [
                AppIcon(AppIcons.check, size: 16, strokeWidth: 2.5, color: c.accent),
                const SizedBox(width: 4),
                Text('Allowed', style: AppText.body(13, weight: FontWeight.w600, color: c.accent)),
              ],
            )
          else
            SmallAccentButton(label: 'Allow', onPressed: onAllow),
        ],
      ),
    );
  }
}

/// The small grey box: "App Lock only checks which app is open..."
class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: c.infoBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppIcon(AppIcons.info, size: 18, color: c.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppText.body(13, height: 1.45, color: c.muted),
                children: [
                  const TextSpan(text: 'App Lock only checks '),
                  TextSpan(
                    text: 'which app',
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' is open. It never reads what’s on your screen.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
