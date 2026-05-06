import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main Android manifest declares network access for all build types', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.INTERNET"'),
    );
    expect(
      manifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
  });

  test('Android package is migrated to the com namespace', () {
    final buildGradle =
        File('android/app/build.gradle.kts').readAsStringSync();
    final mainActivity = File(
      'android/app/src/main/kotlin/com/szk333333/course_schedule_app/MainActivity.kt',
    );

    expect(
      buildGradle,
      contains('namespace = "com.szk333333.course_schedule_app"'),
    );
    expect(
      buildGradle,
      contains('applicationId = "com.szk333333.course_schedule_app"'),
    );
    expect(mainActivity.existsSync(), true);
    expect(
      mainActivity.readAsStringSync(),
      contains('package com.szk333333.course_schedule_app'),
    );
    expect(
      Directory('android/app/src/main/kotlin/fun').existsSync(),
      false,
      reason: 'The old fun.* package directory should not remain.',
    );
  });

  test('Android NDK version is locked to the installed ASCII SDK version', () {
    final buildGradle =
        File('android/app/build.gradle.kts').readAsStringSync();

    expect(buildGradle, contains('ndkVersion = "27.0.12077973"'));
  });
}
