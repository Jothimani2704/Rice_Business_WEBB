import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/token_storage.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      // Validate token by fetching user
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
      } else {
        _user = null;
        await TokenStorage.deleteToken();
        _isAuthenticated = false;
      }
    } else {
      _user = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await AuthService.login(username, password);
      if (success) {
        _user = await AuthService.getCurrentUser();
        _isAuthenticated = true;
      } else {
        _errorMessage = 'Invalid username or password';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
