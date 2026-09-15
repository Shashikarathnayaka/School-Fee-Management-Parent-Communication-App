import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import 'auth_service.dart';
import 'student_list_notifier.dart';

class ApiAuthService extends AuthService {
  final ApiClient _apiClient;
  final StudentListNotifier? _studentListNotifier;
  AuthUser? _currentUser;

  ApiAuthService(this._apiClient, {StudentListNotifier? studentListNotifier})
      : _studentListNotifier = studentListNotifier;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<bool> checkAuthStatus() async {
    final token = _apiClient.token;
    if (token == null || token.isEmpty) {
      return false;
    }

    if (_currentUser != null) {
      return true;
    }

    // Token exists but _currentUser is null: restore from persisted user data
    final userDataJson = _apiClient.getUserData();
    if (userDataJson != null && userDataJson.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(userDataJson);
        if (decoded is Map<String, dynamic>) {
          _currentUser = AuthUser.fromJson(decoded);
          notifyListeners();
          return true;
        } else if (decoded is Map) {
          _currentUser = AuthUser.fromJson(Map<String, dynamic>.from(decoded));
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('Failed to restore user data from local storage: $e');
      }
    }

    // Token exists but no valid persisted user data can be restored -> clear orphaned token & data
    await _apiClient.clearToken();
    await _apiClient.clearUserData();
    _currentUser = null;
    return false;
  }

  Future<void> _setCurrentUserAndPersist(AuthUser user) async {
    _currentUser = user;
    try {
      await _apiClient.setUserData(jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Failed to persist user data: $e');
    }
    notifyListeners();
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

        _studentListNotifier?.reset();
        await _setCurrentUserAndPersist(
          AuthUser(
            id: userObj['id'] ?? '',
            name: userObj['name'] ?? '',
            email: userObj['email'] ?? emailOrPhone,
            roles: _parseRoles(userObj),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
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
        _studentListNotifier?.reset();
        await _setCurrentUserAndPersist(
          AuthUser(
            id: userObj['id'] ?? '',
            name: userObj['name'] ?? fullName,
            email: userObj['email'] ?? email,
            roles: _parseRoles(userObj, fallback: UserRole.parent),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
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
        await _setCurrentUserAndPersist(
          AuthUser(
            id: userObj['id'] ?? '',
            name: userObj['name'] ?? fullName,
            email: userObj['email'] ?? email,
            roles: _parseRoles(userObj, fallback: UserRole.driver),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
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
        await _setCurrentUserAndPersist(
          AuthUser(
            id: userObj['id'] ?? _currentUser?.id ?? '',
            name: userObj['name'] ?? _currentUser?.name ?? '',
            email: userObj['email'] ?? _currentUser?.email ?? '',
            roles: _parseRoles(userObj, fallback: UserRole.parent),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Become driver error: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.clearToken();
    await _apiClient.clearUserData();
    _currentUser = null;
    _studentListNotifier?.reset();
    notifyListeners();
  }
}
