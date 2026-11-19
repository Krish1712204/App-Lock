import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:applock/main.dart';

void main() {
  // A quick check that the app starts and the setup flow moves forward.
  testWidgets('Welcome opens Set PIN, and Continue needs 4 digits', (tester) async {
    // Use the Edge 40 Neo screen size: 1080x2400 pixels ≈ 411x914 logical.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AppLockApp());
    expect(find.text('Lock any app with your fingerprint'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Create a backup PIN'), findsOneWidget);

    // Type 4 digits: the hint changes to "Looks good".
    for (final d in ['2', '5', '8', '0']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    expect(find.text('Looks good'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Allow 4 permissions'), findsOneWidget);
  });
}
