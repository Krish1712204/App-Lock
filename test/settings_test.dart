import 'package:applock/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the settings map Kotlin sends', () {
    final s = AppSettings.fromMap({
      'fingerprintUnlock': false,
      'relockSeconds': 60,
      'lockOnScreenOff': false,
      'lockSystemApps': true,
      'hideRecents': false,
    });
    expect(s.fingerprintUnlock, isFalse);
    expect(s.relockDelay, RelockDelay.oneMinute);
    expect(s.lockOnScreenOff, isFalse);
    expect(s.lockSystemApps, isTrue);
    expect(s.hideRecents, isFalse);
  });

  test('missing values fall back to the defaults', () {
    final s = AppSettings.fromMap({});
    expect(s.fingerprintUnlock, isTrue);
    expect(s.relockDelay, RelockDelay.now);
    expect(s.lockSystemApps, isFalse);
  });

  test('relock choices map to the seconds Kotlin stores', () {
    expect(RelockDelay.values.map((d) => d.seconds), [0, 60, 300]);
    expect(RelockDelay.fromSeconds(300), RelockDelay.fiveMinutes);
    expect(RelockDelay.fromSeconds(42), RelockDelay.now); // unknown → safest
  });
}
