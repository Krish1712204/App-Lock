import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/pin_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/pin_widgets.dart';

/// Screen 2 (design/SetPin.html): choose a 4-6 digit backup PIN.
///
/// It works in stages on the same screen:
///   0. (Change PIN only) "Enter your current PIN": checked right away,
///      with the same 5 tries / 30 s pause as the lock screen.
///   1. "Create a backup PIN": type a PIN, tap Continue.
///   2. "Type your PIN again": type it again, tap Confirm.
/// If 1 and 2 match, the PIN is saved (as a salted hash, see PinStore).
///
/// [changing] = opened from Settings → "Change PIN": no "Step 1 of 2" bar,
/// stage 0 first, and after saving it goes back to Settings.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key, this.changing = false});

  /// Pass this as the route argument to open the screen in "change" mode.
  static const changeMode = 'change';

  final bool changing;

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  static const _minLength = 4;
  static const _maxLength = 6;

  late bool _verifying = widget.changing; // stage 0: checking the current PIN
  int _currentLength = 4; // digits in the current PIN (for stage 0 dots)
  String? _verifyError; // red text in stage 0, e.g. "Wrong PIN · 4 tries left"

  String _pin = ''; // digits typed in the current stage
  String? _firstPin; // the PIN from stage 1 (null = not in stage 2)
  bool _mismatch = false; // true after the two new PINs didn't match
  bool _busy = false; // true while hashing (checking or saving)

  bool get _confirming => _firstPin != null;

  /// How many digits this stage accepts.
  int get _limit => _verifying ? _currentLength : (_confirming ? _firstPin!.length : _maxLength);

  bool get _ready => !_verifying && (_confirming ? _pin.length == _firstPin!.length : _pin.length >= _minLength);

  @override
  void initState() {
    super.initState();
    if (_verifying) {
      PinStore.instance.pinLength().then((n) {
        if (mounted) setState(() => _currentLength = n);
      });
    }
  }

  void _addDigit(String d) {
    if (_busy || _pin.length >= _limit) return;
    setState(() {
      _pin += d;
      _mismatch = false;
      _verifyError = null;
    });
    // Stage 0 checks by itself once all digits are typed.
    if (_verifying && _pin.length == _currentLength) _checkCurrent();
  }

  void _deleteDigit() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  /// Stage 0: is this the current PIN?
  Future<void> _checkCurrent() async {
    setState(() => _busy = true);
    final result = await PinStore.instance.check(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
      switch (result.status) {
        case PinCheck.correct:
          _verifying = false; // on to stage 1
        case PinCheck.wrong:
          final n = result.triesLeft;
          _verifyError = 'Wrong PIN · $n ${n == 1 ? 'try' : 'tries'} left';
        case PinCheck.lockedOut:
          _verifyError = 'Too many tries · wait ${result.lockoutLeft.inSeconds + 1} s';
      }
    });
  }

  /// Back to stage 1, with everything cleared.
  void _startOver({bool mismatch = false}) {
    setState(() {
      _firstPin = null;
      _pin = '';
      _mismatch = mismatch;
    });
  }

  /// The small text under the dots.
  String get _hint {
    if (_verifying) return _verifyError ?? 'Type the PIN you use now';
    if (_mismatch) return 'The PINs didn’t match. Try again.';
    if (_confirming) return 'Type the same ${_firstPin!.length} numbers';
    if (_pin.isEmpty) return 'Tip: avoid 1234 or your birth year';
    if (_pin.length < _minLength) return '${_minLength - _pin.length} more to go';
    return 'Looks good';
  }

  bool get _hintIsError => (_verifying && _verifyError != null) || _mismatch;

  Future<void> _onContinue() async {
    // Stage 1 → stage 2.
    if (!_confirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
      });
      return;
    }

    // Stage 2: do they match?
    if (_pin != _firstPin) {
      _startOver(mismatch: true);
      return;
    }

    setState(() => _busy = true);
    await PinStore.instance.savePin(_pin);
    if (!mounted) return; // the screen was closed while saving

    if (widget.changing) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed')));
    } else {
      Navigator.pushNamed(context, Routes.permissions);
      // If you come back here with Back, start fresh.
      _startOver();
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final String title;
    final String body;
    if (_verifying) {
      title = 'Enter your current PIN';
      body = 'To change your PIN, first type the one you use now.';
    } else if (_confirming) {
      title = 'Type your PIN again';
      body = 'Just to make sure there’s no typo.';
    } else {
      title = widget.changing ? 'Choose a new PIN' : 'Create a backup PIN';
      body = 'You’ll use this when your fingerprint doesn’t work. Use 4 to 6 numbers.';
    }

    // PopScope: while confirming, Back returns to stage 1 instead of
    // leaving the screen.
    return PopScope(
      canPop: !_confirming,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _startOver();
      },
      child: Scaffold(
        body: SafeArea(
          child: FillScroll(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepHeader(stepLabel: widget.changing ? null : 'Step 1 of 2'),
                if (widget.changing)
                  const SizedBox(height: 24)
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 32),
                    child: StepProgress(done: 1),
                  ),
                Text(title, style: AppText.heading(28, letterSpacing: -0.4, height: 1.2, color: c.text)),
                const SizedBox(height: 10),
                Text(body, style: AppText.body(15, height: 1.5, color: c.muted)),
                const SizedBox(height: 44),
                PinDots(total: _limit, filled: _pin.length),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: Text(
                    _hint,
                    textAlign: TextAlign.center,
                    style: AppText.body(13, color: _hintIsError ? c.error : c.muted),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 24), // minimum gap on short screens
                PinKeypad(style: KeypadStyle.square, onDigit: _addDigit, onDelete: _deleteDigit),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _confirming ? 'Confirm' : 'Continue',
                  onPressed: _ready && !_busy ? _onContinue : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
