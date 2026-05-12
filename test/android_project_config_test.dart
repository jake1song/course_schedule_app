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
  });

  test('cleartext network config is restricted to debug builds', () {
    final debugManifest =
        File('android/app/src/debug/AndroidManifest.xml').readAsStringSync();
    final debugConfig =
        File('android/app/src/debug/res/xml/network_security_config.xml');

    expect(
      debugManifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(debugConfig.existsSync(), true);
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

  test('in-app APK installer declares Android install contract', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final mainActivity =
        File(
          'android/app/src/main/kotlin/com/szk333333/course_schedule_app/MainActivity.kt',
        ).readAsStringSync();
    final filePaths =
        File('android/app/src/main/res/xml/file_paths.xml').readAsStringSync();

    expect(
      manifest,
      contains('android.permission.REQUEST_INSTALL_PACKAGES'),
    );
    expect(manifest, contains('androidx.core.content.FileProvider'));
    expect(manifest, contains('@xml/file_paths'));
    expect(filePaths, contains('<external-files-path'));
    expect(mainActivity, contains('FileProvider.getUriForFile'));
    expect(mainActivity, contains('Intent.FLAG_GRANT_READ_URI_PERMISSION'));
  });

  test('native APK installer routes users to unknown app source settings', () {
    final mainActivity =
        File(
          'android/app/src/main/kotlin/com/szk333333/course_schedule_app/MainActivity.kt',
        ).readAsStringSync();

    expect(mainActivity, contains('packageManager.canRequestPackageInstalls()'));
    expect(
      mainActivity,
      contains('Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES'),
    );
    expect(mainActivity, contains('INSTALL_PERMISSION_REQUIRED'));
  });
}
