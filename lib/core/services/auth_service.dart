import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../models/user_role.dart';
import 'student_list_notifier.dart';

/// Abstract AuthService defining the contract for authentication actions.
abstract class AuthService extends ChangeNotifier {
  bool get isAuthenticated;
  AuthUser? get currentUser;

  Future<bool> checkAuthStatus();

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  });

  Future<bool> registerParent({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  });

  Future<bool> registerDriver({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    required String vanNumber,
    required String licenseNo,
  });

  Future<bool> becomeDriver({
    required String vanNumber,
    required String licenseNo,
  });

  Future<void> logout();
}

/// Lightweight mock implementation of AuthService strictly reserved for unit/widget tests.
/// Production code must use [ApiAuthService] configured in [ServiceLocator].
@visibleForTesting
class MockAuthService extends AuthService {
  final StudentListNotifier? _studentListNotifier;

  MockAuthService({StudentListNotifier? studentListNotifier})
      : _studentListNotifier = studentListNotifier;

  // Development-only test credentials
  static const String devParentEmail = 'parent@test.com';
  static const String devParentPassword = 'Parent@123';

  static const String devDriverEmail = 'driver@test.com';
  static const String devDriverPassword = 'Driver@123';

  AuthUser? _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<bool> checkAuthStatus() async {
    // Simulate brief check delay
    await Future.delayed(const Duration(milliseconds: 300));
    return isAuthenticated;
  }

  @override
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final trimmed = emailOrPhone.trim().toLowerCase();

    if (trimmed == devParentEmail.toLowerCase() && password == devParentPassword) {
      _studentListNotifier?.reset();
      _currentUser = const AuthUser(
        id: 'usr_parent_01',
        name: 'Shashi Karathnayaka',
        email: devParentEmail,
        roles: {UserRole.parent},
      );
      notifyListeners();
      return true;
    }

    if (trimmed == devDriverEmail.toLowerCase() && password == devDriverPassword) {
      _studentListNotifier?.reset();
      _currentUser = const AuthUser(
        id: 'usr_driver_01',
        name: 'Kamal Silva',
        email: devDriverEmail,
        roles: {UserRole.driver},
      );
      notifyListeners();
      return true;
    }

    return false;
  }

  @override
  Future<bool> registerParent({
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
  Future<bool> registerDriver({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    required String vanNumber,
    required String licenseNo,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (fullName.isNotEmpty &&
        email.isNotEmpty &&
        mobileNumber.isNotEmpty &&
        password.length >= 6 &&
        vanNumber.isNotEmpty &&
        licenseNo.isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  Future<bool> becomeDriver({
    required String vanNumber,
    required String licenseNo,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentUser != null && vanNumber.isNotEmpty && licenseNo.isNotEmpty) {
      _currentUser = AuthUser(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        roles: {..._currentUser!.roles, UserRole.driver},
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _studentListNotifier?.reset();
    _currentUser = null;
    notifyListeners();
  }
}
