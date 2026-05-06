import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android WebView shell does not resize during keyboard animation', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final homePage = File('lib/screens/home_page.dart').readAsStringSync();

    expect(manifest, contains('android:windowSoftInputMode="adjustNothing"'));
    expect(homePage, contains('resizeToAvoidBottomInset: false'));
  });
}
