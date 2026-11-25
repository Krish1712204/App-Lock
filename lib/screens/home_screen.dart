import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../lock/lock_controller.dart';
import '../routes.dart';
import '../services/native_bridge.dart';
import '../services/owner_check.dart';
import '../services/permissions_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/pill_switch.dart';

/// Screen 4 (design/Home.html): master switch, search, and the app lists.
///
/// The apps come from Kotlin (your real installed apps). Every switch is
/// saved straight to Kotlin, where the watcher reads it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// WidgetsBindingObserver: re-check the watcher when you come back to App Lock.
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<AppInfo>? _apps; // null while loading
  Set<String> _locked = {}; // package names of locked apps
  bool _protectionOn = true;
  bool _watcherRunning = true; // assume fine until checked (no flash of red)
  String _query = ''; // text in the search box
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkWatcher();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkWatcher();
  }

  /// Is the Accessibility watcher actually running? If not, nothing gets
  /// locked, so Home shows a red warning.
  Future<void> _checkWatcher() async {
    try {
      final status = await PermissionsService.check();
      if (mounted) setState(() => _watcherRunning = status.watcherRunning);
    } catch (_) {
      // keep the last value
    }
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      // Ask Kotlin for all three things at the same time.
      final results = await Future.wait([
        NativeBridge.getInstalledApps(refresh: refresh),
        NativeBridge.getLockedApps(),
        NativeBridge.isProtectionOn(),
      ]);
      if (!mounted) return;
      setState(() {
        _apps = results[0] as List<AppInfo>;
        _locked = results[1] as Set<String>;
        _protectionOn = results[2] as bool;
        _loadError = null;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Couldn’t load your apps.\n$e');
    }
  }

  bool _matches(AppInfo app) => app.name.toLowerCase().contains(_query.trim().toLowerCase());

  Future<void> _toggleApp(AppInfo app) async {
    final removing = _locked.contains(app.packageName);
    // Removing a lock makes App Lock weaker: check it's really you first.
    // (Adding a lock never asks.)
    if (removing && !await OwnerCheck.confirm(context, 'Remove lock from ${app.name}')) return;
    if (!mounted) return;
    setState(() {
      if (removing) {
        _locked.remove(app.packageName);
      } else {
        _locked.add(app.packageName);
      }
    });
    NativeBridge.setLockedApps(_locked); // save for the watcher
  }

  Future<void> _setProtection(bool on) async {
    // Turning protection off unlocks everything: check it's really you.
    if (!on && !await OwnerCheck.confirm(context, 'Turn off App Lock')) return;
    if (!mounted) return;
    setState(() => _protectionOn = on);
    NativeBridge.setProtectionOn(on);
  }

  /// "Preview the lock screen →" uses your first locked app (or any app).
  void _openPreview() {
    final apps = _apps ?? const <AppInfo>[];
    final lockedApps = apps.where((a) => _locked.contains(a.packageName));
    final app = lockedApps.isNotEmpty ? lockedApps.first : (apps.isNotEmpty ? apps.first : null);
    // Fingerprint off in Settings → preview the PIN pad instead.
    Navigator.pushNamed(context, LockController.fingerprintEnabled ? Routes.lock : Routes.lockPin, arguments: app);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final apps = _apps ?? const <AppInfo>[];
    // Count only locked apps that are still installed.
    final lockedTotal = apps.where((a) => _locked.contains(a.packageName)).length;

    return Scaffold(
      body: SafeArea(
        bottom: false, // let the list scroll behind the gesture bar
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title + settings button
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Expanded(
                      child: Text('App Lock', style: AppText.heading(26, letterSpacing: -0.4, color: c.text)),
                    ),
                    Transform.translate(
                      offset: const Offset(6, 0),
                      child: RoundIconButton(
                        icon: AppIcons.sliders,
                        iconSize: 20,
                        tooltip: 'Settings',
                        background: c.surface,
                        onPressed: () => Navigator.pushNamed(context, Routes.settings),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _StatusCard(
                on: _protectionOn,
                broken: _protectionOn && !_watcherRunning,
                lockedTotal: lockedTotal,
                onToggle: _setProtection,
                onPreview: _openPreview,
                onFix: () => PermissionsService.open(AppPermission.accessibility),
              ),
              const SizedBox(height: 16),
              _SearchBox(onChanged: (q) => setState(() => _query = q)),
              const SizedBox(height: 8),
              Expanded(child: _buildList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final c = context.colors;

    if (_loadError != null) {
      return Center(
        child: Text(_loadError!, textAlign: TextAlign.center, style: AppText.body(14, color: c.error)),
      );
    }
    if (_apps == null) {
      return Center(child: CircularProgressIndicator(color: c.accent));
    }

    final locked = _apps!.where((a) => _locked.contains(a.packageName) && _matches(a)).toList();
    final other = _apps!.where((a) => !_locked.contains(a.packageName) && _matches(a)).toList();
    final bottomInset = MediaQuery.paddingOf(context).bottom; // gesture bar height

    // Pull down to reload the app list (e.g. after installing a new app).
    return RefreshIndicator(
      color: c.accent,
      onRefresh: () => _load(refresh: true),
      child: CustomScrollView(
        // Always scrollable, so pull-to-refresh works even with few apps.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // A SliverList builds rows only when they scroll into view,
          // which keeps a list of 100+ apps smooth.
          if (locked.isNotEmpty) ..._section('Locked · ${locked.length}', locked, isLocked: true),
          if (other.isNotEmpty) ..._section('Other apps · ${other.length}', other, isLocked: false),
          if (locked.isEmpty && other.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'No apps match “$_query”',
                  textAlign: TextAlign.center,
                  style: AppText.body(15, color: c.muted),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 24 + bottomInset)),
        ],
      ),
    );
  }

  List<Widget> _section(String title, List<AppInfo> apps, {required bool isLocked}) => [
        SliverToBoxAdapter(child: _ListHeader(title)),
        SliverList.builder(
          itemCount: apps.length,
          itemBuilder: (_, i) => _AppRow(
            // The key helps Flutter keep the right switch with the right app
            // when rows move between the two lists.
            key: ValueKey(apps[i].packageName),
            app: apps[i],
            locked: isLocked,
            onToggle: () => _toggleApp(apps[i]),
          ),
        ),
      ];
}

/// The big card at the top: shield, "Protection is on", master switch,
/// and the "Preview the lock screen →" link.
/// If [broken] (switch on, but the watcher isn't running), it turns red and
/// shows a "Turn on Accessibility →" link.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.on,
    required this.broken,
    required this.lockedTotal,
    required this.onToggle,
    required this.onPreview,
    required this.onFix,
  });

  final bool on;
  final bool broken;
  final int lockedTotal;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPreview;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final appsWord = lockedTotal == 1 ? 'app' : 'apps';

    final String title;
    final String subtitle;
    if (broken) {
      title = 'Protection isn’t working';
      subtitle = 'Accessibility is off, so apps open without a check';
    } else if (on) {
      title = 'Protection is on';
      subtitle = '$lockedTotal $appsWord locked';
    } else {
      title = 'Protection is paused';
      subtitle = 'Locked apps open without a check';
    }

    return SurfaceCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: broken ? AppIcons.alertTriangle : AppIcons.shieldCheck,
                iconColor: broken ? c.error : (on ? c.accent : c.muted),
                size: 48,
                radius: 16,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.body(17, weight: FontWeight.w600, color: broken ? c.error : c.text),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.body(13, color: c.muted)),
                  ],
                ),
              ),
              PillSwitch(value: on, onChanged: onToggle, label: 'App Lock protection'),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: broken ? onFix : onPreview,
            child: Text(
              broken ? 'Turn on Accessibility →' : 'Preview the lock screen →',
              style: AppText.body(14, weight: FontWeight.w600, color: broken ? c.error : c.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.search, size: 18, color: c.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppText.body(15, color: c.text),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration.collapsed(
                hintText: 'Search apps',
                hintStyle: AppText.body(15, color: c.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: SectionLabel(text),
    );
  }
}

/// One app: icon, name, "Needs fingerprint"/"Not locked", switch.
/// Tapping anywhere on the row flips the switch.
class _AppRow extends StatelessWidget {
  const _AppRow({super.key, required this.app, required this.locked, required this.onToggle});

  final AppInfo app;
  final bool locked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            AppTile(app: app),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // long names end with "…"
                    style: AppText.body(15, weight: FontWeight.w500, color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked ? 'Needs fingerprint' : 'Not locked',
                    style: AppText.body(13, color: locked ? c.accent : c.muted),
                  ),
                ],
              ),
            ),
            PillSwitch(value: locked, onChanged: (_) => onToggle(), label: 'Lock ${app.name}'),
          ],
        ),
      ),
    );
  }
}
