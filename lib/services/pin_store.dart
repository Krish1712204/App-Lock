import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What happened when a PIN was checked.
enum PinCheck { correct, wrong, lockedOut }

/// The answer from [PinStore.check].
class PinCheckResult {
  const PinCheckResult(this.status, {this.triesLeft = 0, this.lockoutLeft = Duration.zero});

  final PinCheck status;
  final int triesLeft; // after a wrong PIN: how many tries remain
  final Duration lockoutLeft; // when locked out: how long to wait
}

/// Saves and checks the backup PIN. The PIN itself is NEVER stored.
///
/// How it works:
/// 1. When you set a PIN, we make a random "salt" (16 random bytes).
/// 2. We hash salt + PIN with SHA-256, then hash the result again and again
///    ([hashRounds] times). Each repeat makes guessing slower.
/// 3. Only the salt and the final hash are saved, in flutter_secure_storage
///    (encrypted with a key kept in the phone's secure hardware).
/// 4. To check a PIN, we hash what you typed with the same salt and
///    compare the two hashes.
class PinStore {
  PinStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  /// One shared copy for the whole app.
  static final instance = PinStore();

  static const maxTries = 5;
  static const lockoutDuration = Duration(seconds: 30);
  static const hashRounds = 10000;

  final FlutterSecureStorage _storage;

  // Names of the saved values.
  static const _kSalt = 'pin_salt';
  static const _kHash = 'pin_hash';
  static const _kLength = 'pin_length';
  static const _kTriesLeft = 'pin_tries_left';
  static const _kLockoutUntil = 'pin_lockout_until'; // milliseconds since 1970

  /// True once a PIN has been set (used to skip the setup screens).
  Future<bool> hasPin() async => await _storage.read(key: _kHash) != null;

  /// How many digits the PIN has (the lock screen shows that many dots).
  Future<int> pinLength() async => int.tryParse(await _storage.read(key: _kLength) ?? '') ?? 4;

  /// Saves a new PIN (as salt + hash) and resets the wrong-try counter.
  Future<void> savePin(String pin) async {
    final salt = _randomBytes(16);
    final hash = await _hashInBackground(pin, salt);
    await _storage.write(key: _kSalt, value: base64Encode(salt));
    await _storage.write(key: _kHash, value: hash);
    await _storage.write(key: _kLength, value: '${pin.length}');
    await resetTries();
  }

  /// Checks a typed PIN. Counts wrong tries; after [maxTries] wrong tries,
  /// the keypad is blocked for [lockoutDuration].
  Future<PinCheckResult> check(String pin) async {
    final wait = await lockoutLeft();
    if (wait > Duration.zero) return PinCheckResult(PinCheck.lockedOut, lockoutLeft: wait);

    final saltText = await _storage.read(key: _kSalt);
    final savedHash = await _storage.read(key: _kHash);
    if (saltText == null || savedHash == null) {
      return const PinCheckResult(PinCheck.wrong); // no PIN set (shouldn't happen)
    }

    final typedHash = await _hashInBackground(pin, base64Decode(saltText));

    if (_sameText(typedHash, savedHash)) {
      await resetTries();
      return const PinCheckResult(PinCheck.correct);
    }

    // Wrong PIN: one try fewer.
    final left = await triesLeft() - 1;
    if (left <= 0) {
      // Out of tries: block for 30 s, then allow a fresh set of tries.
      final until = DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;
      await _storage.write(key: _kLockoutUntil, value: '$until');
      await _storage.write(key: _kTriesLeft, value: '$maxTries');
      return const PinCheckResult(PinCheck.lockedOut, lockoutLeft: lockoutDuration);
    }
    await _storage.write(key: _kTriesLeft, value: '$left');
    return PinCheckResult(PinCheck.wrong, triesLeft: left);
  }

  /// Tries remaining before the 30 s block.
  Future<int> triesLeft() async =>
      int.tryParse(await _storage.read(key: _kTriesLeft) ?? '') ?? maxTries;

  /// How long the keypad is still blocked (zero = not blocked).
  Future<Duration> lockoutLeft() async {
    final until = int.tryParse(await _storage.read(key: _kLockoutUntil) ?? '');
    if (until == null) return Duration.zero;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Called after any successful unlock (PIN, fingerprint or screen lock).
  Future<void> resetTries() async {
    await _storage.write(key: _kTriesLeft, value: '$maxTries');
    await _storage.delete(key: _kLockoutUntil);
  }

  /// The hashing recipe. "static" and pure (no storage), so tests can call it
  /// directly and it can run on a background isolate.
  static String hashPin(String pin, List<int> salt) {
    var digest = sha256.convert([...salt, ...utf8.encode(pin)]).bytes;
    for (var i = 1; i < hashRounds; i++) {
      digest = sha256.convert([...digest, ...salt]).bytes;
    }
    return base64Encode(digest);
  }

  /// Hashing 10,000 times takes a moment, so we run it on a background
  /// "isolate" (a separate worker thread). That way the keypad never freezes.
  /// It's static so the worker only gets the PIN and salt, nothing else.
  static Future<String> _hashInBackground(String pin, List<int> salt) =>
      Isolate.run(() => hashPin(pin, salt));

  /// Cryptographically secure random bytes (Random.secure uses the OS).
  static List<int> _randomBytes(int count) {
    final random = Random.secure();
    return List<int>.generate(count, (_) => random.nextInt(256));
  }

  /// Compares two strings in "constant time": it always looks at every
  /// character, so the time taken doesn't hint at how close a guess was.
  static bool _sameText(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
