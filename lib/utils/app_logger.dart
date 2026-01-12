import 'package:flutter/foundation.dart';

/// Logger Utility
/// Production'da debug logları devre dışı bırakır
class AppLogger {
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      print('❌ $message${error != null ? ': $error' : ''}');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      print('✅ $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ $message');
    }
  }
}
