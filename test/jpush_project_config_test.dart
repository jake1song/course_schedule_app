import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android project is configured for JPush notifications', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final authController =
        File('lib/auth/auth_controller.dart').readAsStringSync();

    expect(pubspec, contains('jpush_flutter'));
    expect(buildGradle, contains('JPUSH_PKGNAME'));
    expect(buildGradle, contains('JPUSH_APPKEY'));
    expect(buildGradle, contains('JPUSH_CHANNEL'));
    expect(buildGradle, contains('XIAOMI_APPID'));
    expect(buildGradle, contains('XIAOMI_APPKEY'));
    expect(buildGradle, contains('HUAWEI_APPID'));
    expect(buildGradle, contains('HUAWEI_CPID'));
    expect(buildGradle, contains('HONOR_APPID'));
    expect(buildGradle, contains('OPPO_APPID'));
    expect(buildGradle, contains('OPPO_APPKEY'));
    expect(buildGradle, contains('OPPO_APPSECRET'));
    expect(buildGradle, contains('VIVO_APPID'));
    expect(buildGradle, contains('VIVO_APPKEY'));
    expect(buildGradle, contains('cn.jiguang.sdk.plugin:xiaomi'));
    expect(buildGradle, contains('cn.jiguang.sdk.plugin:huawei'));
    expect(buildGradle, contains('cn.jiguang.sdk.plugin:honor'));
    expect(buildGradle, contains('cn.jiguang.sdk.plugin:oppo'));
    expect(buildGradle, contains('cn.jiguang.sdk.plugin:vivo'));
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('com.huawei.hms.client.appid'));
    expect(main, contains('Provider<PushDeviceApi>'));
    expect(main, contains('Provider<PushRegistrar>'));
    expect(authController, contains('registerAndBind'));
  });
}
