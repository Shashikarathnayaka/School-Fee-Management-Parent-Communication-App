import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int statusCode;

  ApiException({
    required this.message,
    this.code,
    required this.statusCode,
  });

  @override
  String toString() => message;
}

/// Helper function to format exceptions into clear, human-readable error messages for UI display.
String formatErrorMessage(dynamic error) {
  if (error is SocketException) {
    return 'No internet connection or server unreachable. Please check your network connection.';
  } else if (error is TimeoutException) {
    return 'Server took too long to respond. Please try again.';
  } else if (error is ApiException) {
    return error.message;
  } else if (error is http.ClientException) {
    final lowerMsg = error.message.toLowerCase();
    if (lowerMsg.contains('socket') ||
        lowerMsg.contains('failed host lookup') ||
        lowerMsg.contains('connection refused') ||
        lowerMsg.contains('network is unreachable')) {
      return 'No internet connection or server unreachable.';
    }
    return error.message;
  } else if (error is Exception) {
    final msg = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    return msg.isNotEmpty ? msg : 'An unexpected error occurred.';
  } else {
    return 'An unexpected error occurred. Please try again.';
  }
}

class ApiClient {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'jwt_token';
  static const String _userDataKey = 'user_data';

  ApiClient(this._prefs);

  Future<void> setToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  String? get token => _prefs.getString(_tokenKey);

  Future<void> setUserData(String json) async {
    await _prefs.setString(_userDataKey, json);
  }

  String? getUserData() => _prefs.getString(_userDataKey);

  String? get userData => _prefs.getString(_userDataKey);

  Future<void> clearUserData() async {
    await _prefs.remove(_userDataKey);
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final currentToken = token;
    if (currentToken != null && currentToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $currentToken';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Something went wrong';
      String? errorCode;
      try {
        if (response.body.isNotEmpty) {
          final body = jsonDecode(response.body);
          if (body is Map) {
            if (body['error'] != null) {
              if (body['error'] is Map) {
                errorMessage = body['error']['message'] ?? errorMessage;
                errorCode = body['error']['code'];
              } else if (body['error'] is String) {
                errorMessage = body['error'];
              }
            }
            if (body['code'] != null && body['code'] is String) {
              errorCode = body['code'];
            }
            if (body['message'] != null && body['message'] is String) {
              errorMessage = body['message'];
            }
          }
        }
      } catch (_) {
        // Fallback to default error message if JSON parsing fails
      }
      throw ApiException(
        message: errorMessage,
        code: errorCode,
        statusCode: response.statusCode,
      );
    }
  }

  Future<dynamic> get(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    final response = await http
        .patch(
          Uri.parse(url),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await http
        .delete(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }
}
