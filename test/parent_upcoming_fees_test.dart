import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/auth_user.dart';
import 'package:nd_smart_schoolpay/core/models/fee.dart';
import 'package:nd_smart_schoolpay/core/models/parent_profile.dart';
import 'package:nd_smart_schoolpay/core/models/student.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/parent_api_service.dart';
import 'package:nd_smart_schoolpay/core/services/student_list_notifier.dart';
import 'package:nd_smart_schoolpay/features/home/presentation/views/parent_home_view.dart';
import 'package:nd_smart_schoolpay/features/home/presentation/widgets/upcoming_fee_card.dart';

class FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  bool get isAuthenticated => true;

  @override
  AuthUser? get currentUser => const AuthUser(
        id: 'p1',
        name: 'Parent User',
        email: 'parent@example.com',
        roles: {UserRole.parent},
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class FakeParentApiService extends ParentApiService {
  List<Fee> fees;
  List<Student> students;

  FakeParentApiService({
    this.fees = const [],
    this.students = const [],
  }) : super(FakeApiClient());

  @override
  Future<ParentProfile?> getProfile() async => ParentProfile(
        id: 'p1',
        name: 'Parent User',
        hasDriverProfile: false,
      );

  @override
  Future<List<Fee>> getFees() async => fees;

  @override
  Future<List<Student>> getStudents() async => students;
}

void main() {
  group('ParentHomeView Upcoming Fees (Next Payment) Tests', () {
    late MockAuthService mockAuth;
    final now = DateTime.now();

    final student1 = Student(
      id: 's1',
      name: 'Kamal Perera',
      studentCode: 'KP01',
    );
    final student2 = Student(
      id: 's2',
      name: 'Nimal Perera',
      studentCode: 'NP02',
    );
    final student3 = Student(
      id: 's3',
      name: 'Amal Perera',
      studentCode: 'AP03',
    );

    setUp(() {
      mockAuth = MockAuthService();
    });

    testWidgets(
        'Displays all children\'s unpaid fees for the current month excluding selected child current fee',
        (WidgetTester tester) async {
      // Fee 1: Student 1 current month (will be selected child's current fee)
      final fee1 = Fee(
        id: 'f1',
        studentId: 's1',
        studentName: 'Kamal Perera',
        amount: 5000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
        dueDate: DateTime(now.year, now.month, 15),
      );

      // Fee 2: Student 2 current month
      final fee2 = Fee(
        id: 'f2',
        studentId: 's2',
        studentName: 'Nimal Perera',
        amount: 4500,
        status: 'PENDING',
        month: now.month,
        year: now.year,
        dueDate: DateTime(now.year, now.month, 18),
      );

      // Fee 3: Student 3 current month
      final fee3 = Fee(
        id: 'f3',
        studentId: 's3',
        studentName: 'Amal Perera',
        amount: 6000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
        dueDate: DateTime(now.year, now.month, 20),
      );

      final api = FakeParentApiService(
        students: [student1, student2, student3],
        fees: [fee1, fee2, fee3],
      );
      final notifier = StudentListNotifier(api);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuth,
            parentApiService: api,
            studentListNotifier: notifier,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Student 1 is selected by default -> fee1 is in the Current Fee Card
      // Next Payment section should show fee2 and fee3
      expect(find.text('Next Payment'), findsOneWidget);
      expect(find.byType(UpcomingFeeCard), findsNWidgets(2));

      // Nimal and Amal should be shown in the upcoming fee cards
      expect(find.textContaining('Nimal Perera'), findsOneWidget);
      expect(find.textContaining('Amal Perera'), findsOneWidget);
      expect(find.text('Rs. 4,500'), findsOneWidget);
      expect(find.text('Rs. 6,000'), findsOneWidget);

      // Total this month line should show sum of upcoming fees: Rs. 10,500
      expect(find.text('Total this month: Rs. 10,500'), findsOneWidget);
    });

    testWidgets('Sorts upcoming fees by due date then student name',
        (WidgetTester tester) async {
      final feeLate = Fee(
        id: 'f_late',
        studentId: 's2',
        studentName: 'Nimal Perera',
        amount: 4000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
        dueDate: DateTime(now.year, now.month, 25),
      );

      final feeEarly = Fee(
        id: 'f_early',
        studentId: 's3',
        studentName: 'Amal Perera',
        amount: 3000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
        dueDate: DateTime(now.year, now.month, 10),
      );

      final feeSelected = Fee(
        id: 'f_sel',
        studentId: 's1',
        studentName: 'Kamal Perera',
        amount: 5000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
        dueDate: DateTime(now.year, now.month, 5),
      );

      final api = FakeParentApiService(
        students: [student1, student2, student3],
        fees: [feeSelected, feeLate, feeEarly],
      );
      final notifier = StudentListNotifier(api);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuth,
            parentApiService: api,
            studentListNotifier: notifier,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = tester.widgetList<UpcomingFeeCard>(find.byType(UpcomingFeeCard)).toList();
      expect(cards.length, 2);
      // First card should be Amal (due 10th), second should be Nimal (due 25th)
      expect(cards[0].upcomingFee.title, contains('Amal Perera'));
      expect(cards[1].upcomingFee.title, contains('Nimal Perera'));
    });

    testWidgets('Shows View all action when more than 3 upcoming fees exist',
        (WidgetTester tester) async {
      final student4 = Student(id: 's4', name: 'Dan Perera', studentCode: 'DP04');
      final student5 = Student(id: 's5', name: 'Eve Perera', studentCode: 'EP05');

      final feeSelected = Fee(
        id: 'f1',
        studentId: 's1',
        amount: 1000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
      );
      final fee2 = Fee(id: 'f2', studentId: 's2', studentName: 'Nimal', amount: 2000, status: 'PENDING', month: now.month, year: now.year);
      final fee3 = Fee(id: 'f3', studentId: 's3', studentName: 'Amal', amount: 3000, status: 'PENDING', month: now.month, year: now.year);
      final fee4 = Fee(id: 'f4', studentId: 's4', studentName: 'Dan', amount: 4000, status: 'PENDING', month: now.month, year: now.year);
      final fee5 = Fee(id: 'f5', studentId: 's5', studentName: 'Eve', amount: 5000, status: 'PENDING', month: now.month, year: now.year);

      final api = FakeParentApiService(
        students: [student1, student2, student3, student4, student5],
        fees: [feeSelected, fee2, fee3, fee4, fee5],
      );
      final notifier = StudentListNotifier(api);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuth,
            parentApiService: api,
            studentListNotifier: notifier,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 3 cards shown in the preview
      expect(find.byType(UpcomingFeeCard), findsNWidgets(3));
      // "View all" action is rendered
      expect(find.byKey(const Key('upcoming_fees_view_all_btn')), findsOneWidget);
      expect(find.text('4 upcoming fees'), findsOneWidget);
    });

    testWidgets('Hides Next Payment section when there are no upcoming fees',
        (WidgetTester tester) async {
      final feeSelected = Fee(
        id: 'f1',
        studentId: 's1',
        amount: 1000,
        status: 'PENDING',
        month: now.month,
        year: now.year,
      );

      final api = FakeParentApiService(
        students: [student1],
        fees: [feeSelected],
      );
      final notifier = StudentListNotifier(api);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuth,
            parentApiService: api,
            studentListNotifier: notifier,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UpcomingFeeCard), findsNothing);
      expect(find.text('Next Payment'), findsNothing);
    });
  });
}
