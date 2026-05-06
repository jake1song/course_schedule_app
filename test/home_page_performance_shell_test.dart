import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomePage avoids Flutter overlays above the Android WebView', () {
    final source = File('lib/screens/home_page.dart').readAsStringSync();

    expect(source, contains('_webViewWidget = _buildWebViewWidget()'));
    expect(source, contains('AndroidWebViewWidgetCreationParams'));
    expect(source, contains('displayWithHybridComposition: true'));
    expect(source, contains("'app': '1'"));
    expect(source, isNot(contains('appBar: AppBar')));
    expect(source, isNot(contains('LinearProgressIndicator')));
    expect(source, isNot(contains('Positioned(')));
    expect(source, isNot(contains('withValues(alpha')));
  });
}
