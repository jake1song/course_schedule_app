import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native push dependencies and Android hooks are removed', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final authController =
        File('lib/auth/auth_controller.dart').readAsStringSync();
    final homePage = File('lib/screens/home_page.dart').readAsStringSync();

    expect(pubspec, isNot(contains('jpush_flutter')));
    expect(buildGradle, isNot(contains('jpush')));
    expect(buildGradle, isNot(contains('cn.jiguang')));
    expect(buildGradle, isNot(contains('JPUSH')));
    expect(buildGradle, isNot(contains('XIAOMI')));
    expect(buildGradle, isNot(contains('HUAWEI')));
    expect(buildGradle, isNot(contains('HONOR')));
    expect(buildGradle, isNot(contains('OPPO')));
    expect(buildGradle, isNot(contains('VIVO')));
    expect(manifest, isNot(contains('POST_NOTIFICATIONS')));
    expect(manifest, isNot(contains('AppJPushReceiver')));
    expect(manifest, isNot(contains('JPushCustomService')));
    expect(manifest, isNot(contains('hms.client')));
    expect(main, isNot(contains('Push')));
    expect(authController, isNot(contains('Push')));
    expect(homePage, isNot(contains('NativePush')));
    // home_page.dart must not import any push-related packages
    expect(homePage, isNot(contains('package:jpush_flutter')));
    expect(Directory('lib/push').existsSync(), false);
    expect(
      File(
        'android/app/src/main/kotlin/com/szk333333/course_schedule_app/AppJPushReceiver.kt',
      ).existsSync(),
      false,
    );
  });
}
