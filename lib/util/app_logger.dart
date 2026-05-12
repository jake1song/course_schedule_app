import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  static LogLevel level = kDebugMode ? LogLevel.debug : LogLevel.info;

  static void debug(String message) {
    if (level.index <= LogLevel.debug.index) {
      debugPrint('[D] $message');
    }
  }

  static void info(String message) {
    if (level.index <= LogLevel.info.index) {
      debugPrint('[I] $message');
    }
  }

  static void warn(String message) {
    if (level.index <= LogLevel.warn.index) {
      debugPrint('[W] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('[E] $message ${error ?? ''}');
    if (stack != null) debugPrint(stack.toString());
  }
}
