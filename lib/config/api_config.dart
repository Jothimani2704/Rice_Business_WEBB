import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Using local IP to allow both PC and Mobile (same network) to connect
      return 'http://192.168.1.47:5260/api';
    }
    // For Android/iOS emulator or mobile app
    return 'http://192.168.1.47:5260/api';
  }
}
