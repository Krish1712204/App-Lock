import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:applock/main.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
  }

  testWidgets('Set PIN asks twice and catches a mismatch', (tester) async {
    // Use the Edge 40 Neo screen size: 1080x2400 pixels ≈ 411x914 logical.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AppLockApp());
    expect(find.text('Lock any app with your fingerprint'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Create a backup PIN'), findsOneWidget);

    // Stage 1: 4 digits → "Looks good" → Continue.
    await typePin(tester, '2580');
    expect(find.text('Looks good'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    // Stage 2: type a different PIN → back to stage 1 with an error.
    expect(find.text('Type your PIN again'), findsOneWidget);
    await typePin(tester, '1111');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Create a backup PIN'), findsOneWidget);
    expect(find.text('The PINs didn’t match. Try again.'), findsOneWidget);
  });
}
