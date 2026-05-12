import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomePage uses native pages instead of WebView for import and AI', () {
    final homeSource = File('lib/screens/home_page.dart').readAsStringSync();

    // Uses native Flutter navigation
    expect(homeSource, contains('PopScope'));
    expect(homeSource, contains('ImportCoursePage'));
    expect(homeSource, contains('AiChatPage'));

    // No WebView references
    expect(homeSource, isNot(contains('CourseWebToolsPage')));
    expect(homeSource, isNot(contains('webview_flutter')));
    expect(homeSource, isNot(contains('WebViewWidget')));
  });

  test('Import page provides native text parsing UI', () {
    final source = File('lib/screens/import_course_page.dart').readAsStringSync();

    expect(source, contains('TextField'));
    expect(source, contains('解析预览'));
    expect(source, contains('ListView.builder'));
    expect(source, contains('_parseText('));
  });

  test('AI chat page provides native chat UI', () {
    final source = File('lib/screens/ai_chat_page.dart').readAsStringSync();

    expect(source, contains('ListView.builder'));
    expect(source, contains('_ChatBubble'));
    expect(source, contains('_send('));
    expect(source, contains('IconButton'));
  });
}
