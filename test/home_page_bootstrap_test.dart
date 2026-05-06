import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebView token bootstrap does not force a full page reload', () {
    final source = File('lib/screens/home_page.dart').readAsStringSync();

    expect(source, isNot(contains('location.reload()')));
    expect(source, contains('loadAppData()'));
    expect(source, contains('setLockedState(false)'));
  });
}
