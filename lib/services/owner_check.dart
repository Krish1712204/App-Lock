import 'package:flutter/material.dart';

import 'biometric_service.dart';
import 'pin_store.dart';

/// "Is this really you?" before App Lock gets WEAKER: switching an app's
/// lock off, or turning protection off. (Opening App Lock and locking more
/// apps never asks.)
///
/// It shows Android's popup, which takes your fingerprint or your phone's
/// own PIN/pattern. If the phone has no screen lock at all, it asks for
/// your App Lock PIN instead.
///
/// A yes is remembered for [trustTime], so removing several apps in a row
/// asks only once.
class OwnerCheck {
  OwnerCheck._();

  static const trustTime = Duration(minutes: 1);
  static DateTime? _trustedUntil;

  /// True if it's you (or you were checked less than a minute ago).
  /// [title] says what's about to happen, e.g. "Remove lock from WhatsApp".
  static Future<bool> confirm(BuildContext context, String title) async {
    final until = _trustedUntil;
    if (until != null && DateTime.now().isBefore(until)) return true;

    final result = await BiometricService.instance.screenLock(title: title);
    if (!context.mounted) return false;

    var ok = false;
    switch (result) {
      case AuthResult.success:
        ok = true;
      case AuthResult.cancelled:
        ok = false; // you closed the popup: nothing changes
      case AuthResult.unavailable:
        // No screen lock on this phone: use App Lock's own PIN.
        ok = await _askAppLockPin(context, title);
      case AuthResult.lockedOut:
      case AuthResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t check it’s you. Try again in a moment.')),
        );
    }
    if (ok) _trustedUntil = DateTime.now().add(trustTime);
    return ok;
  }

  /// A small dialog: type your App Lock PIN.
  static Future<bool> _askAppLockPin(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _PinDialog(title: title),
    );
    return result ?? false;
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title});

  final String title;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await PinStore.instance.check(_controller.text);
    if (!mounted) return;
    switch (result.status) {
      case PinCheck.correct:
        Navigator.pop(context, true);
        return;
      case PinCheck.wrong:
        _error = 'Wrong PIN · ${result.triesLeft} ${result.triesLeft == 1 ? 'try' : 'tries'} left';
      case PinCheck.lockedOut:
        _error = 'Too many tries · wait ${result.lockoutLeft.inSeconds + 1} s';
    }
    _controller.clear();
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(labelText: 'Your App Lock PIN', errorText: _error),
        onSubmitted: (_) => _check(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: _checking ? null : _check, child: const Text('OK')),
      ],
    );
  }
}
