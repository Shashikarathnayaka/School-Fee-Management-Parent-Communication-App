import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/fee.dart';
import 'package:nd_smart_schoolpay/core/models/student.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/models/auth_user.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/driver_api_service.dart';
import 'package:nd_smart_schoolpay/features/driver/domain/models/pickup_record.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_home_view.dart';
import 'package:nd_smart_schoolpay/features/driver/presentation/screens/driver_students_screen.dart';
import 'package:nd_smart_schoolpay/features/home/domain/models/fee_summary.dart';
import 'package:nd_smart_schoolpay/features/home/domain/models/payment_record.dart';
import 'package:nd_smart_schoolpay/features/home/presentation/widgets/fee_summary_card.dart';
import 'package:nd_smart_schoolpay/features/home/presentation/widgets/recent_payments_card.dart';

class MockTestAuthService extends MockAuthService {
  @override
  bool get isAuthenticated => true;

  @override
  AuthUser? get currentUser => const AuthUser(
    id: 'usr_driver_01',
    name: 'Kamal Silva',
    email: 'driver@test.com',
    roles: {UserRole.driver},
  );
}

class FakeTestApiClient implements ApiClient {
  dynamic postResponse;
  dynamic patchResponse;
  dynamic getResponse;

  String? lastPostUrl;
  Map<String, dynamic>? lastPostBody;

  String? lastPatchUrl;
  Map<String, dynamic>? lastPatchBody;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    lastPostUrl = url;
    lastPostBody = body;
    return postResponse;
  }

  @override
  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    lastPatchUrl = url;
    lastPatchBody = body;
    return patchResponse;
  }

  @override
  Future<dynamic> get(String url) async {
    return getResponse;
  }
}

