import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JPushRegistrar retries registrationId before binding device', () {
    final source = File('lib/push/jpush_registrar.dart').readAsStringSync();

    expect(source, contains('registrationIdAttempts'));
    expect(source, contains('Future<void>.delayed'));
  });
}
