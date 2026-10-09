import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/driver_profile.dart';
import 'package:nd_smart_schoolpay/core/models/driver_route.dart';
import 'package:nd_smart_schoolpay/core/models/notification_model.dart';
import 'package:nd_smart_schoolpay/core/models/student.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/driver_api_service.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_home_view.dart';

// ─── Fake helpers ────────────────────────────────────────────────────────────

class FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class FakeDriverApiService extends DriverApiService {
  final List<DriverRoute> routes;
  bool isOnDuty;
  int getTodayRoutesCallCount = 0;
  int startRouteCallCount = 0;
  int getProfileCallCount = 0;
  bool shouldThrowOnToggle = false;
  Completer<DriverProfile?>? getProfileCompleter;
  String? lastStartedRouteId;
  StartRouteResult? startRouteResult;
  Object? startRouteError;

  FakeDriverApiService(
    this.routes, {
    this.isOnDuty = false,
    this.startRouteResult,
    this.startRouteError,
  }) : super(FakeApiClient()) {
    isOnDutyNotifier.value = isOnDuty;
  }

  @override
  Future<DriverProfile?> getProfile() async {
    getProfileCallCount++;
    if (getProfileCompleter != null) {
      return getProfileCompleter!.future;
    }
    return DriverProfile(
      id: 'drv_1',
      name: 'Test Driver',
      phone: '0771111111',
      vanNumber: 'WP AA-0001',
      licenseNo: 'A0000001',
      isOnDuty: isOnDuty,
    );
  }

  @override
  Future<List<DriverRoute>> getTodayRoutes() async {
    getTodayRoutesCallCount++;
    return routes;
  }

  @override
  Future<List<AppNotification>> getNotifications() async => [];

  @override
  Future<void> toggleDutyStatus(bool onDuty) async {
    if (shouldThrowOnToggle) {
      throw Exception('Server error');
    }
    isOnDuty = onDuty;
    isOnDutyNotifier.value = onDuty;
    hasLoadedDutyStatus = true;
  }

  @override
  Future<StartRouteResult> startRoute(String routeId) async {
    startRouteCallCount++;
    lastStartedRouteId = routeId;
    if (startRouteError != null) {
      throw startRouteError!;
    }
    return startRouteResult ?? const StartRouteResult(notified: 2, skipped: 0);
  }
}

// ─── Unit tests: isMorningNow ─────────────────────────────────────────────────

