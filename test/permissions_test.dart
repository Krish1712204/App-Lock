import 'package:applock/services/permissions_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts how many of the 4 permissions are done', () {
    const status = PermissionStatus(
      accessibility: true,
      watcherRunning: true,
      overlay: false,
      fingerprint: true,
      battery: false,
    );
    expect(status.doneCount, 2);
    expect(status.isAllowed(AppPermission.accessibility), isTrue);
    expect(status.isAllowed(AppPermission.overlay), isFalse);
    expect(status.isAllowed(AppPermission.battery), isFalse);
  });

  test('permission names match the ones Kotlin understands', () {
    // PermissionsHelper.open() in Kotlin switches on these exact words.
    expect(AppPermission.values.map((p) => p.name),
        ['accessibility', 'overlay', 'fingerprint', 'battery', 'appInfo']);
  });
}
