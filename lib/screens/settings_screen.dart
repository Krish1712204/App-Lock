import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../routes.dart';
import '../services/permissions_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/pill_switch.dart';
import 'set_pin_screen.dart';

/// Screen 7 (design/Settings.html).
///
/// Phase 1: switches only change in-memory values. Phase 6 makes them real.
/// "Extras" is shown greyed out ("Coming later"), as agreed.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// WidgetsBindingObserver: re-check the Health card when you come back
// from Android settings.
class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _s = FakeStore.instance;
  PermissionStatus? _health;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkHealth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final status = await PermissionsService.check();
      if (mounted) setState(() => _health = status);
    } catch (_) {
      // keep the last result
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back arrow + "Settings" title. The design shifts this row
              // 10px left so the arrow lines up with the cards below.
              SizedBox(
                height: 52,
                child: Transform.translate(
                  offset: const Offset(-10, 0),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: AppIcons.arrowLeft,
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 6),
                      Text('Settings', style: AppText.heading(24, letterSpacing: -0.3, color: c.text)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 4, bottom: 28 + bottomInset),
                  children: [
                    const _GroupLabel('Security', top: 16),
                    _Group(children: [
                      _TapRow(
                        title: 'Change PIN',
                        onTap: () => Navigator.pushNamed(context, Routes.setPin, arguments: SetPinScreen.changeMode),
                      ),
                      _SwitchRow(
                        title: 'Fingerprint unlock',
                        value: _s.fingerprintUnlock,
                        onChanged: (v) => setState(() => _s.fingerprintUnlock = v),
                      ),
                      _RelockPicker(
                        value: _s.relockDelay,
                        onChanged: (v) => setState(() => _s.relockDelay = v),
                      ),
                      _SwitchRow(
                        title: 'Lock when screen turns off',
                        subtitle: 'Every locked app needs a new check',
                        value: _s.lockOnScreenOff,
                        onChanged: (v) => setState(() => _s.lockOnScreenOff = v),
                      ),
                    ]),
                    const _GroupLabel('Protection'),
                    _Group(children: [
                      _SwitchRow(
                        title: 'Lock Settings & Play Store',
                        subtitle: 'So no one can uninstall App Lock',
                        value: _s.lockSettingsAndStore,
                        onChanged: (v) => setState(() => _s.lockSettingsAndStore = v),
                      ),
                      _SwitchRow(
                        title: 'Hide previews in Recent apps',
                        subtitle: 'Locked apps show a blank card',
                        value: _s.hideRecentsPreview,
                        onChanged: (v) => setState(() => _s.hideRecentsPreview = v),
                      ),
                    ]),
                    const _GroupLabel('Extras', badge: 'Coming later'),
                    // Greyed out and switches disabled (onChanged: null).
                    Opacity(
                      opacity: 0.5,
                      child: _Group(children: [
                        _SwitchRow(
                          icon: AppIcons.camera,
                          title: 'Intruder selfie',
                          subtitle: 'Photo after 3 wrong PINs',
                          value: false,
                          onChanged: null,
                        ),
                        _SwitchRow(
                          icon: AppIcons.alertTriangle,
                          title: 'Fake crash screen',
                          subtitle: 'Shows “App has stopped” instead',
                          value: false,
                          onChanged: null,
                        ),
                      ]),
                    ),
                    const _GroupLabel('Health check'),
                    _HealthCheck(status: _health),
                    // The Permissions screen is part of setup; this is the
                    // way back to it afterwards.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.permissions, arguments: true),
                        style: TextButton.styleFrom(foregroundColor: c.accent),
                        child: Text('All permissions →', style: AppText.body(14, weight: FontWeight.w600, color: c.accent)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey uppercase label above each group, with an optional small badge.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {this.top = 24, this.badge});

  final String text;
  final double top;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, 8),
      child: Row(
        children: [
          SectionLabel(text),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
              child: Text(badge!, style: AppText.body(11, weight: FontWeight.w600, color: c.text)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A rounded card holding rows, with thin lines between them.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      radius: 18,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: c.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A row you tap to open another screen (with a ">" arrow).
class _TapRow extends StatelessWidget {
  const _TapRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(title, style: AppText.body(15, weight: FontWeight.w500, color: c.text))),
              AppIcon(AppIcons.chevronRight, size: 18, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with a title, optional subtitle/icon, and a switch on the right.
/// Tapping anywhere on the row flips the switch.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? icon;
  final bool value;
  final ValueChanged<bool>? onChanged; // null = disabled

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, subtitle == null ? 0 : 10, 8, subtitle == null ? 0 : 10),
          child: Row(
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: 20, color: c.muted),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppText.body(15, weight: FontWeight.w500, color: c.text)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppText.body(13, color: c.muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PillSwitch(value: value, onChanged: onChanged, label: title, tapWidth: 56),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Lock again after": Right away / 1 min / 5 min.
class _RelockPicker extends StatelessWidget {
  const _RelockPicker({required this.value, required this.onChanged});

  final RelockDelay value;
  final ValueChanged<RelockDelay> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lock again after', style: AppText.body(15, weight: FontWeight.w500, color: c.text)),
          const SizedBox(height: 2),
          Text('Time after you leave a locked app', style: AppText.body(13, color: c.muted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: c.segmentTrack, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                for (final option in RelockDelay.values) ...[
                  if (option != RelockDelay.values.first) const SizedBox(width: 4),
                  Expanded(child: _segment(context, option)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, RelockDelay option) {
    final c = context.colors;
    final selected = option == value;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => onChanged(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          decoration: BoxDecoration(
            color: selected ? c.segmentSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? c.segmentShadow : null,
          ),
          child: Center(
            child: Text(
              option.label,
              style: AppText.body(
                14,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? c.text : c.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Health check" card, with the real status.
/// Green ✓ = fine. Red ✗ = a problem: tap the line to open the fix.
class _HealthCheck extends StatelessWidget {
  const _HealthCheck({required this.status});

  final PermissionStatus? status; // null while checking

  @override
  Widget build(BuildContext context) {
    final s = status;
    // (ok?, text when ok, text when not ok, what to open to fix it)
    final lines = <(bool, String, String, AppPermission)>[
      (s?.watcherRunning ?? true, 'Accessibility service is running',
          'Accessibility service is off · Fix', AppPermission.accessibility),
      (s?.overlay ?? true, 'Can display over other apps',
          'Can’t display over other apps · Fix', AppPermission.overlay),
      (s?.battery ?? true, 'Battery set to Unrestricted',
          'Battery isn’t Unrestricted · Fix', AppPermission.battery),
      (s?.fingerprint ?? true, 'Fingerprint saved on this phone',
          'No fingerprint saved · Add one', AppPermission.fingerprint),
    ];

    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _HealthLine(ok: lines[i].$1, okText: lines[i].$2, badText: lines[i].$3, fix: lines[i].$4),
          ],
        ],
      ),
    );
  }
}

class _HealthLine extends StatelessWidget {
  const _HealthLine({required this.ok, required this.okText, required this.badText, required this.fix});

  final bool ok;
  final String okText;
  final String badText;
  final AppPermission fix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ok ? null : () => PermissionsService.open(fix),
      child: Row(
        children: [
          AppIcon(ok ? AppIcons.check : AppIcons.cross, size: 18, strokeWidth: 2.5, color: ok ? c.accent : c.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok ? okText : badText,
              style: AppText.body(14, weight: ok ? FontWeight.w400 : FontWeight.w500, color: ok ? c.text : c.error),
            ),
          ),
        ],
      ),
    );
  }
}
