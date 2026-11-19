import 'package:flutter/material.dart';

import '../data/fake_data.dart';
import '../routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/pin_widgets.dart';

/// Screen 2 (design/SetPin.html): type a 4-6 digit backup PIN.
///
/// Also opened from Settings → "Change PIN". In that case [changing] is true:
/// there's no "Step 1 of 2" bar, and Continue goes back to Settings.
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

  String _pin = ''; // the digits typed so far

  bool get _ready => _pin.length >= _minLength;

  void _addDigit(String d) {
    if (_pin.length < _maxLength) setState(() => _pin += d);
  }

  void _deleteDigit() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  /// The small text under the dots changes as you type.
  String get _hint {
    if (_pin.isEmpty) return 'Tip: avoid 1234 or your birth year';
    if (_pin.length < _minLength) return '${_minLength - _pin.length} more to go';
    return 'Looks good';
  }

  void _continue() {
    // Phase 1: keep the PIN in memory only. Phase 2 saves a salted hash.
    FakeStore.instance.pin = _pin;
    if (widget.changing) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed')));
    } else {
      Navigator.pushNamed(context, Routes.permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
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
              Text(
                widget.changing ? 'Choose a new PIN' : 'Create a backup PIN',
                style: AppText.heading(28, letterSpacing: -0.4, height: 1.2, color: c.text),
              ),
              const SizedBox(height: 10),
              Text(
                'You’ll use this when your fingerprint doesn’t work. Use 4 to 6 numbers.',
                style: AppText.body(15, height: 1.5, color: c.muted),
              ),
              const SizedBox(height: 44),
              PinDots(total: _maxLength, filled: _pin.length),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 20,
                child: Text(
                  _hint,
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: c.muted),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24), // minimum gap on short screens
              PinKeypad(style: KeypadStyle.square, onDigit: _addDigit, onDelete: _deleteDigit),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Continue', onPressed: _ready ? _continue : null),
            ],
          ),
        ),
      ),
    );
  }
}
