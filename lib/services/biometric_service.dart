import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// The outcome of asking for a fingerprint (or the phone's screen lock).
enum AuthResult {
  success,
  cancelled, // you closed the popup, or the system closed it
  unavailable, // no fingerprint enrolled / sensor not available
  lockedOut, // too many failed fingerprints: Android blocks it for a while
  error,
}

/// A small wrapper around the local_auth package.
///
/// Important: apps can't read the fingerprint sensor directly. They ask
/// Android to show its own fingerprint popup, and Android tells us if it
/// worked. That's what every call here does.
class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();

  /// True if at least one fingerprint is saved on the phone.
  Future<bool> hasFingerprint() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  /// Shows Android's fingerprint popup. Fingerprint only, no phone PIN.
  Future<AuthResult> fingerprint({required String title}) =>
      _authenticate(title: title, biometricOnly: true);

  /// Shows Android's popup that also accepts the phone's own screen lock
  /// (PIN, pattern or password). Used for "Forgot PIN?".
  Future<AuthResult> screenLock({required String title}) =>
      _authenticate(title: title, biometricOnly: false);

  Future<AuthResult> _authenticate({required String title, required bool biometricOnly}) async {
    try {
      final ok = await _auth.authenticate(
        // Fingerprint: no extra text. Android already shows its own
        // "Touch the fingerprint sensor" line, so ours would appear twice.
        // Empty text lines are hidden by Android.
        localizedReason: biometricOnly ? '' : 'Use your phone’s screen lock',
        biometricOnly: biometricOnly,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: title,
            signInHint: '', // hides the default "Verify identity" line
            cancelButton: 'Cancel',
          ),
        ],
      );
      return ok ? AuthResult.success : AuthResult.cancelled;
    } on LocalAuthException catch (e) {
      // Turn the many error codes into the few cases our screens care about.
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.authInProgress => AuthResult.cancelled,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable => AuthResult.unavailable,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => AuthResult.lockedOut,
        _ => AuthResult.error,
      };
    }
  }
}
