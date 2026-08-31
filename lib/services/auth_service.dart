import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    final response = await ApiClient.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );

    if (response != null && response['token'] != null) {
      await TokenStorage.saveToken(response['token']);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    await TokenStorage.deleteToken();
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await ApiClient.get('/auth/me');
      return response;
    } catch (e) {
      return null;
    }
  }
}
