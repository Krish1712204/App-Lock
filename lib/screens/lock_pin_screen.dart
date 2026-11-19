import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/common.dart';
import '../widgets/pin_widgets.dart';

/// Screen 6 (design/LockPin.html): type the PIN to open a locked app.
///
/// Phase 1: checks against the PIN you chose on the Set PIN screen
/// (kept in memory). Try a wrong PIN to see the red "tries left" state.
class LockPinScreen extends StatefulWidget {
  const LockPinScreen({super.key, required this.app});

  final FakeApp app;

  @override
  State<LockPinScreen> createState() => _LockPinScreenState();
}

class _LockPinScreenState extends State<LockPinScreen> {
  final _store = FakeStore.instance;
  String _entered = '';
  bool _wrong = false; // true right after a wrong PIN: dots turn red

  int get _pinLength => _store.pin.length;
  bool get _outOfTries => _store.pinTriesLeft <= 0;

  void _addDigit(String d) {
    if (_outOfTries) return;
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
    setState(() {
      if (_wrong) {
        _wrong = false;
        _entered = '';
      } else if (_entered.isNotEmpty) {
        _entered = _entered.substring(0, _entered.length - 1);
      }
    });
  }

  void _check() {
    if (_entered == _store.pin) {
      _store.pinTriesLeft = FakeStore.maxPinTries; // reset after success
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.app.name} unlocked (preview)')),
      );
    } else {
      setState(() {
        _wrong = true;
        _store.pinTriesLeft--;
      });
    }
  }

  String get _errorText {
    final n = _store.pinTriesLeft;
    if (n <= 0) return 'No tries left · use your fingerprint';
    return 'Wrong PIN · $n ${n == 1 ? 'try' : 'tries'} left';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final app = widget.app;

    return Scaffold(
      body: SafeArea(
        child: FillScroll(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 32),
          child: Column(
            children: [
              LetterTile(app: app, size: 60, radius: 19, fontSize: 26),
              const SizedBox(height: 20),
              Text(
                'Enter PIN to open ${app.name}',
                textAlign: TextAlign.center,
                style: AppText.heading(22, weight: FontWeight.w600, color: c.text),
              ),
              const SizedBox(height: 36),
              PinDots(total: _pinLength, filled: _wrong ? _pinLength : _entered.length, error: _wrong),
              const SizedBox(height: 14),
              // Always reserve this space, so the layout doesn't jump.
              SizedBox(
                height: 20,
                child: (_wrong || _outOfTries)
                    ? Semantics(
                        liveRegion: true, // TalkBack reads it out, like role="alert"
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(AppIcons.alertTriangle, size: 16, color: c.error),
                            const SizedBox(width: 6),
                            Text(_errorText, style: AppText.body(14, weight: FontWeight.w500, color: c.error)),
                          ],
                        ),
                      )
                    : null,
              ),
              const Spacer(),
              const SizedBox(height: 32),
              PinKeypad(
                style: KeypadStyle.round,
                onDigit: _addDigit,
                onDelete: _deleteDigit,
                onFingerprint: () => Navigator.pushReplacementNamed(context, Routes.lock, arguments: app),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Screen-lock unlock comes in Phase 2')),
                ),
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
    );
  }
}
