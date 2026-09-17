import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../utils/api_exception.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isInitialChecking = true;
  String _errorMessage = '';
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialChecking => _isInitialChecking;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isInitialChecking = true;
    _isLoading = true;
    notifyListeners();

    try {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          final user = await AuthService.getCurrentUser();
          if (user != null) {
            _user = user;
            _isAuthenticated = true;
          } else {
            _user = null;
            await TokenStorage.deleteToken();
            _isAuthenticated = false;
          }
        } catch (e) {
          if (e is ApiException && e.statusCode == 401) {
            _user = null;
            await TokenStorage.deleteToken();
            _isAuthenticated = false;
          } else {
            _isAuthenticated = true;
          }
        }
      } else {
        _user = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      _user = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      _isInitialChecking = false;
      notifyListeners();
    }
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
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
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

  Future<bool> updateProfile(String username, String storeName, {String? currentPassword, String? newPassword}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedUser = await AuthService.updateProfile(
        username,
        storeName,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (updatedUser != null) {
        _user = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> uploadProfileImage(List<int> bytes, String filename) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedUser = await AuthService.uploadProfileImage(bytes, filename);
      if (updatedUser != null) {
        _user = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
