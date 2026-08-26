import 'package:flutter/foundation.dart';

/// Abstract AuthService defining the contract for authentication actions.
abstract class AuthService extends ChangeNotifier {
  bool get isAuthenticated;

  Future<bool> checkAuthStatus();

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  });

  Future<bool> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  });

  Future<void> logout();
}

/// Lightweight mock implementation of AuthService for development phase.
class MockAuthService extends AuthService {
  // Development-only test credentials
  static const String devEmail = 'parent@test.com';
  static const String devPassword = 'Parent@123';

  bool _isAuthenticated = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<bool> checkAuthStatus() async {
    // Simulate brief check delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _isAuthenticated;
  }

  @override
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final trimmed = emailOrPhone.trim().toLowerCase();
    if (trimmed == devEmail.toLowerCase() && password == devPassword) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  Future<bool> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (fullName.isNotEmpty &&
        email.isNotEmpty &&
        mobileNumber.isNotEmpty &&
        password.length >= 6) {
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isAuthenticated = false;
    notifyListeners();
  }
}
