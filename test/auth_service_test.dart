import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    test('Initial auth state should be false', () {
      expect(authService.isAuthenticated, false);
    });

    test('checkAuthStatus returns false initially', () async {
      final isAuth = await authService.checkAuthStatus();
      expect(isAuth, false);
    });

    test('login with valid credentials sets isAuthenticated to true', () async {
      final success = await authService.login(
        emailOrPhone: 'parent@school.com',
        password: 'password123',
      );

      expect(success, true);
      expect(authService.isAuthenticated, true);
    });

    test('login with empty credentials returns false', () async {
      final success = await authService.login(
        emailOrPhone: '',
        password: '123',
      );

      expect(success, false);
      expect(authService.isAuthenticated, false);
    });

    test('register with valid details returns true', () async {
      final success = await authService.register(
        fullName: 'John Doe',
        email: 'john@example.com',
        mobileNumber: '0771234567',
        password: 'password123',
      );

      expect(success, true);
    });

    test('logout resets isAuthenticated to false', () async {
      await authService.login(
        emailOrPhone: 'parent@school.com',
        password: 'password123',
      );
      expect(authService.isAuthenticated, true);

      await authService.logout();
      expect(authService.isAuthenticated, false);
    });
  });
}
