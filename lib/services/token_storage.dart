import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } else {
      await _storage.write(key: _keyToken, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } else {
      try {
        return await _storage.read(key: _keyToken);
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_keyToken);
      }
    }
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
    } else {
      try {
        await _storage.delete(key: _keyToken);
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
    }
  }
}
