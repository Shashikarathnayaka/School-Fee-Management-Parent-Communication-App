import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import 'auth_service.dart';

class ApiAuthService extends AuthService {
  final ApiClient _apiClient;
  AuthUser? _currentUser;

  ApiAuthService(this._apiClient);

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<bool> checkAuthStatus() async {
    // Basic check: do we have a token?
    final token = _apiClient.token;
    if (token != null && token.isNotEmpty) {
      // Ideally, we would hit a /me endpoint here to get the current user details.
      // But since the API docs don't specify a /me endpoint that returns the unified AuthUser,
      // we might need to rely on the stored state or fetch the profile based on the role.
      // For now, if we don't have _currentUser but have a token, we might not be fully "logged in"
      // in the app state unless we persisted the user object too.
      // If we just restarted the app, we need to restore _currentUser from local storage.
      // (This is a simplified implementation. In a real app, you'd persist user data or fetch it here).
      return _currentUser != null;
    }
    return false;
  }

  /// Parses a roles set from the API response user object.
  /// Supports both a `roles` array and a single `role` string for backward compat.
  Set<UserRole> _parseRoles(Map<String, dynamic> userObj, {UserRole? fallback}) {
    final rolesJson = userObj['roles'];
    if (rolesJson is List && rolesJson.isNotEmpty) {
      final parsed = <UserRole>{};
      for (final r in rolesJson) {
        final upper = r.toString().toUpperCase();
        if (upper == 'DRIVER') parsed.add(UserRole.driver);
        if (upper == 'PARENT') parsed.add(UserRole.parent);
      }
      if (parsed.isNotEmpty) return parsed;
    }
    // Fallback to single 'role' string
    final roleStr = userObj['role'] ?? '';
    if (roleStr.toString().toUpperCase() == 'DRIVER') {
      return {UserRole.driver};
    }
    return {fallback ?? UserRole.parent};
  }

  @override
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.login,
        body: {
          'email': emailOrPhone,
          'password': password,
        },
      );

      if (response != null && response['token'] != null) {
        await _apiClient.setToken(response['token']);

        final userObj = response['user'] ?? {};

        _currentUser = AuthUser(
          id: userObj['id'] ?? '',
          name: userObj['name'] ?? '',
          email: userObj['email'] ?? emailOrPhone,
          roles: _parseRoles(userObj),
        );

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  @override
  Future<bool> registerParent({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.registerParent,
        body: {
          'name': fullName,
          'email': email,
          'phone': mobileNumber,
          'password': password,
        },
      );

      if (response != null && response['token'] != null) {
        await _apiClient.setToken(response['token']);
        
        final userObj = response['user'] ?? {};
        _currentUser = AuthUser(
          id: userObj['id'] ?? '',
          name: userObj['name'] ?? fullName,
          email: userObj['email'] ?? email,
          roles: _parseRoles(userObj, fallback: UserRole.parent),
        );

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  @override
  Future<bool> registerDriver({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    required String vanNumber,
    required String licenseNo,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.registerDriver,
        body: {
          'name': fullName,
          'email': email,
          'phone': mobileNumber,
          'password': password,
          'van_number': vanNumber,
          'license_no': licenseNo,
        },
      );

      if (response != null && response['token'] != null) {
        await _apiClient.setToken(response['token']);
        
        final userObj = response['user'] ?? {};
        _currentUser = AuthUser(
          id: userObj['id'] ?? '',
          name: userObj['name'] ?? fullName,
          email: userObj['email'] ?? email,
          roles: _parseRoles(userObj, fallback: UserRole.driver),
        );

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  @override
  Future<bool> becomeDriver({
    required String vanNumber,
    required String licenseNo,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiConfig.parentBecomeDriver,
        body: {
          'van_number': vanNumber,
          'license_no': licenseNo,
        },
      );

      if (response != null && response['token'] != null) {
        await _apiClient.setToken(response['token']);

        final userObj = response['user'] ?? {};
        _currentUser = AuthUser(
          id: userObj['id'] ?? _currentUser?.id ?? '',
          name: userObj['name'] ?? _currentUser?.name ?? '',
          email: userObj['email'] ?? _currentUser?.email ?? '',
          roles: _parseRoles(userObj, fallback: UserRole.parent),
        );

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Become driver error: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.clearToken();
    _currentUser = null;
    notifyListeners();
  }
}
