import 'package:flutter/foundation.dart';

class AppLog {
  static void d(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static void e(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
