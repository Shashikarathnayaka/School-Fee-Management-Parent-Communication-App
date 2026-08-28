import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    test('Initial auth state should be false and currentUser null', () {
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, null);
    });

    test('checkAuthStatus returns false initially', () async {
      final isAuth = await authService.checkAuthStatus();
      expect(isAuth, false);
    });

    test('login with valid parent credentials authenticates as UserRole.parent', () async {
      final success = await authService.login(
        emailOrPhone: 'parent@test.com',
        password: 'Parent@123',
      );

      expect(success, true);
      expect(authService.isAuthenticated, true);
      expect(authService.currentUser?.role, UserRole.parent);
      expect(authService.currentUser?.email, 'parent@test.com');
    });

    test('login with valid driver credentials authenticates as UserRole.driver', () async {
      final success = await authService.login(
        emailOrPhone: 'driver@test.com',
        password: 'Driver@123',
      );

      expect(success, true);
      expect(authService.isAuthenticated, true);
      expect(authService.currentUser?.role, UserRole.driver);
      expect(authService.currentUser?.email, 'driver@test.com');
    });

    test('login with invalid credentials returns false and keeps currentUser null', () async {
      final success = await authService.login(
        emailOrPhone: 'wrong@test.com',
        password: 'wrongpassword',
      );

      expect(success, false);
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, null);
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

    test('logout resets isAuthenticated to false and clears currentUser', () async {
      await authService.login(
        emailOrPhone: 'parent@test.com',
        password: 'Parent@123',
      );
      expect(authService.isAuthenticated, true);

      await authService.logout();
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, null);
    });
  });
}
