import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/driver_route.dart';
import 'package:nd_smart_schoolpay/core/models/student.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/driver_api_service.dart';
import 'package:nd_smart_schoolpay/features/auth/presentation/widgets/auth_button.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_home_view.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_route_screen.dart';

class MockDriverApiService extends DriverApiService {
  List<DriverRoute> mockRoutes;
  bool shouldThrowOnGet;
  bool shouldThrowOnCreate;
  String? createErrorMessage;
  bool createRouteCalled = false;
  String? lastCreatedName;
  String? lastCreatedStartTime;
  String? lastCreatedEndTime;

  MockDriverApiService({
    this.mockRoutes = const [],
    this.shouldThrowOnGet = false,
    this.shouldThrowOnCreate = false,
    this.createErrorMessage,
  }) : super(FakeApiClient());

  @override
  Future<List<DriverRoute>> getTodayRoutes() async {
    if (shouldThrowOnGet) {
      throw Exception('Network error');
    }
    return mockRoutes;
  }

  @override
  Future<DriverRoute?> createRoute({
    required String name,
    String? startTime,
    String? endTime,
  }) async {
    createRouteCalled = true;
    lastCreatedName = name;
    lastCreatedStartTime = startTime;
    lastCreatedEndTime = endTime;

    if (shouldThrowOnCreate) {
      throw ApiException(
        statusCode: 400,
        message: createErrorMessage ?? 'Validation failed',
      );
    }

    final newRoute = DriverRoute(
      id: 'route_new',
      name: name,
      startTime: startTime,
      endTime: endTime,
      status: 'SCHEDULED',
      students: [],
    );
    mockRoutes = [...mockRoutes, newRoute];
    return newRoute;
  }
}

class FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('DriverRouteScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late ActiveRoleNotifier activeRoleNotifier;

    setUp(() {
      mockAuthService = MockAuthService();
      activeRoleNotifier = ActiveRoleNotifier();
      activeRoleNotifier.value = UserRole.driver;
    });

    final testRoute1 = DriverRoute(
      id: 'route_01',
      name: 'Morning School Route',
      startTime: '07:00 AM',
      endTime: '08:30 AM',
      status: 'SCHEDULED',
      students: [
        Student(id: 'stu_01', name: 'Student 1', studentCode: 'S1'),
        Student(id: 'stu_02', name: 'Student 2', studentCode: 'S2'),
      ],
    );

    final testRoute2 = DriverRoute(
      id: 'route_02',
      name: 'Afternoon Return Route',
      startTime: '01:30 PM',
      endTime: '03:00 PM',
      status: 'ACTIVE',
      students: [
        Student(id: 'stu_03', name: 'Student 3', studentCode: 'S3'),
      ],
    );

    testWidgets('Renders loading indicator initially', (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders empty state when no routes exist', (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: []);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Routes Yet Today'), findsOneWidget);
      expect(find.text('No routes yet today — create one to get started'), findsOneWidget);
      expect(find.text('Live GPS Route Map'), findsOneWidget);
      expect(find.text('Create Route'), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders error state with retry button when loading fails',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(shouldThrowOnGet: true);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Couldn't load today's routes. Please try again."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now fix mock and tap retry
      mockApi.shouldThrowOnGet = false;
      mockApi.mockRoutes = [testRoute1];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Morning School Route'), findsOneWidget);
    });

    testWidgets('Renders multiple route cards and live map placeholder',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1, testRoute2]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify route 1 card
      expect(find.text('Morning School Route'), findsOneWidget);
      expect(find.text('SCHEDULED'), findsOneWidget);
      expect(find.text('07:00 AM - 08:30 AM'), findsOneWidget);
      expect(find.text('2 Students'), findsOneWidget);

      // Verify route 2 card
      expect(find.text('Afternoon Return Route'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('01:30 PM - 03:00 PM'), findsOneWidget);
      expect(find.text('1 Student'), findsOneWidget);

      // Verify live map placeholder is also present
      expect(find.text('Live GPS Route Map'), findsOneWidget);
    });

    testWidgets('Opens Create Route modal bottom sheet and validates empty name',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap FAB "Create Route"
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Create Route'));
      await tester.pumpAndSettle();

      expect(find.text('Create New Route'), findsOneWidget);
      expect(find.text('Route Name'), findsOneWidget);
      expect(find.text('Start Time (Optional)'), findsOneWidget);
      expect(find.text('End Time (Optional)'), findsOneWidget);

      // Tap submit without entering route name
      await tester.tap(find.widgetWithText(AuthButton, 'Create Route'));
      await tester.pumpAndSettle();

      expect(find.text('Route name is required'), findsOneWidget);
      expect(mockApi.createRouteCalled, isFalse);
    });

    testWidgets('Successfully creates a route and refreshes list',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: []);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No Routes Yet Today'), findsOneWidget);

      // Open bottom sheet
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Create Route'));
      await tester.pumpAndSettle();

      // Enter details
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Evening Express Route');
      await tester.enterText(textFields.at(1), '04:00 PM');
      await tester.enterText(textFields.at(2), '05:30 PM');

      // Submit
      await tester.tap(find.widgetWithText(AuthButton, 'Create Route'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify API called with right values
      expect(mockApi.createRouteCalled, isTrue);
      expect(mockApi.lastCreatedName, 'Evening Express Route');
      expect(mockApi.lastCreatedStartTime, '04:00 PM');
      expect(mockApi.lastCreatedEndTime, '05:30 PM');

      // Bottom sheet closed and list refreshed with new card
      expect(find.text('Create New Route'), findsNothing);
      expect(find.text('Evening Express Route'), findsOneWidget);
      expect(find.text('04:00 PM - 05:30 PM'), findsOneWidget);
      expect(find.text('Route "Evening Express Route" created successfully!'), findsOneWidget);
    });

    testWidgets('Shows error snackbar if route creation fails',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(
        mockRoutes: [],
        shouldThrowOnCreate: true,
        createErrorMessage: 'Route creation rejected',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open bottom sheet via AppBar action
      await tester.tap(find.byTooltip('Create Route'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Invalid Route');

      await tester.tap(find.widgetWithText(AuthButton, 'Create Route'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Route creation rejected'), findsOneWidget);
    });

    testWidgets(
        'Successfully creates a new route when an existing route with assigned students is already present',
        (WidgetTester tester) async {
      final existingRouteWithStudents = DriverRoute(
        id: 'route_existing',
        name: 'Morning Primary Route',
        startTime: '07:00 AM',
        endTime: '08:00 AM',
        status: 'SCHEDULED',
        students: [
          Student(
            id: 'stu_1',
            name: 'Timmy',
            studentCode: 'STU-123',
            pickupStatus: 'PENDING',
          ),
        ],
      );

      final mockApi = MockDriverApiService(
        mockRoutes: [existingRouteWithStudents],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverRouteScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial route card is displayed
      expect(find.text('Morning Primary Route'), findsOneWidget);
      expect(find.text('1 Student'), findsOneWidget);

      // Open bottom sheet to create second route
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Create Route'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Afternoon Return Route');
      await tester.enterText(textFields.at(1), '01:30 PM');
      await tester.enterText(textFields.at(2), '03:00 PM');

      await tester.tap(find.widgetWithText(AuthButton, 'Create Route'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Both existing route and new route are rendered
      expect(find.text('Morning Primary Route'), findsOneWidget);
      expect(find.text('Afternoon Return Route'), findsOneWidget);
      expect(find.text('01:30 PM - 03:00 PM'), findsOneWidget);
      expect(
        find.text('Route "Afternoon Return Route" created successfully!'),
        findsOneWidget,
      );
    });
  });

  group('DriverRoute & Student fromJson Payload Parsing Tests', () {
    test('Correctly parses real backend route payload with nested join-table and list pickup_status', () {
      final rawPayload = {
        'id': 'route_abc',
        'driver_id': 'driver_xyz',
        'name': 'Live Route 1',
        'start_time': '06:45 AM',
        'end_time': '08:00 AM',
        'status': 'SCHEDULED',
        'students': [
          {
            'id': 'rs_1',
            'route_id': 'route_abc',
            'student_id': 'stu_1',
            'pickup_order': 1,
            'scheduled_time': null,
            'monthly_fee': 4500,
            'student': {
              'id': 'stu_1',
              'name': 'Little Timmy',
              'grade': '5',
              'section': 'A',
              'school_name': 'Royal College',
              'pickup_location': 'Colombo 07',
              'student_code': 'STU-TMXMW',
              'pickup_status': [],
            },
          },
          {
            'id': 'rs_2',
            'route_id': 'route_abc',
            'student_id': 'stu_2',
            'pickup_order': 2,
            'student': {
              'id': 'stu_2',
              'name': 'Jane Doe',
              'grade': '6',
              'section': 'B',
              'student_code': 'STU-JANE',
              'pickup_status': [
                {'status': 'PICKED_UP'},
              ],
            },
          },
        ],
      };

      final route = DriverRoute.fromJson(rawPayload);
      expect(route.id, 'route_abc');
      expect(route.name, 'Live Route 1');
      expect(route.students?.length, 2);

      final student1 = route.students![0];
      expect(student1.id, 'stu_1');
      expect(student1.name, 'Little Timmy');
      expect(student1.studentCode, 'STU-TMXMW');
      expect(student1.pickupStatus, isNull);

      final student2 = route.students![1];
      expect(student2.id, 'stu_2');
      expect(student2.name, 'Jane Doe');
      expect(student2.pickupStatus, 'PICKED_UP');
    });

    test('Correctly parses student with string or map pickup_status', () {
      final studentWithString = Student.fromJson({
        'id': 's1',
        'name': 'Student A',
        'pickup_status': 'ABSENT',
      });
      expect(studentWithString.pickupStatus, 'ABSENT');

      final studentWithMap = Student.fromJson({
        'id': 's2',
        'name': 'Student B',
        'pickup_status': {'status': 'PICKED_UP'},
      });
      expect(studentWithMap.pickupStatus, 'PICKED_UP');

      final studentWithNull = Student.fromJson({
        'id': 's3',
        'name': 'Student C',
        'pickup_status': null,
      });
      expect(studentWithNull.pickupStatus, isNull);
    });
  });

  group('DriverHomeView Route Card Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    final testRoute1 = DriverRoute(
      id: 'route_01',
      name: 'Primary Morning Route',
      startTime: '07:15 AM',
      endTime: '08:15 AM',
      status: 'SCHEDULED',
      students: [
        Student(id: 's1', name: 'Student 1', studentCode: 'S1'),
      ],
    );

    final testRoute2 = DriverRoute(
      id: 'route_02',
      name: 'Secondary Route',
      startTime: '01:00 PM',
      endTime: '02:00 PM',
      status: 'SCHEDULED',
      students: [],
    );

    testWidgets('Displays first route and multi-route chip when multiple routes exist',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: [testRoute1, testRoute2]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuthService,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Today's Route"), findsAtLeastNWidgets(1));
      expect(find.text('Primary Morning Route'), findsOneWidget);
      expect(find.text('07:15 AM - 08:15 AM'), findsOneWidget);
      expect(find.text('1 Student'), findsOneWidget);
      expect(find.text('+1 more route today • View all'), findsOneWidget);
    });

    testWidgets('Displays empty route state on home screen when no routes exist',
        (WidgetTester tester) async {
      final mockApi = MockDriverApiService(mockRoutes: []);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuthService,
            driverApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Today's Route"), findsAtLeastNWidgets(1));
      expect(find.text('No routes scheduled for today.'), findsOneWidget);
      expect(find.text('Create Route'), findsOneWidget);
      expect(find.text('+1 more route today • View all'), findsNothing);
    });
  });
}
