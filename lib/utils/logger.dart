import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static const String _prefix = '[FlipbookApp]';

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag);
    }
  }

  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag);
    if (error != null) {
      debugPrint('$_prefix [ERROR] Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('$_prefix [ERROR] Stack trace: $stackTrace');
    }
  }

  static void _log(LogLevel level, String message, String? tag) {
    final tagStr = tag != null ? '[$tag]' : '';
    final levelStr = level.name.toUpperCase();
    debugPrint('$_prefix [$levelStr] $tagStr $message');
  }
}