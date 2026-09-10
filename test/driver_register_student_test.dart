import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/constants/app_strings.dart';
import 'package:nd_smart_schoolpay/core/models/driver_route.dart';
import 'package:nd_smart_schoolpay/core/models/student.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/driver_api_service.dart';
import 'package:nd_smart_schoolpay/features/auth/presentation/widgets/auth_button.dart';
import 'package:nd_smart_schoolpay/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_register_student_screen.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_students_screen.dart';

class MockDriverApiService extends DriverApiService {
  List<DriverRoute> mockRoutes;
  bool addStudentCalled = false;
  String? lastRouteId;
  String? lastStudentCode;
  double? lastMonthlyFee;
  Exception? addStudentError;

  MockDriverApiService({
    this.mockRoutes = const [],
    this.addStudentError,
  }) : super(FakeApiClient());

  @override
  Future<List<DriverRoute>> getTodayRoutes() async {
    return mockRoutes;
  }

  @override
  Future<void> addStudentToRoute(
    String routeId,
    String studentCode,
    double monthlyFee,
  ) async {
    addStudentCalled = true;
    lastRouteId = routeId;
    lastStudentCode = studentCode;
    lastMonthlyFee = monthlyFee;

    if (addStudentError != null) {
      throw addStudentError!;
    }
  }
}

class FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Driver Register Student Flow Tests', () {
    late MockAuthService mockAuthService;
    late ActiveRoleNotifier activeRoleNotifier;

    setUp(() {
      mockAuthService = MockAuthService();
      activeRoleNotifier = ActiveRoleNotifier();
    });

    final testRoute1 = DriverRoute(
      id: 'route_01',
      name: 'Morning School Route',
      startTime: '07:00 AM',
      endTime: '08:30 AM',
      students: [
        Student(
          id: 'stu_01',
          name: 'Kasun Perera',
          studentCode: 'STU-101',
          grade: 'Grade 08',
          pickupLocation: 'Main Junction',
          pickupStatus: 'PICKED_UP',
        ),
        Student(
          id: 'stu_02',
          name: 'Amali Silva',
          studentCode: 'STU-102',
          grade: 'Grade 06',
          pickupLocation: 'Temple Road',
          pickupStatus: 'PENDING',
        ),
      ],
    );

    final testRoute2 = DriverRoute(
      id: 'route_02',
      name: 'Afternoon Return Route',
      startTime: '01:30 PM',
      endTime: '03:00 PM',
      students: [
        Student(
          id: 'stu_03',
          name: 'Nimal Fernando',
          studentCode: 'STU-103',
          grade: 'Grade 09',
          pickupLocation: 'Station Road',
          pickupStatus: 'ABSENT',
        ),
      ],
    );

    testWidgets('DriverStudentsScreen renders real student list from routes',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentsScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      // Loading indicator first
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify real students from testRoute1 are displayed
      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(find.text('Amali Silva'), findsOneWidget);
      expect(find.text('Grade 08 • Main Junction'), findsOneWidget);
      expect(find.text('Grade 06 • Temple Road'), findsOneWidget);

      // Verify pickup status badges
      expect(find.text('Picked Up'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Verify "Register Student" buttons are available
      expect(find.text('Register Student'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_rounded), findsWidgets);
    });

    testWidgets('DriverStudentsScreen shows empty state when no students on route',
        (WidgetTester tester) async {
      final emptyRoute = DriverRoute(
        id: 'route_empty',
        name: 'Empty Route',
        students: [],
      );
      final mockApi = MockDriverApiService(mockRoutes: [emptyRoute]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentsScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Students Assigned'), findsOneWidget);
      expect(find.text('Register Student'), findsWidgets);
    });

    testWidgets('DriverStudentsScreen supports route switching filter',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1, testRoute2]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentsScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In All Routes mode, all 3 students appear
      expect(find.text('All Routes'), findsOneWidget);
      expect(find.text('Morning School Route (2)'), findsOneWidget);
      expect(find.text('Afternoon Return Route (1)'), findsOneWidget);
      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(find.text('Nimal Fernando'), findsOneWidget);

      // Tap on Morning School Route filter
      await tester.tap(find.text('Morning School Route (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(find.text('Amali Silva'), findsOneWidget);
      expect(find.text('Nimal Fernando'), findsNothing);
    });

    testWidgets('DriverStudentsScreen opens payment status bottom sheet on student tap',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentsScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Kasun Perera
      await tester.tap(find.text('Kasun Perera'));
      await tester.pumpAndSettle();

      // Bottom sheet with Fee Payment Status appears
      expect(find.text('Fee Payment Status'), findsOneWidget);
    });

    testWidgets('DriverRegisterStudentScreen validates required fields and negative fee',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRegisterStudentScreen(
            authService: mockAuthService,
            driverApiService: mockApi,
            initialRoutes: [testRoute1],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit with empty fields
      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.reqStudentCode), findsOneWidget);
      expect(find.text(AppStrings.reqMonthlyFee), findsOneWidget);
      expect(mockApi.addStudentCalled, isFalse);

      // Enter student code and invalid negative fee
      final textFields = find.byType(AuthTextField);
      await tester.enterText(textFields.at(0), 'STU-999');
      await tester.enterText(textFields.at(1), '-100');
      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.invalidMonthlyFee), findsOneWidget);
      expect(mockApi.addStudentCalled, isFalse);

      // Enter 0 fee
      await tester.enterText(textFields.at(1), '0');
      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.invalidMonthlyFee), findsOneWidget);
      expect(mockApi.addStudentCalled, isFalse);
    });

    testWidgets('DriverRegisterStudentScreen submits successfully and displays dialog',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRegisterStudentScreen(
            authService: mockAuthService,
            driverApiService: mockApi,
            initialRoutes: [testRoute1],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter valid student code and fee
      final textFields = find.byType(AuthTextField);
      await tester.enterText(textFields.at(0), 'STU-999');
      await tester.enterText(textFields.at(1), '4500.00');

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      // Verify API was called with required fields
      expect(mockApi.addStudentCalled, isTrue);
      expect(mockApi.lastRouteId, equals('route_01'));
      expect(mockApi.lastStudentCode, equals('STU-999'));
      expect(mockApi.lastMonthlyFee, equals(4500.00));

      // Verify Success Dialog
      expect(find.text(AppStrings.registerStudentSuccessTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('STU-999'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rs. 4500.00'),
        ),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('DriverRegisterStudentScreen displays NOT_FOUND error correctly',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(
        mockRoutes: [testRoute1],
        addStudentError: ApiException(
          message: 'Student not found',
          code: 'NOT_FOUND',
          statusCode: 404,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRegisterStudentScreen(
            authService: mockAuthService,
            driverApiService: mockApi,
            initialRoutes: [testRoute1],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(AuthTextField);
      await tester.enterText(textFields.at(0), 'INVALID_CODE');
      await tester.enterText(textFields.at(1), '5000');

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.studentNotFound), findsOneWidget);
    });

    testWidgets('DriverRegisterStudentScreen displays CONFLICT error correctly',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(
        mockRoutes: [testRoute1],
        addStudentError: ApiException(
          message: 'Conflict',
          code: 'CONFLICT',
          statusCode: 409,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRegisterStudentScreen(
            authService: mockAuthService,
            driverApiService: mockApi,
            initialRoutes: [testRoute1],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(AuthTextField);
      await tester.enterText(textFields.at(0), 'STU-101');
      await tester.enterText(textFields.at(1), '5000');

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.studentConflict), findsOneWidget);
    });
  });
}