void main() {
  group('isMorningNow pure function', () {
    test('returns true when hour < 12 (morning)', () {
      // 09:30 SL time
      final morning = DateTime(2026, 10, 5, 9, 30);
      expect(isMorningNow(morning), isTrue);
    });

    test('returns true at 00:00 midnight', () {
      final midnight = DateTime(2026, 10, 5, 0, 0);
      expect(isMorningNow(midnight), isTrue);
    });

    test('returns true at 11:59', () {
      final justBefore = DateTime(2026, 10, 5, 11, 59);
      expect(isMorningNow(justBefore), isTrue);
    });

    test('returns false at exactly 12:00', () {
      final noon = DateTime(2026, 10, 5, 12, 0);
      expect(isMorningNow(noon), isFalse);
    });

    test('returns false in the afternoon (14:30)', () {
      final afternoon = DateTime(2026, 10, 5, 14, 30);
      expect(isMorningNow(afternoon), isFalse);
    });

    test('returns false at 23:59', () {
      final lateNight = DateTime(2026, 10, 5, 23, 59);
      expect(isMorningNow(lateNight), isFalse);
    });
  });

  // ─── Unit tests: shouldResetManualSelection ──────────────────────────────

  group('shouldResetManualSelection pure function', () {
    final morningTime = DateTime(2026, 10, 5, 9, 0);   // 09:00 – morning
    final eveningTime = DateTime(2026, 10, 5, 14, 0);  // 14:00 – evening

    test('returns false when manualPeriodIsMorning is null (no manual selection)', () {
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: null, now: morningTime),
        isFalse,
      );
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: null, now: eveningTime),
        isFalse,
      );
    });

    test('returns false when manual selection is morning and it is still morning', () {
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: true, now: morningTime),
        isFalse,
      );
    });

    test('returns false when manual selection is evening and it is still evening', () {
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: false, now: eveningTime),
        isFalse,
      );
    });

    test('returns true when manual selection was morning but it is now evening', () {
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: true, now: eveningTime),
        isTrue,
      );
    });

    test('returns true when manual selection was evening but it is now morning', () {
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: false, now: morningTime),
        isTrue,
      );
    });

    test('boundary: exactly at noon is evening (hour == 12)', () {
      final noonExact = DateTime(2026, 10, 5, 12, 0);
      // If the manual selection was morning-period and we are now at noon -> reset
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: true, now: noonExact),
        isTrue,
      );
      // If manual selection was evening-period and we are at noon -> same period, no reset
      expect(
        shouldResetManualSelection(manualPeriodIsMorning: false, now: noonExact),
        isFalse,
      );
    });
  });

  // ─── Widget test: route chips and evening chip switching ─────────────────

  group('DriverHomeView route chip selection', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
    });

    final morningStudent = Student(
      id: 'sm1',
      name: 'Morning Kid',
      studentCode: 'MK01',
    );
    final eveningStudent = Student(
      id: 'se1',
      name: 'Evening Kid',
      studentCode: 'EK01',
    );

    final morningRoute = DriverRoute(
      id: 'r_morning',
      name: 'Morning Bus',
      direction: RouteDirection.homeToSchool,
      students: [morningStudent],
    );
    final eveningRoute = DriverRoute(
      id: 'r_evening',
      name: 'Evening Bus',
      direction: RouteDirection.schoolToHome,
      students: [eveningStudent],
    );

    testWidgets(
        'Both chips appear when one HOME_TO_SCHOOL and one SCHOOL_TO_HOME route exist',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute, eveningRoute]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both chips should be rendered
      expect(find.text('Morning - Morning Bus'), findsOneWidget);
      expect(find.text('Evening - Evening Bus'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
    });

    testWidgets(
        'Tapping the Evening chip switches the pickups list to the evening route students',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute, eveningRoute]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially the morning route is selected (before noon in test environment
      // or whichever auto-selected), the morning student should be visible.
      // We verify that after tapping the Evening chip, the evening student appears.

      // Tap the Evening chip
      await tester.tap(find.text('Evening - Evening Bus'));
      await tester.pumpAndSettle();

      // Evening route card now shows Evening Bus name
      expect(find.text('Evening Bus'), findsOneWidget);

      // Evening student appears in the pickups list
      expect(find.text('Evening Kid'), findsOneWidget);

      // Morning student no longer visible
      expect(find.text('Morning Kid'), findsNothing);
    });

    testWidgets(
        'No chips shown when only one route exists',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute]);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  // ─── Widget test: Start Route Flow ────────────────────────────────────────

  group('DriverHomeView start route flow', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
    });

    final testStudent = Student(
      id: 'st_1',
      name: 'Alice Smith',
      studentCode: 'AS01',
    );

    final morningRoute = DriverRoute(
      id: 'r_morning',
      name: 'Morning Route 1',
      direction: RouteDirection.homeToSchool,
      startTime: '07:30',
      isActiveNow: true,
      students: [testStudent],
    );

    final eveningRoute = DriverRoute(
      id: 'r_evening',
      name: 'Evening Route 1',
      direction: RouteDirection.schoolToHome,
      startTime: '14:30',
      isActiveNow: false,
      students: [testStudent],
    );

    testWidgets('Start Route button is visible on route card when driver is on duty',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute], isOnDuty: true);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('start_route_btn')), findsOneWidget);
    });

    testWidgets('Start Route button is NOT visible on route card when driver is offline',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute], isOnDuty: false);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('start_route_btn')), findsNothing);
    });

    testWidgets('Tapping Go On Duty opens the "Select route to start" sheet with route list and Recommended badge',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute, eveningRoute], isOnDuty: false);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Go On Duty
      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      // Sheet is visible
      expect(find.text('Select route to start'), findsOneWidget);
      expect(find.text("Parents will receive a 'Driver on the way' notification."), findsOneWidget);
      expect(find.text('Morning Route 1'), findsWidgets);
      expect(find.text('Evening Route 1'), findsWidgets);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.byKey(const Key('start_btn_r_morning')), findsOneWidget);
      expect(find.byKey(const Key('start_btn_r_evening')), findsOneWidget);
      expect(find.byKey(const Key('start_route_later_btn')), findsOneWidget);
    });

    testWidgets('Tapping Later dismisses the sheet',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute], isOnDuty: false);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      expect(find.text('Select route to start'), findsOneWidget);

      await tester.tap(find.byKey(const Key('start_route_later_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Select route to start'), findsNothing);
    });

    testWidgets('Tapping Start route calls API, shows success SnackBar and closes sheet',
        (WidgetTester tester) async {
      final api = FakeDriverApiService(
        [morningRoute],
        isOnDuty: false,
        startRouteResult: const StartRouteResult(notified: 3, skipped: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      // Tap Start button for morning route
      await tester.tap(find.byKey(const Key('start_btn_r_morning')));
      await tester.pumpAndSettle();

      expect(api.startRouteCallCount, equals(1));
      expect(api.lastStartedRouteId, equals('r_morning'));
      expect(find.text('Route started. 3 parents notified.'), findsOneWidget);
      expect(find.text('Select route to start'), findsNothing);
    });

    testWidgets('Start route failure displays error SnackBar and keeps sheet open',
        (WidgetTester tester) async {
      final api = FakeDriverApiService(
        [morningRoute],
        isOnDuty: false,
        startRouteError: ApiException(
          message: 'Route not on duty',
          code: 'NOT_ON_DUTY',
          statusCode: 409,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      // Tap Start
      await tester.tap(find.byKey(const Key('start_btn_r_morning')));
      await tester.pumpAndSettle();

      expect(api.startRouteCallCount, equals(1));
      // Friendly message for NOT_ON_DUTY
      expect(find.text('You must be on duty before starting a route.'), findsOneWidget);
      // Sheet remains open for retry or dismissal
      expect(find.text('Select route to start'), findsOneWidget);
      expect(find.byKey(const Key('start_route_later_btn')), findsOneWidget);
    });

    testWidgets('Start Route button on route card opens the same sheet when already on duty',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute], isOnDuty: true);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('start_route_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Select route to start'), findsOneWidget);
      expect(find.byKey(const Key('start_btn_r_morning')), findsOneWidget);
    });

    testWidgets('Go On Duty does not open sheet when there are no routes',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([], isOnDuty: false);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      expect(find.text('Select route to start'), findsNothing);
    });

    testWidgets('Going offline reloads today routes',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([morningRoute], isOnDuty: true);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCount = api.getTodayRoutesCallCount;

      await tester.tap(find.text('Go Offline'));
      await tester.pumpAndSettle();

      expect(api.getTodayRoutesCallCount, greaterThan(initialCount));
    });
  });

  // ─── Tests: Duty Status Persistence & Tab Switching ────────────────────────

  group('DriverHomeView duty status persistence & tab switching', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
    });

    testWidgets(
        'While profile is loading and duty state is unknown, shows Loading... and not Go On Duty',
        (WidgetTester tester) async {
      final completer = Completer<DriverProfile?>();
      final api = FakeDriverApiService([]);
      api.getProfileCompleter = completer;

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );

      // Frame 1: profile is still loading and duty state is unknown
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Go On Duty'), findsNothing);
      expect(find.text('Go Offline'), findsNothing);

      // Complete profile loading with isOnDuty = false
      completer.complete(DriverProfile(
        id: 'drv_1',
        name: 'Test Driver',
        isOnDuty: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Loading...'), findsNothing);
      expect(find.text('Go On Duty'), findsOneWidget);
    });

    testWidgets(
        'Tapping Go On Duty updates button to Go Offline and updates isOnDutyNotifier',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([], isOnDuty: false);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Go On Duty'), findsOneWidget);
      expect(api.isOnDutyNotifier.value, isFalse);

      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      expect(find.text('Go Offline'), findsOneWidget);
      expect(api.isOnDutyNotifier.value, isTrue);
    });

    testWidgets(
        'Duty state survives simulated tab switch and widget rebuild',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([], isOnDuty: true);

      // Simulate first mount and loaded duty status
      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Go Offline'), findsOneWidget);
      expect(api.isOnDutyNotifier.value, isTrue);

      // Simulate switching tabs away and coming back:
      // A new DriverHomeView instance is created with the same driverApiService.
      final completer = Completer<DriverProfile?>();
      api.getProfileCompleter = completer;

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );

      // Even before getProfile resolves, the known duty state from the notifier is shown!
      await tester.pump();

      expect(find.text('Go Offline'), findsOneWidget);
      expect(find.text('Go On Duty'), findsNothing);
      expect(find.text('Loading...'), findsNothing);

      completer.complete(DriverProfile(
        id: 'drv_1',
        name: 'Test Driver',
        isOnDuty: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Go Offline'), findsOneWidget);
    });

    testWidgets(
        'Duty toggle API failure reverts _isOnDuty and notifier and shows error',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([], isOnDuty: false);
      api.shouldThrowOnToggle = true;

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Go On Duty'), findsOneWidget);
      expect(api.isOnDutyNotifier.value, isFalse);

      await tester.tap(find.text('Go On Duty'));
      await tester.pumpAndSettle();

      // Should have reverted back to Go On Duty and notifier false
      expect(find.text('Go On Duty'), findsOneWidget);
      expect(api.isOnDutyNotifier.value, isFalse);
      expect(
        find.text("Couldn't update duty status. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets(
        'App resume triggers _loadProfile to re-sync server state',
        (WidgetTester tester) async {
      final api = FakeDriverApiService([], isOnDuty: false);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverHomeView(
            authService: mockAuth,
            driverApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialProfileCalls = api.getProfileCallCount;

      // Simulate AppLifecycleState.resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(api.getProfileCallCount, greaterThan(initialProfileCalls));
    });
  });
}
