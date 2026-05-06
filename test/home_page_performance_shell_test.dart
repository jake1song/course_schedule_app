import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomePage avoids Flutter overlays above the Android WebView', () {
    final source = File('lib/screens/home_page.dart').readAsStringSync();

    expect(source, contains('appBar: AppBar'));
    expect(source, contains('_webViewWidget = WebViewWidget'));
    expect(source, contains('LinearProgressIndicator'));
    expect(source, isNot(contains('Positioned(')));
    expect(source, isNot(contains('withValues(alpha')));
  });
}
