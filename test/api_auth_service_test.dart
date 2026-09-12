import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/auth_user.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/api_auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/parent_api_service.dart';
import 'package:nd_smart_schoolpay/core/services/student_list_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthUser JSON Serialization Tests', () {
    test('toJson and fromJson preserves parent user fields', () {
      const user = AuthUser(
        id: 'usr_p1',
        name: 'Jane Parent',
        email: 'jane@example.com',
        roles: {UserRole.parent},
      );

      final jsonMap = user.toJson();
      expect(jsonMap['id'], 'usr_p1');
      expect(jsonMap['name'], 'Jane Parent');
      expect(jsonMap['email'], 'jane@example.com');
      expect(jsonMap['roles'], ['parent']);

      final restored = AuthUser.fromJson(jsonMap);
      expect(restored.id, user.id);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.roles, user.roles);
      expect(restored.isParent, true);
      expect(restored.isDriver, false);
      expect(restored.hasDualRole, false);
      expect(restored.role, UserRole.parent);
      expect(restored, equals(user));
    });

    test('toJson and fromJson preserves driver and dual-role user fields', () {
      const driver = AuthUser(
        id: 'usr_d1',
        name: 'Bob Driver',
        email: 'bob@example.com',
        roles: {UserRole.driver},
      );
      final restoredDriver = AuthUser.fromJson(driver.toJson());
      expect(restoredDriver.isDriver, true);
      expect(restoredDriver.isParent, false);
      expect(restoredDriver.role, UserRole.driver);
      expect(restoredDriver, equals(driver));

      const dualUser = AuthUser(
        id: 'usr_dual_1',
        name: 'Alice Dual',
        email: 'alice@example.com',
        roles: {UserRole.parent, UserRole.driver},
      );
      final restoredDual = AuthUser.fromJson(dualUser.toJson());
      expect(restoredDual.hasDualRole, true);
      expect(restoredDual.isParent, true);
      expect(restoredDual.isDriver, true);
      expect(restoredDual, equals(dualUser));
    });

    test('fromJson handles backward-compatible single role field and case insensitivity', () {
      final jsonWithSingleRole = {
        'id': 'usr_legacy',
        'name': 'Legacy Driver',
        'email': 'legacy@example.com',
        'role': 'DRIVER',
      };
      final user = AuthUser.fromJson(jsonWithSingleRole);
      expect(user.roles, {UserRole.driver});
      expect(user.role, UserRole.driver);
    });

    test('fromJson defaults to parent if roles list is empty or unknown', () {
      final jsonEmpty = {
        'id': 'usr_unk',
        'name': 'Unknown User',
        'email': 'unk@example.com',
        'roles': ['UNKNOWN_ROLE'],
      };
      final user = AuthUser.fromJson(jsonEmpty);
      expect(user.roles, {UserRole.parent});
    });
  });

  group('ApiClient UserData Persistence Tests', () {
    late ApiClient apiClient;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      apiClient = ApiClient(prefs);
    });

    test('setUserData, getUserData, userData and clearUserData work as expected', () async {
      expect(apiClient.getUserData(), isNull);
      expect(apiClient.userData, isNull);

      const sampleJson = '{"id":"u1","name":"Test","email":"test@test.com","roles":["parent"]}';
      await apiClient.setUserData(sampleJson);

      expect(apiClient.getUserData(), sampleJson);
      expect(apiClient.userData, sampleJson);

      await apiClient.clearUserData();
      expect(apiClient.getUserData(), isNull);
      expect(apiClient.userData, isNull);
    });
  });

  group('ApiAuthService Session Restoration Tests', () {
    test('checkAuthStatus returns false when no token exists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      final authService = ApiAuthService(apiClient);

      final isAuth = await authService.checkAuthStatus();
      expect(isAuth, false);
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, isNull);
    });

    test('checkAuthStatus returns true and restores _currentUser when token and valid user data exist', () async {
      const user = AuthUser(
        id: 'usr_persisted_1',
        name: 'Persisted Parent',
        email: 'parent@school.com',
        roles: {UserRole.parent},
      );
      final userJson = jsonEncode(user.toJson());

      SharedPreferences.setMockInitialValues({
        'jwt_token': 'valid_jwt_token_123',
        'user_data': userJson,
      });

      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      final authService = ApiAuthService(apiClient);

      // Initially in memory it is null before checkAuthStatus
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, isNull);

      bool notificationFired = false;
      authService.addListener(() {
        notificationFired = true;
      });

      final isAuth = await authService.checkAuthStatus();

      expect(isAuth, true);
      expect(authService.isAuthenticated, true);
      expect(authService.currentUser, equals(user));
      expect(authService.currentUser?.name, 'Persisted Parent');
      expect(notificationFired, true);

      // Calling checkAuthStatus again when already authenticated in memory returns true
      final secondCheck = await authService.checkAuthStatus();
      expect(secondCheck, true);
    });

    test('checkAuthStatus clears orphaned token and returns false when token exists but user data is missing', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'orphaned_token_without_user',
      });

      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      final authService = ApiAuthService(apiClient);

      final isAuth = await authService.checkAuthStatus();

      expect(isAuth, false);
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, isNull);
      // Orphaned token should have been cleaned up
      expect(apiClient.token, isNull);
    });

    test('checkAuthStatus clears orphaned token and returns false when token exists but user data is corrupted JSON', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'valid_token_with_corrupt_data',
        'user_data': 'corrupt {invalid json',
      });

      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      final authService = ApiAuthService(apiClient);

      final isAuth = await authService.checkAuthStatus();

      expect(isAuth, false);
      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, isNull);
      expect(apiClient.token, isNull);
      expect(apiClient.getUserData(), isNull);
    });

    test('logout clears both token and user data from storage and resets state', () async {
      const user = AuthUser(
        id: 'usr_to_logout',
        name: 'Logout User',
        email: 'logout@test.com',
        roles: {UserRole.driver},
      );
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'test_token',
        'user_data': jsonEncode(user.toJson()),
      });

      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      final authService = ApiAuthService(apiClient);

      // Restore session first
      await authService.checkAuthStatus();
      expect(authService.isAuthenticated, true);

      // Perform logout
      await authService.logout();

      expect(authService.isAuthenticated, false);
      expect(authService.currentUser, isNull);
      expect(apiClient.token, isNull);
      expect(apiClient.getUserData(), isNull);
    });

    test('logout resets StudentListNotifier', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(prefs);
      final studentListNotifier = StudentListNotifier(
        ParentApiService(apiClient),
        initialStudents: [],
      );
      expect(studentListNotifier.hasLoaded, true);

      final authService = ApiAuthService(
        apiClient,
        studentListNotifier: studentListNotifier,
      );

      await authService.logout();

      expect(studentListNotifier.hasLoaded, false);
      expect(studentListNotifier.students, isEmpty);
    });
  });

  group('StudentListNotifier Reset Tests', () {
    test('reset clears cached students and resets hasLoaded flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final studentListNotifier = StudentListNotifier(
        ParentApiService(ApiClient(prefs)),
        initialStudents: [],
      );
      expect(studentListNotifier.hasLoaded, true);

      studentListNotifier.reset();

      expect(studentListNotifier.hasLoaded, false);
      expect(studentListNotifier.students, isEmpty);
      expect(studentListNotifier.isLoading, false);
      expect(studentListNotifier.hasFetchError, false);
    });
  });
}
