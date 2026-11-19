import 'package:applock/services/pin_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tests can't use the phone's real secure storage, so we give the package
  // an empty in-memory pretend storage before each test.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('the hash depends on both the PIN and the salt', () {
    final saltA = List<int>.filled(16, 1);
    final saltB = List<int>.filled(16, 2);
    // Same PIN + same salt → same hash (so checking works).
    expect(PinStore.hashPin('2580', saltA), PinStore.hashPin('2580', saltA));
    // Different PIN or different salt → different hash.
    expect(PinStore.hashPin('2580', saltA), isNot(PinStore.hashPin('2581', saltA)));
    expect(PinStore.hashPin('2580', saltA), isNot(PinStore.hashPin('2580', saltB)));
  });

  test('saves a hash (never the PIN) and checks it', () async {
    final store = PinStore();
    expect(await store.hasPin(), isFalse);

    await store.savePin('2580');
    expect(await store.hasPin(), isTrue);
    expect(await store.pinLength(), 4);

    // The PIN itself must not appear anywhere in storage.
    final everything = await const FlutterSecureStorage().readAll();
    expect(everything.values.any((v) => v == '2580'), isFalse);

    expect((await store.check('2580')).status, PinCheck.correct);
    expect((await store.check('1111')).status, PinCheck.wrong);
  });

  test('5 wrong tries pause the keypad, then a good PIN works after', () async {
    final store = PinStore();
    await store.savePin('2580');

    for (var left = 4; left >= 1; left--) {
      final r = await store.check('0000');
      expect(r.status, PinCheck.wrong);
      expect(r.triesLeft, left);
    }
    final fifth = await store.check('0000');
    expect(fifth.status, PinCheck.lockedOut);

    // Even the right PIN is refused during the pause.
    expect((await store.check('2580')).status, PinCheck.lockedOut);

    // After a fingerprint/screen-lock unlock, the pause is cleared.
    await store.resetTries();
    expect((await store.check('2580')).status, PinCheck.correct);
  });
}
