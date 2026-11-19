import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/permissions_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// Screen 3 (design/Permissions.html): the 4 permissions App Lock needs.
///
/// Shows the REAL status of each one. "Allow" opens the right Android
/// settings page. When you come back to App Lock, it checks again by itself.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, this.fromSettings = false});

  /// true = opened from Settings: no "Step 2 of 2", and the button says
  /// "Done" and just goes back.
  final bool fromSettings;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

// "WidgetsBindingObserver" lets this screen hear app events, like
// "App Lock is back on screen" (after you return from Android settings).
class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  PermissionStatus? _status; // null until the first check finishes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(); // back from settings
  }

  Future<void> _refresh() async {
    try {
      final status = await PermissionsService.check();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      // Leave the old status if the check fails; it will retry on resume.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = _status;

    final items = [
      const _Permission(AppPermission.accessibility, AppIcons.eye, 'Accessibility',
          'Notices when a locked app opens'),
      const _Permission(AppPermission.overlay, AppIcons.layers, 'Display over other apps',
          'Shows the lock screen on top'),
      const _Permission(AppPermission.fingerprint, AppIcons.fingerprintSmall, 'Fingerprint',
          'Uses fingerprints saved on your phone'),
      const _Permission(AppPermission.battery, AppIcons.battery, 'Battery: Unrestricted',
          'Stops the phone from closing App Lock'),
    ];

    return Scaffold(
      body: SafeArea(
        child: FillScroll(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepHeader(stepLabel: widget.fromSettings ? null : 'Step 2 of 2'),
              if (widget.fromSettings)
                const SizedBox(height: 24)
              else
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
                  allowed: status?.isAllowed(p.type), // null = still checking
                  onAllow: () => PermissionsService.open(p.type),
                ),
                const SizedBox(height: 10),
              ],
              // Android 14/15 greys out Accessibility for apps installed from
              // an APK file ("Restricted setting"). Explain the way around it.
              if (status != null && !status.accessibility) ...[
                const _RestrictedHint(),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6), // 10 + 6 = 16px gap, like the design
              const _PrivacyNote(),
              const Spacer(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Text(
                  status == null ? ' ' : '${status.doneCount} of 4 done',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: c.muted),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: widget.fromSettings ? 'Done' : 'Finish setup',
                onPressed: widget.fromSettings
                    ? () => Navigator.pop(context)
                    // Setup: go to Home and remove the setup screens from the
                    // back stack, so Back doesn't return to setup.
                    : () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed info for one permission row.
class _Permission {
  const _Permission(this.type, this.icon, this.title, this.subtitle);

  final AppPermission type;
  final String icon;
  final String title;
  final String subtitle;
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.permission, required this.allowed, required this.onAllow});

  final _Permission permission;
  final bool? allowed; // null while checking
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = permission;
    final ok = allowed == true;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      // Not-yet-allowed cards get a stronger border to stand out.
      borderColor: ok ? c.border : c.borderStrong,
      shadow: ok,
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
          if (allowed == null)
            const SizedBox(width: 36) // keep the space while checking
          else if (ok)
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

/// Shown while Accessibility is off: how to fix a greyed-out switch.
class _RestrictedHint extends StatelessWidget {
  const _RestrictedHint();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => PermissionsService.open(AppPermission.appInfo),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: c.infoBg, borderRadius: BorderRadius.circular(14)),
        child: Text.rich(
          TextSpan(
            style: AppText.body(13, height: 1.45, color: c.muted),
            children: [
              TextSpan(
                text: 'Switch greyed out? ',
                style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: 'Open App info → ⋮ (top right) → Allow restricted settings, then try again. '),
              TextSpan(
                text: 'Open App info',
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small grey box: "App Lock only checks which app is open..."
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

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
