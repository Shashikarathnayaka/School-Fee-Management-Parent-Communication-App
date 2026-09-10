import 'dart:convert';
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

class ApiClient {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'jwt_token';

  ApiClient(this._prefs);

  Future<void> setToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  String? get token => _prefs.getString(_tokenKey);

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
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(response);
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: _headers);
    return _processResponse(response);
  }
}
