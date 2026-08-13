import 'package:flutter/foundation.dart';

/// Simple debug logger utility.
abstract final class AppLogger {
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[HomeGenny] $message');
      if (error != null) debugPrint('[HomeGenny] Error: $error');
      if (stackTrace != null) debugPrint('[HomeGenny] $stackTrace');
    }
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[HomeGenny ERROR] $message');
    if (error != null) debugPrint('[HomeGenny ERROR] $error');
    if (stackTrace != null) debugPrint('[HomeGenny ERROR] $stackTrace');
  }

  static void i(String message) {
    if (kDebugMode) {
      debugPrint('[HomeGenny INFO] $message');
    }
  }
  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[HomeGenny WARN] $message');
    if (error != null) debugPrint('[HomeGenny WARN] $error');
    if (stackTrace != null) debugPrint('[HomeGenny WARN] $stackTrace');
  }
}
