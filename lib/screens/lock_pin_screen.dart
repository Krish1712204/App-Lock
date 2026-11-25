import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../lock/lock_controller.dart';
import '../routes.dart';
import '../services/biometric_service.dart';
import '../services/pin_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/common.dart';
import '../widgets/pin_widgets.dart';
import '../widgets/success_check.dart';

/// Screen 6 (design/LockPin.html): type the PIN to open a locked app.
///
/// - Checks the PIN against the saved hash (PinStore).
/// - Wrong PIN: red dots + "Wrong PIN · N tries left".
/// - 5 wrong tries: the keypad pauses for 30 seconds (with a countdown).
/// - "Forgot PIN?": unlock with the phone's own screen lock instead.
class LockPinScreen extends StatefulWidget {
  const LockPinScreen({super.key, required this.app});

  final AppInfo app;

  @override
  State<LockPinScreen> createState() => _LockPinScreenState();
}

class _LockPinScreenState extends State<LockPinScreen> {
  final _pins = PinStore.instance;

  int? _pinLength; // null until loaded from storage
  String _entered = '';
  bool _wrong = false; // true right after a wrong PIN: dots turn red
  bool _checking = false; // true while the hash is being compared
  bool _success = false; // true after a correct PIN: shows the check mark
  int _triesLeft = PinStore.maxTries;
  int _waitSeconds = 0; // > 0 while the keypad is paused
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdown?.cancel(); // stop the timer when the screen closes
    super.dispose();
  }

  /// Read the PIN length and any running pause from storage.
  Future<void> _load() async {
    final length = await _pins.pinLength();
    final tries = await _pins.triesLeft();
    final wait = await _pins.lockoutLeft();
    if (!mounted) return;
    setState(() {
      _pinLength = length;
      _triesLeft = tries;
    });
    if (wait > Duration.zero) _startCountdown(wait);
  }

  void _startCountdown(Duration wait) {
    _countdown?.cancel();
    setState(() {
      _waitSeconds = wait.inSeconds + 1; // round up, so it never shows 0 early
      _wrong = false;
      _entered = '';
    });
    // Tick once per second until the pause is over.
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _waitSeconds--);
      if (_waitSeconds <= 0) {
        timer.cancel();
        setState(() => _triesLeft = PinStore.maxTries);
      }
    });
  }

  bool get _blocked => _waitSeconds > 0 || _checking || _success || _pinLength == null;

  void _addDigit(String d) {
    if (_blocked) return;
    setState(() {
      // The first key after a wrong try clears the red dots.
      if (_wrong) {
        _wrong = false;
        _entered = '';
      }
      _entered += d;
    });
    // Check automatically once enough digits are typed.
    if (_entered.length == _pinLength) _check();
  }

  void _deleteDigit() {
    if (_blocked) return;
    setState(() {
      if (_wrong) {
        _wrong = false;
        _entered = '';
      } else if (_entered.isNotEmpty) {
        _entered = _entered.substring(0, _entered.length - 1);
      }
    });
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await _pins.check(_entered);
    if (!mounted) return;
    setState(() => _checking = false);

    switch (result.status) {
      case PinCheck.correct:
        _unlocked();
      case PinCheck.wrong:
        setState(() {
          _wrong = true;
          _triesLeft = result.triesLeft;
        });
      case PinCheck.lockedOut:
        _startCountdown(result.lockoutLeft);
    }
  }

  /// "Forgot PIN?": Android's popup with the phone's own PIN/pattern.
  Future<void> _useScreenLock() async {
    final result = await BiometricService.instance.screenLock(title: 'Unlock ${widget.app.name}');
    if (!mounted) return;
    switch (result) {
      case AuthResult.success:
        await _pins.resetTries();
        _unlocked();
      case AuthResult.cancelled:
        break; // you closed the popup: stay here
      case AuthResult.unavailable:
        _toast('Set up a screen lock in your phone’s Settings first.');
      case AuthResult.lockedOut:
      case AuthResult.error:
        _toast('Couldn’t open the screen lock. Try again in a moment.');
    }
  }

  Future<void> _unlocked() async {
    _countdown?.cancel();
    // The PIN dots turn into a check mark for a moment.
    setState(() => _success = true);
    await SuccessCheck.pause(context);
    if (!mounted) return;
    // Real lock: closes (fading out) and shows the app. Preview: back to Home.
    await LockController.unlocked(context, widget.app);
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// The red line under the dots (null = show nothing).
  String? get _message {
    if (_waitSeconds > 0) return 'Too many tries · wait $_waitSeconds s';
    if (_wrong) return 'Wrong PIN · $_triesLeft ${_triesLeft == 1 ? 'try' : 'tries'} left';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final app = widget.app;
    final length = _pinLength ?? 4;
    final message = _message;

    // Real lock: Back goes to the home screen, never into the locked app.
    return PopScope(
      canPop: !LockController.isRealLock,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) LockController.back();
      },
      child: Scaffold(
        body: SafeArea(
          child: FillScroll(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 32),
            child: Column(
              children: [
                AppTile(app: app, size: 60, radius: 19, fontSize: 26),
                const SizedBox(height: 20),
                Text(
                  'Enter PIN to open ${app.name}',
                  textAlign: TextAlign.center,
                  style: AppText.heading(22, weight: FontWeight.w600, color: c.text),
                ),
                const SizedBox(height: 36),
                // Correct PIN: a check mark pops in over the dots. The dots
                // stay (invisible), so nothing else on the screen moves.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: _success ? 0 : 1,
                      child: PinDots(total: length, filled: _wrong ? length : _entered.length, error: _wrong),
                    ),
                    if (_success)
                      // Same size as the dots row, but lets the 56 px check
                      // stick out of it, centered.
                      const Positioned.fill(
                        child: OverflowBox(maxWidth: 56, maxHeight: 56, child: SuccessCheck(size: 56)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Always reserve this space, so the layout doesn't jump.
                SizedBox(
                  height: 20,
                  child: message == null
                      ? null
                      : Semantics(
                          liveRegion: true, // TalkBack reads it out, like role="alert"
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(AppIcons.alertTriangle, size: 16, color: c.error),
                              const SizedBox(width: 6),
                              Text(
                                message,
                                style: AppText.body(14, weight: FontWeight.w500, color: c.error),
                              ),
                            ],
                          ),
                        ),
                ),
                const Spacer(),
                const SizedBox(height: 32),
                // Dim the keypad while it's paused.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _waitSeconds > 0 ? 0.4 : 1,
                  child: PinKeypad(
                    style: KeypadStyle.round,
                    onDigit: _addDigit,
                    onDelete: _deleteDigit,
                    // Hidden when fingerprint unlock is off in Settings.
                    onFingerprint: LockController.fingerprintEnabled
                        ? () => Navigator.pushReplacementNamed(context, Routes.lock, arguments: app)
                        : null,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _useScreenLock,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        'Forgot PIN? Use your phone’s screen lock',
                        textAlign: TextAlign.center,
                        style: AppText.body(14, weight: FontWeight.w500, color: c.accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
