import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../lock/lock_controller.dart';
import '../routes.dart';
import '../services/biometric_service.dart';
import '../services/pin_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/success_check.dart';

/// Screen 5 (design/LockScreen.html): "WhatsApp is locked" + fingerprint.
///
/// When it opens, Android's fingerprint popup appears by itself.
/// If you close the popup, tap the fingerprint circle to open it again.
/// (Apps can't read the sensor directly; only Android's popup can.)
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.app});

  final AppInfo app;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

// "SingleTickerProviderStateMixin" gives us a clock for the pulse animation.
class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the phone's "Remove animations" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  String? _problem; // shown in red under the sensor text, e.g. "No fingerprint saved"
  bool _asking = false; // true while the fingerprint popup is open
  bool _autoAsked = false; // the popup opens by itself only ONCE per lock
  bool _success = false; // true after a good unlock: shows the check mark

  @override
  void initState() {
    super.initState();
    if (!LockController.fingerprintEnabled) return; // Settings: fingerprint off

    if (LockController.isRealLock) {
      // Real lock: Android can only show the popup while LockActivity is on
      // screen. Ask now if it already is, otherwise as soon as it is.
      LockController.activityResumed.addListener(_onResumedChanged);
      _onResumedChanged();
    } else {
      // Preview: wait until the screen has been drawn once, then ask.
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoAsk());
    }
  }

  void _onResumedChanged() {
    if (LockController.activityResumed.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoAsk());
    }
  }

  // Opens the popup by itself, but only once. (Closing the popup makes
  // LockActivity "resume" again; without this guard, it would pop up again
  // forever after every Cancel.)
  void _autoAsk() {
    if (_autoAsked || !mounted) return;
    _autoAsked = true;
    _askFingerprint();
  }

  @override
  void dispose() {
    LockController.activityResumed.removeListener(_onResumedChanged);
    _pulse.dispose(); // always stop animations when the screen closes
    super.dispose();
  }

  Future<void> _askFingerprint() async {
    if (_asking) return; // the popup is already showing
    _asking = true;
    if (kDebugMode) {
      debugPrint('AppLock: fingerprint popup opened for ${widget.app.packageName}');
    }
    final result = await BiometricService.instance.fingerprint(title: 'Unlock ${widget.app.name}');
    _asking = false;
    if (kDebugMode) debugPrint('AppLock: fingerprint popup closed: $result');
    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        await _unlocked();
      case AuthResult.cancelled:
        setState(() => _problem = null); // you closed it: just wait
      case AuthResult.unavailable:
        setState(() => _problem = 'No fingerprint saved on this phone. Use your PIN.');
      case AuthResult.lockedOut:
        setState(() => _problem = 'Too many tries. Use your PIN for now.');
      case AuthResult.error:
        setState(() => _problem = 'Fingerprint didn’t work. Try again or use your PIN.');
    }
  }

  Future<void> _unlocked() async {
    await PinStore.instance.resetTries(); // a good unlock clears wrong PIN tries
    if (!mounted) return;
    // The fingerprint circle turns into a check mark for a moment.
    setState(() => _success = true);
    await SuccessCheck.pause(context);
    if (!mounted) return;
    // Real lock: closes (fading out) and shows the app. Preview: back to Home.
    await LockController.unlocked(context, widget.app);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final app = widget.app;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Real lock: Back must never reveal the locked app, so we catch it
    // (canPop: false) and go to the home screen instead.
    return PopScope(
      canPop: !LockController.isRealLock,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) LockController.back();
      },
      child: _buildScreen(c, app, reduceMotion),
    );
  }

  Widget _buildScreen(AppColors c, AppInfo app, bool reduceMotion) {
    return Scaffold(
      body: SafeArea(
        child: FillScroll(
          padding: const EdgeInsets.fromLTRB(24, 96, 24, 40),
          child: Column(
            children: [
              // App tile with a small lock badge on its corner.
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  clipBehavior: Clip.none, // the badge sticks out of the tile
                  children: [
                    AppTile(app: app, size: 84, radius: 26, fontSize: 36),
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: c.background, shape: BoxShape.circle),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                            child: Center(child: AppIcon(AppIcons.lock, size: 15, strokeWidth: 2.5, color: c.onAccent)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '${app.name} is locked',
                textAlign: TextAlign.center,
                style: AppText.heading(26, letterSpacing: -0.3, color: c.text),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock to continue',
                textAlign: TextAlign.center,
                style: AppText.body(15, color: c.muted),
              ),
              const Spacer(),
              const SizedBox(height: 32),
              // Fingerprint circle with a pulsing ring around it.
              Semantics(
                button: true,
                label: 'Touch to unlock with fingerprint',
                child: GestureDetector(
                  onTap: _success ? null : _askFingerprint,
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    // Unlocked: the check mark pops in where the circle was.
                    child: _success
                        ? const SuccessCheck(size: 96)
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // The ring grows (1x → 1.7x) and fades out, again and again.
                              // Positioned.fill = take the full 96x96 of the Stack.
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, _) {
                                    final t = Curves.easeOut.transform(_pulse.value);
                                    return Transform.scale(
                                      scale: reduceMotion ? 1 : 1 + 0.7 * t,
                                      child: Opacity(
                                        opacity: reduceMotion ? 0.25 : 0.55 * (1 - t),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: c.accent, width: 2),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.track),
                                  ),
                                  child: Center(
                                    child: AppIcon(AppIcons.fingerprint, size: 48, strokeWidth: 1.6, color: c.accent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Touch the sensor to unlock',
                textAlign: TextAlign.center,
                style: AppText.body(15, weight: FontWeight.w500, color: c.text),
              ),
              const SizedBox(height: 6),
              Text(
                _problem ?? 'The sensor is under the screen, here',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: _problem == null ? c.muted : c.error),
              ),
              const SizedBox(height: 64),
              OutlinePillButton(
                label: 'Use PIN instead',
                icon: AppIcons.key,
                // Replace (not push) so Back from the PIN screen goes to Home.
                onPressed: () => Navigator.pushReplacementNamed(context, Routes.lockPin, arguments: app),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
