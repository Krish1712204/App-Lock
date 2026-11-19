import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/pill_switch.dart';

/// Screen 4 (design/Home.html): master switch, search, and the app lists.
///
/// Phase 1 uses the 12 fake apps. Phase 3 loads the real installed apps.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = FakeStore.instance;
  String _query = ''; // text in the search box

  bool _matches(FakeApp app) => app.name.toLowerCase().contains(_query.trim().toLowerCase());

  void _toggleApp(FakeApp app) {
    setState(() {
      // Set.remove returns false if it wasn't there, so then we add it.
      if (!_store.lockedIds.remove(app.id)) _store.lockedIds.add(app.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locked = fakeApps.where((a) => _store.lockedIds.contains(a.id) && _matches(a)).toList();
    final other = fakeApps.where((a) => !_store.lockedIds.contains(a.id) && _matches(a)).toList();
    final bottomInset = MediaQuery.paddingOf(context).bottom; // gesture bar height

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
                        onPressed: () async {
                          await Navigator.pushNamed(context, Routes.settings);
                          // Refresh in case something changed (only if this
                          // screen is still open).
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _StatusCard(
                on: _store.protectionOn,
                lockedTotal: _store.lockedIds.length,
                onToggle: (v) => setState(() => _store.protectionOn = v),
              ),
              const SizedBox(height: 16),
              _SearchBox(onChanged: (q) => setState(() => _query = q)),
              const SizedBox(height: 8),
              // The scrolling list of apps.
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: 24 + bottomInset),
                  children: [
                    if (locked.isNotEmpty) ...[
                      _ListHeader('Locked · ${locked.length}'),
                      for (final app in locked) _AppRow(app: app, locked: true, onToggle: () => _toggleApp(app)),
                    ],
                    if (other.isNotEmpty) ...[
                      _ListHeader('Other apps · ${other.length}'),
                      for (final app in other) _AppRow(app: app, locked: false, onToggle: () => _toggleApp(app)),
                    ],
                    if (locked.isEmpty && other.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Text(
                          'No apps match “$_query”',
                          textAlign: TextAlign.center,
                          style: AppText.body(15, color: c.muted),
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

/// The big card at the top: shield, "Protection is on", master switch,
/// and the "Preview the lock screen →" link.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.on, required this.lockedTotal, required this.onToggle});

  final bool on;
  final int lockedTotal;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final appsWord = lockedTotal == 1 ? 'app' : 'apps';

    return SurfaceCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: AppIcons.shieldCheck,
                iconColor: on ? c.accent : c.muted,
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
                      on ? 'Protection is on' : 'Protection is paused',
                      style: AppText.body(17, weight: FontWeight.w600, color: c.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      on ? '$lockedTotal $appsWord locked' : 'Locked apps open without a check',
                      style: AppText.body(13, color: c.muted),
                    ),
                  ],
                ),
              ),
              PillSwitch(value: on, onChanged: onToggle, label: 'App Lock protection'),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.lock, arguments: fakeApps.first),
            child: Text(
              'Preview the lock screen →',
              style: AppText.body(14, weight: FontWeight.w500, color: c.accent),
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

/// One app: letter tile, name, "Needs fingerprint"/"Not locked", switch.
/// Tapping anywhere on the row flips the switch.
class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.locked, required this.onToggle});

  final FakeApp app;
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
            LetterTile(app: app),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: AppText.body(15, weight: FontWeight.w500, color: c.text)),
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
