import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'HomePage renders the schedule in Flutter with native navigation',
    () {
      final source = File('lib/screens/home_page.dart').readAsStringSync();

      expect(source, contains('FutureBuilder<NativeCourseSchedule>'));
      expect(source, contains('rowsByWeek'));
      expect(source, contains('ListView.builder'));
      expect(source, contains('_openImport'));
      expect(source, contains('_openAi'));
      expect(source, isNot(contains('_webViewWidget')));
      expect(source, isNot(contains('WebViewWidget')));
      expect(source, isNot(contains('CourseWebToolsPage')));
    },
  );

  test('Import and AI are native Flutter pages, not WebView wrappers', () {
    final importSource = File('lib/screens/import_course_page.dart').readAsStringSync();
    final aiSource = File('lib/screens/ai_chat_page.dart').readAsStringSync();

    expect(importSource, isNot(contains('webview')));
    expect(importSource, isNot(contains('WebView')));
    expect(aiSource, isNot(contains('webview')));
    expect(aiSource, isNot(contains('WebView')));
    expect(importSource, contains('class ImportCoursePage'));
    expect(aiSource, contains('class AiChatPage'));
  });

  test('NativeCourse model lives in a dedicated models file', () {
    final source = File('lib/models/native_course.dart').readAsStringSync();

    expect(source, contains('class NativeCourse'));
    expect(source, contains('class NativeCourseSchedule'));
    expect(source, contains('class ScheduleRow'));
    expect(source, contains('factory NativeCourseSchedule.fromCourses'));
  });

  test('RefreshIndicator waits for the native course reload request', () {
    final source = File('lib/screens/home_page.dart').readAsStringSync();

    expect(source, contains('Future<void> _reloadCourses()'));
    expect(source, contains('final reloaded = _loadNativeCourses();'));
    expect(source, contains('await reloaded;'));
    expect(source, contains('onRefresh: _reloadCourses'));
  });

  test('native course request delegates to AuthApi with bounded timeout', () {
    final source = File('lib/screens/home_page.dart').readAsStringSync();

    expect(source, contains('authenticatedGet'));
    expect(source, isNot(contains('http.get')));

    final authApiSource = File('lib/auth/auth_api.dart').readAsStringSync();
    expect(authApiSource, contains('.timeout(_timeout)'));
    expect(authApiSource, contains('Duration(seconds: 10)'));
  });
}
