import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Using local IP so it can be accessed from mobile devices on same network
      return 'http://192.168.1.47:5260/api';
    }
    // For Android/iOS emulator, you'd use 10.0.2.2 or localhost respectively
    // But since we are targeting mobile physical devices on same network, use local IP:
    return 'http://192.168.1.47:5260/api';
  }
}
