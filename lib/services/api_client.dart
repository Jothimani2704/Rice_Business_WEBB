import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  static final String _baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.get(url, headers: await _getHeaders());
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, {dynamic body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, {dynamic body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.delete(url, headers: await _getHeaders());
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'An unexpected error occurred';
    try {
      final errorData = jsonDecode(response.body);
      message =
          errorData['message'] ??
          errorData['title'] ??
          response.reasonPhrase ??
          message;
    } catch (_) {
      if (response.statusCode == 401) {
        message = 'Unauthorized. Please login again.';
      } else if (response.statusCode == 403) {
        message = 'Forbidden access.';
      } else if (response.statusCode == 404) {
        message = 'Resource not found.';
      } else if (response.statusCode >= 500) {
        message = 'Server error. Please try again later.';
      }
    }

    throw ApiException(response.statusCode, message);
  }
}
