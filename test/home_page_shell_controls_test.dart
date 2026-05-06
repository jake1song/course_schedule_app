import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomePage provides native shell controls for WebView navigation', () {
    final source = File('lib/screens/home_page.dart').readAsStringSync();

    expect(source, contains('PopScope'));
    expect(source, contains('canGoBack()'));
    expect(source, contains('goBack()'));
    expect(source, contains('Icons.refresh'));
    expect(source, contains('Icons.logout'));
    expect(source, contains('enableZoom(false)'));
    expect(source, contains('setBackgroundColor'));
  });
}
