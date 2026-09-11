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

  static Future<Map<String, dynamic>?> updateProfile(String username, String storeName, {String? currentPassword, String? newPassword}) async {
    try {
      final body = {
        'username': username,
        'storeName': storeName,
        if (currentPassword != null && currentPassword.isNotEmpty) 'currentPassword': currentPassword,
        if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
      };
      
      final response = await ApiClient.put('/auth/profile', body: body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> uploadProfileImage(
      List<int> fileBytes, String filename) async {
    try {
      final response = await ApiClient.multipartRequest(
        '/auth/profile-image',
        method: 'POST',
        fileBytes: fileBytes,
        filename: filename,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
