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

  FakeDriverApiService(this.routes) : super(FakeApiClient());

  @override
  Future<DriverProfile?> getProfile() async => DriverProfile(
        id: 'drv_1',
        name: 'Test Driver',
        phone: '0771111111',
        vanNumber: 'WP AA-0001',
        licenseNo: 'A0000001',
        isOnDuty: false,
      );

  @override
  Future<List<DriverRoute>> getTodayRoutes() async => routes;

  @override
  Future<List<AppNotification>> getNotifications() async => [];
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
}
