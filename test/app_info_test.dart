import 'dart:typed_data';

import 'package:applock/data/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the map Kotlin sends', () {
    final app = AppInfo.fromMap({
      'packageName': 'com.whatsapp',
      'name': 'WhatsApp',
      'icon': Uint8List.fromList([1, 2, 3]),
    });
    expect(app.packageName, 'com.whatsapp');
    expect(app.name, 'WhatsApp');
    expect(app.icon, isNotNull);
    expect(app.letter, 'W');
  });

  test('an app with no name falls back to its package name', () {
    final app = AppInfo.fromMap({'packageName': 'com.example.x', 'name': '  '});
    expect(app.name, 'com.example.x');
    expect(app.icon, isNull);
  });

  test('sorts A to Z ignoring case', () {
    final apps = [
      const AppInfo(packageName: 'b', name: 'youTube'),
      const AppInfo(packageName: 'a', name: 'Gallery'),
      const AppInfo(packageName: 'c', name: 'chrome'),
    ]..sort(AppInfo.byName);
    expect(apps.map((a) => a.name), ['chrome', 'Gallery', 'youTube']);
  });
}
