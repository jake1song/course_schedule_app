import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android receiver launches MainActivity when a JPush notification opens',
    () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      final buildGradle =
          File('android/app/build.gradle.kts').readAsStringSync();
      final receiver =
          File(
            'android/app/src/main/kotlin/com/szk333333/course_schedule_app/AppJPushReceiver.kt',
          ).readAsStringSync();

      expect(buildGradle, contains('cn.jiguang.sdk:jpush'));
      expect(manifest, contains('AppJPushReceiver'));
      expect(manifest, contains('cn.jpush.android.intent.RECEIVER_MESSAGE'));
      expect(manifest, contains('android:stopWithTask="false"'));
      expect(receiver, contains('onNotifyMessageOpened'));
      expect(receiver, contains('context.startActivity'));
      expect(receiver, contains('MainActivity::class.java'));
    },
  );
}