void main() {
  group('Fee Model Tests', () {
    test('Fee.fromJson parses numeric amount and new fields correctly', () {
      final json = {
        'id': 'fee_123',
        'student_id': 'stu_456',
        'student_name': 'Kaveesha Silva',
        'amount': 15000.0,
        'status': 'PENDING',
        'due_date': '2026-10-15T00:00:00.000Z',
        'description': 'October Transport',
        'trips_count': 12,
        'trips_total': 40,
        'per_trip_amount': 375.0,
        'month': 10,
        'year': 2026,
      };

      final fee = Fee.fromJson(json);

      expect(fee.id, 'fee_123');
      expect(fee.studentId, 'stu_456');
      expect(fee.studentName, 'Kaveesha Silva');
      expect(fee.amount, 15000.0);
      expect(fee.status, 'PENDING');
      expect(fee.tripsCount, 12);
      expect(fee.tripsTotal, 40);
      expect(fee.perTripAmount, 375.0);
      expect(fee.month, 10);
      expect(fee.year, 2026);
    });

    test('Fee.fromJson parses string amounts and string trips robustly', () {
      final json = {
        'id': 'fee_999',
        'studentId': 'stu_888',
        'amount': '1500.50',
        'status': 'DUE',
        'trips_count': '4',
        'trips_total': '40',
        'per_trip_amount': '375',
        'month': '10',
        'year': '2026',
      };

      final fee = Fee.fromJson(json);

      expect(fee.amount, 1500.50);
      expect(fee.tripsCount, 4);
      expect(fee.tripsTotal, 40);
      expect(fee.perTripAmount, 375.0);
      expect(fee.month, 10);
      expect(fee.year, 2026);
    });

    test(
      'Fee.fromJson defaults tripsTotal to 40 and tripsCount to 0 when omitted',
      () {
        final json = {
          'id': 'fee_001',
          'student_id': 'stu_001',
          'amount': 0,
          'status': 'PENDING',
        };

        final fee = Fee.fromJson(json);

        expect(fee.tripsCount, 0);
        expect(fee.tripsTotal, 40);
        expect(fee.perTripAmount, isNull);
        expect(fee.month, isNull);
        expect(fee.year, isNull);
      },
    );

    test('Fee.toJson outputs all fields', () {
      final fee = Fee(
        id: 'f1',
        studentId: 's1',
        studentName: 'Kasun',
        amount: 3000,
        status: 'PENDING',
        tripsCount: 8,
        tripsTotal: 40,
        perTripAmount: 375,
        month: 10,
        year: 2026,
      );

      final json = fee.toJson();
      expect(json['id'], 'f1');
      expect(json['student_id'], 's1');
      expect(json['student_name'], 'Kasun');
      expect(json['amount'], 3000.0);
      expect(json['trips_count'], 8);
      expect(json['trips_total'], 40);
      expect(json['per_trip_amount'], 375.0);
      expect(json['month'], 10);
      expect(json['year'], 2026);
    });
  });

  group('PickupStatus & DROPPED mapping Tests', () {
    test(
      'PickupStatus enum contains dropped with correct label, icon, and color',
      () {
        const status = PickupStatus.dropped;
        expect(status.label, 'Dropped Off');
        expect(status.icon, Icons.home_rounded);
        expect(status.color, const Color(0xFF2563EB));
      },
    );

    test('PickupRecord.fromJson parses DROPPED status', () {
      final record = PickupRecord.fromJson({
        'id': 'p1',
        'student': {'name': 'Amal'},
        'status': 'DROPPED',
      });

      expect(record.status, PickupStatus.dropped);
    });

    test(
      'Student.fromJson parses DROPPED pickupStatus from string or list',
      () {
        final student1 = Student.fromJson({
          'id': 's1',
          'name': 'Student 1',
          'pickup_status': 'DROPPED',
        });
        expect(student1.pickupStatus, 'DROPPED');

        final student2 = Student.fromJson({
          'id': 's2',
          'name': 'Student 2',
          'pickup_status': [
            {'status': 'DROPPED'},
          ],
        });
        expect(student2.pickupStatus, 'DROPPED');
      },
    );
  });

  group('DriverApiService Per-Trip & Reminders Tests', () {
    late FakeTestApiClient fakeClient;
    late DriverApiService apiService;

    setUp(() {
      fakeClient = FakeTestApiClient();
      apiService = DriverApiService(fakeClient);
    });

    test('updatePickupStatus returns parsed fee and charge', () async {
      fakeClient.patchResponse = {
        'pickup': {'id': 'p123', 'status': 'PICKED_UP'},
        'fee': {
          'id': 'f123',
          'amount': 375,
          'trips_count': 1,
          'trips_total': 40,
          'status': 'PENDING',
        },
        'charge': {'kind': 'PICKUP', 'amount': 375.0},
      };

      final result = await apiService.updatePickupStatus(
        studentId: 'stu_1',
        status: 'PICKED_UP',
        routeId: 'route_1',
      );

      expect(result.charge, isNotNull);
      expect(result.charge!.amount, 375.0);
      expect(result.charge!.kind, 'PICKUP');
      expect(result.fee, isNotNull);
      expect(result.fee!.amount, 375.0);
      expect(result.fee!.tripsCount, 1);
    });

    test('markStudentDropped sends DROPPED status', () async {
      fakeClient.patchResponse = {
        'pickup': {'status': 'DROPPED'},
        'charge': {'amount': 375.0},
      };

      final result = await apiService.markStudentDropped(
        studentId: 'stu_1',
        routeId: 'route_1',
      );

      expect(fakeClient.lastPatchBody?['status'], 'DROPPED');
      expect(result.charge?.amount, 375.0);
    });

    test(
      'sendFeeReminders sends POST and returns parsed sent and skipped',
      () async {
        fakeClient.postResponse = {'sent': 5, 'skipped': 2};

        final result = await apiService.sendFeeReminders(month: 10, year: 2026);

        expect(fakeClient.lastPostBody?['month'], 10);
        expect(fakeClient.lastPostBody?['year'], 2026);
        expect(result.sent, 5);
        expect(result.skipped, 2);
      },
    );
  });

  group('FeeSummaryCard & Payments UI Tests', () {
    testWidgets(
      'FeeSummaryCard renders per-trip details and View Details button',
      (WidgetTester tester) async {
        bool viewDetailsTapped = false;

        const summary = FeeSummary(
          id: 'fee_1',
          title: 'Kaveesha - October transport fee',
          status: FeeStatus.pending,
          amount: 'Rs. 1,500',
          dueDate: 'Due 15 Oct 2026',
          tripsCount: 4,
          tripsTotal: 40,
          perTrip: 375.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeeSummaryCard(
                feeSummary: summary,
                onViewDetails: () {
                  viewDetailsTapped = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Kaveesha - October transport fee'), findsOneWidget);
        expect(find.text('Rs. 1,500'), findsOneWidget);
        expect(find.text('4 of 40 trips - Rs. 375 per trip'), findsOneWidget);
        expect(find.text('View Details'), findsOneWidget);
        expect(find.text('Pay cash to your driver'), findsOneWidget);

        await tester.tap(find.text('View Details'));
        expect(viewDetailsTapped, isTrue);
      },
    );

    testWidgets('FeeSummaryCard renders 0 trips state when no charges yet', (
      WidgetTester tester,
    ) async {
      const summary = FeeSummary(
        id: '',
        title: 'Amal - October transport fee',
        status: FeeStatus.pending,
        amount: 'Rs. 0',
        dueDate: '',
        tripsCount: 0,
        tripsTotal: 40,
        perTrip: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FeeSummaryCard(feeSummary: summary)),
        ),
      );

      expect(find.text('Amal - October transport fee'), findsOneWidget);
      expect(find.text('Rs. 0'), findsOneWidget);
      expect(find.text('0 of 40 trips'), findsOneWidget);
    });

    testWidgets(
      'RecentPaymentsCard renders trips subtitle when perTripAmount exists',
      (WidgetTester tester) async {
        const payment = PaymentRecord(
          id: 'p1',
          title: 'October Transport',
          date: '10 Oct 2026',
          amount: 'Rs. 1500.00',
          status: FeeStatus.due,
          tripsCount: 4,
          tripsTotal: 40,
          perTripAmount: 375.0,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: RecentPaymentsCard(payments: [payment])),
          ),
        );

        expect(find.text('October Transport'), findsOneWidget);
        expect(find.text('4 trips x Rs. 375'), findsOneWidget);
      },
    );
  });

  group('Driver Home Pickup Actions & Dropped flow Tests', () {
    testWidgets(
      'Renders Dropped Off button when status is picked up and Completed indicator when dropped',
      (WidgetTester tester) async {
        final fakeClient = FakeTestApiClient();
        final mockAuth = MockTestAuthService();

        fakeClient.getResponse = {
          'routes': [
            {
              'id': 'r_1',
              'name': 'Morning Bus',
              'status': 'SCHEDULED',
              'students': [
                {
                  'id': 's_picked',
                  'name': 'Saman Perera',
                  'pickup_status': 'PICKED_UP',
                },
                {
                  'id': 's_dropped',
                  'name': 'Nimali Silva',
                  'pickup_status': 'DROPPED',
                },
              ],
            },
          ],
        };

        final apiService = DriverApiService(fakeClient);

        await tester.pumpWidget(
          MaterialApp(
            home: DriverHomeView(
              authService: mockAuth,
              driverApiService: apiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Dropped Off'), findsAtLeastNWidgets(1));
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Undo'), findsAtLeastNWidgets(2));
      },
    );
  });

  group('Driver Students Fee Reminders Dialog Test', () {
    testWidgets(
      'Opens confirmation dialog and calls sendFeeReminders on confirm',
      (WidgetTester tester) async {
        final fakeClient = FakeTestApiClient();
        final mockAuth = MockTestAuthService();
        final activeRole = ActiveRoleNotifier()..value = UserRole.driver;

        fakeClient.getResponse = {
          'routes': [
            {
              'id': 'r1',
              'name': 'Morning Route',
              'status': 'SCHEDULED',
              'students': [
                {
                  'id': 's1',
                  'name': 'Test Student',
                  'pickup_status': 'PENDING',
                },
              ],
            },
          ],
        };

        fakeClient.postResponse = {'sent': 3, 'skipped': 1};

        final apiService = DriverApiService(fakeClient);

        await tester.pumpWidget(
          MaterialApp(
            home: DriverStudentsScreen(
              authService: mockAuth,
              activeRoleNotifier: activeRole,
              driverApiService: apiService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the Send Fee Reminders button in the AppBar
        final reminderBtn = find.byKey(const Key('send_fee_reminders_btn'));
        expect(reminderBtn, findsOneWidget);

        await tester.tap(reminderBtn);
        await tester.pumpAndSettle();

        // Verify the confirmation dialog is displayed
        expect(
          find.text(
            "Send this month's fee reminder to all parents with unpaid fees?",
          ),
          findsOneWidget,
        );

        // Tap Send in dialog
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Send'),
          ),
        );
        await tester.pumpAndSettle();

        // Verify SnackBar with result is displayed
        expect(
          find.text('Reminder sent to 3 parents (1 skipped)'),
          findsOneWidget,
        );
      },
    );
  });
}
