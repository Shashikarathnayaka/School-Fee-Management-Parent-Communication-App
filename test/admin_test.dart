import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/app/router/app_router.dart';
import 'package:nd_smart_schoolpay/core/constants/app_routes.dart';
import 'package:nd_smart_schoolpay/core/models/auth_user.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/network/api_config.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/admin_api_service.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/parent_api_service.dart';
import 'package:nd_smart_schoolpay/core/services/student_list_notifier.dart';
import 'package:nd_smart_schoolpay/features/admin/presentation/screens/admin_home_screen.dart';

class MockAdminApiClient implements ApiClient {
  final List<dynamic>? mockRoutesResponse;

  MockAdminApiClient({this.mockRoutesResponse});

  @override
  Future<dynamic> get(String url) async {
    if (url == ApiConfig.adminRoutes) {
      return {'routes': mockRoutesResponse ?? []};
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthService extends ChangeNotifier implements AuthService {
  AuthUser? _user;
  bool _isAuthenticated = false;

  void setAuthenticatedUser(AuthUser user) {
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<bool> checkAuthStatus() async => _isAuthenticated;

  @override
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async => true;

  @override
  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyParentApiService extends ParentApiService {
  DummyParentApiService() : super(null);
}

void main() {
  group('Admin Foundation Tests', () {
    test('UserRole enum contains admin', () {
      expect(UserRole.values.contains(UserRole.admin), isTrue);
    });

    test(
      'AuthUser correctly parses admin from roles array and role string',
      () {
        final userFromArray = AuthUser.fromJson({
          'id': 'admin_1',
          'name': 'Admin User',
          'email': 'admin@school.com',
          'roles': ['ADMIN'],
        });

        expect(userFromArray.isAdmin, isTrue);
        expect(userFromArray.isParent, isFalse);
        expect(userFromArray.isDriver, isFalse);
        expect(userFromArray.hasDualRole, isFalse);

        final userFromString = AuthUser.fromJson({
          'id': 'admin_2',
          'name': 'Admin User 2',
          'email': 'admin2@school.com',
          'role': 'admin',
        });

        expect(userFromString.isAdmin, isTrue);
        expect(userFromString.isParent, isFalse);
        expect(userFromString.isDriver, isFalse);

        final serialized = userFromArray.toJson();
        expect(serialized['roles'], contains('admin'));
      },
    );

    test('ApiConfig has all 5 admin endpoints configured', () {
      expect(ApiConfig.adminPickups, contains('/admin/pickups'));
      expect(ApiConfig.adminPickupsMark, contains('/admin/pickups'));
      expect(ApiConfig.adminPickupsTicket, contains('/admin/pickups/ticket'));
      expect(ApiConfig.adminStudentPickupHistory, contains('/admin/students'));
      expect(ApiConfig.adminRoutes, contains('/admin/routes'));
    });

    test(
      'AdminApiService calls GET /admin/routes and returns routes list',
      () async {
        final mockClient = MockAdminApiClient(
          mockRoutesResponse: [
            {'id': 'r1', 'name': 'Morning Route A'},
            {'id': 'r2', 'name': 'Morning Route B'},
          ],
        );
        final service = AdminApiService(mockClient);
        final routes = await service.getRoutes();

        expect(routes.length, equals(2));
        expect(routes[0]['name'], equals('Morning Route A'));
      },
    );
  });

  group('Admin Routing & Redirect Guard Tests', () {
    late TestAuthService authService;
    late ActiveRoleNotifier activeRoleNotifier;
    late StudentListNotifier studentListNotifier;
    late DummyParentApiService parentApiService;

    setUp(() {
      authService = TestAuthService();
      activeRoleNotifier = ActiveRoleNotifier();
      parentApiService = DummyParentApiService();
      studentListNotifier = StudentListNotifier(parentApiService);
    });

    testWidgets(
      'Admin user redirects to adminHome without modifying activeRoleNotifier',
      (tester) async {
        final adminUser = const AuthUser(
          id: 'admin_01',
          name: 'Super Admin',
          email: 'admin@test.com',
          roles: {UserRole.admin},
        );

        authService.setAuthenticatedUser(adminUser);

        // activeRoleNotifier defaults to UserRole.parent
        expect(activeRoleNotifier.value, equals(UserRole.parent));

        final router = AppRouter.createRouter(
          authService,
          activeRoleNotifier,
          studentListNotifier,
          parentApiService,
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Should be on Admin Dashboard
        expect(find.text('Admin Dashboard'), findsOneWidget);
        // activeRoleNotifier should NOT have been set or modified
        expect(activeRoleNotifier.value, equals(UserRole.parent));
      },
    );

    testWidgets(
      'Authenticated admin landing on /home is redirected to /admin-home',
      (tester) async {
        final adminUser = const AuthUser(
          id: 'admin_01',
          name: 'Super Admin',
          email: 'admin@test.com',
          roles: {UserRole.admin},
        );

        authService.setAuthenticatedUser(adminUser);

        final router = AppRouter.createRouter(
          authService,
          activeRoleNotifier,
          studentListNotifier,
          parentApiService,
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Attempt to navigate to /home
        router.go(AppRoutes.home);
        await tester.pumpAndSettle();

        // Guard redirects back to Admin Dashboard
        expect(find.text('Admin Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      'Non-admin user landing on /admin-home is redirected to /home',
      (tester) async {
        final parentUser = const AuthUser(
          id: 'parent_01',
          name: 'Parent User',
          email: 'parent@test.com',
          roles: {UserRole.parent},
        );

        authService.setAuthenticatedUser(parentUser);

        final router = AppRouter.createRouter(
          authService,
          activeRoleNotifier,
          studentListNotifier,
          parentApiService,
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Attempt to navigate to /admin-home
        router.go(AppRoutes.adminHome);
        await tester.pumpAndSettle();

        // Should NOT show Admin Dashboard, redirected to home
        expect(find.text('Admin Dashboard'), findsNothing);
      },
    );
  });

  group('AdminHomeScreen Widget Tests', () {
    late TestAuthService authService;

    setUp(() {
      authService = TestAuthService();
      authService.setAuthenticatedUser(
        const AuthUser(
          id: 'admin_1',
          name: 'Admin',
          email: 'admin@test.com',
          roles: {UserRole.admin},
        ),
      );
    });

    testWidgets('Renders AppBar and tabs: Pickups, Routes, History', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminHomeScreen(authService: authService)),
      );

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Pickups'), findsOneWidget);
      expect(find.text('Routes'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Default tab is Pickups
      expect(find.text('Pickups Review'), findsOneWidget);

      // Tap on Routes tab
      await tester.tap(find.text('Routes'));
      await tester.pumpAndSettle();
      expect(find.text('Routes Management'), findsOneWidget);

      // Tap on History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Pickup History'), findsOneWidget);
    });

    testWidgets('Logout button opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AdminHomeScreen(authService: authService)),
      );

      final logoutButton = find.byIcon(Icons.logout_rounded);
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsWidgets);
      expect(
        find.text('Are you sure you want to sign out of the Admin panel?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        find.text('Are you sure you want to sign out of the Admin panel?'),
        findsNothing,
      );
      expect(authService.isAuthenticated, isTrue);
    });
  });
}
