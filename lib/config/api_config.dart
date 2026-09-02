import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web - localhost-la run panna localhost use pannanum
      return 'http://localhost:5260/api';
    }
    // For Android/iOS mobile app - LAN IP use pannanum
    return 'http://192.168.1.47:5260/api';
  }
}
