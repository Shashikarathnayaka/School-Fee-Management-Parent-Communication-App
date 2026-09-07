import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/constants/app_strings.dart';
import 'package:nd_smart_schoolpay/core/models/student.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/parent_api_service.dart';
import 'package:nd_smart_schoolpay/core/services/student_list_notifier.dart';
import 'package:nd_smart_schoolpay/features/auth/presentation/widgets/auth_button.dart';
import 'package:nd_smart_schoolpay/features/home/presentation/screens/add_student_screen.dart';
import 'package:nd_smart_schoolpay/features/home/presentation/views/parent_home_view.dart';
import 'package:nd_smart_schoolpay/features/profile/presentation/screens/manage_students_screen.dart';

class MockParentApiService extends ParentApiService {
  final List<Student> mockStudents;
  final Student? mockAddResult;
  bool addStudentCalled = false;
  Map<String, dynamic>? lastAddParams;

  MockParentApiService({
    this.mockStudents = const [],
    this.mockAddResult,
  }) : super();

  @override
  Future<List<Student>> getStudents() async {
    return mockStudents;
  }

  @override
  Future<Student?> addStudent({
    required String name,
    String? grade,
    String? section,
    String? schoolName,
    String? pickupLocation,
  }) async {
    addStudentCalled = true;
    lastAddParams = {
      'name': name,
      'grade': grade,
      'section': section,
      'schoolName': schoolName,
      'pickupLocation': pickupLocation,
    };
    return mockAddResult ??
        Student(
          id: 'stu_new_01',
          name: name,
          studentCode: 'STU-TEST123',
          grade: grade,
          section: section,
          schoolName: schoolName,
          pickupLocation: pickupLocation,
        );
  }
}

void main() {
  group('Add Student Feature Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('AddStudentScreen validates empty student name',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: AddStudentScreen(
            authService: mockAuthService,
            parentApiService: mockApi,
          ),
        ),
      );

      // Tap submit button without entering name
      final submitButton = find.byType(AuthButton);
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify inline validation error shown and API not called
      expect(find.text(AppStrings.reqStudentName), findsOneWidget);
      expect(mockApi.addStudentCalled, isFalse);
    });

    testWidgets('AddStudentScreen submits valid form and shows student code dialog',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService(
        mockAddResult: Student(
          id: 'stu_99',
          name: 'Nimal Silva',
          studentCode: 'STU-NIMAL99',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AddStudentScreen(
            authService: mockAuthService,
            parentApiService: mockApi,
          ),
        ),
      );

      // Enter student name
      final nameFields = find.byType(TextField);
      await tester.enterText(nameFields.at(0), 'Nimal Silva');

      // Tap submit button
      final btn = find.byType(AuthButton);
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Verify API was called with student name
      expect(mockApi.addStudentCalled, isTrue);
      expect(mockApi.lastAddParams?['name'], 'Nimal Silva');

      // Verify Success Dialog is displayed with student code
      expect(find.text(AppStrings.addStudentSuccessDialogTitle), findsOneWidget);
      expect(find.text('STU-NIMAL99'), findsOneWidget);
      expect(find.text(AppStrings.addStudentCodeNotice), findsOneWidget);
    });

    testWidgets('ParentHomeView displays informational empty state without Add Student button when getStudents returns empty list',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService(mockStudents: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuthService,
            parentApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Empty State UI components: shows message directing to Profile, no Add Student button
      expect(find.text(AppStrings.noStudentsTitle), findsOneWidget);
      expect(
        find.text('No students added yet — add one from your Profile'),
        findsOneWidget,
      );
      expect(find.text(AppStrings.addFirstStudentButton), findsNothing);
      expect(find.byIcon(Icons.person_add_rounded), findsNothing);
    });

    testWidgets('ManageStudentsScreen displays empty student state with Add Student CTA when getStudents returns empty list',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService(mockStudents: []);
      final activeRoleNotifier = ActiveRoleNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: ManageStudentsScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Empty State UI on ManageStudentsScreen
      expect(find.text(AppStrings.noStudentsTitle), findsOneWidget);
      expect(find.text('Add Student'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('ManageStudentsScreen displays student cards when getStudents returns students',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService(
        mockStudents: [
          Student(
            id: 'st_test_1',
            name: 'Kasun Bandara',
            grade: '07',
            section: 'B',
            schoolName: 'Royal College',
            studentCode: 'STU-KASUN01',
          ),
        ],
      );
      final activeRoleNotifier = ActiveRoleNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: ManageStudentsScreen(
            authService: mockAuthService,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: mockApi,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify student card is rendered with details
      expect(find.text('Kasun Bandara'), findsOneWidget);
      expect(find.text('Grade 07 - B'), findsOneWidget);
      expect(find.text('Royal College'), findsOneWidget);
      expect(find.text('STU-KASUN01'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      // Floating action button exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('ParentHomeView automatically updates when StudentListNotifier receives a new student',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService(mockStudents: []);
      final sharedNotifier = StudentListNotifier(mockApi);

      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuthService,
            studentListNotifier: sharedNotifier,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially empty
      expect(find.text(AppStrings.noStudentsTitle), findsOneWidget);
      expect(find.text('Kasun Bandara'), findsNothing);

      // Now add a student via shared notifier
      final newStudent = Student(
        id: 'stu_live_01',
        name: 'Kasun Bandara',
        grade: '08',
        section: 'A',
        schoolName: 'N&D School',
        studentCode: 'STU-LIVE01',
      );
      await sharedNotifier.onStudentAdded(newStudent);
      await tester.pumpAndSettle();

      // ParentHomeView automatically updates and shows the new student without restart
      expect(find.text('Kasun Bandara'), findsOneWidget);
      expect(find.text(AppStrings.noStudentsTitle), findsNothing);
    });

    testWidgets('AddStudentScreen updates shared StudentListNotifier so ParentHomeView reflects new student',
        (WidgetTester tester) async {
      final mockApi = MockParentApiService(
        mockStudents: [],
        mockAddResult: Student(
          id: 'stu_new_99',
          name: 'Anuki Rathnayaka',
          studentCode: 'STU-ANUKI99',
          grade: '03',
          section: 'C',
          schoolName: 'St. Bridgets Convent',
        ),
      );
      final sharedNotifier = StudentListNotifier(mockApi);

      // 1. First pump AddStudentScreen with the shared notifier
      await tester.pumpWidget(
        MaterialApp(
          home: AddStudentScreen(
            authService: mockAuthService,
            parentApiService: mockApi,
            studentListNotifier: sharedNotifier,
          ),
        ),
      );

      final nameFields = find.byType(TextField);
      await tester.enterText(nameFields.at(0), 'Anuki Rathnayaka');

      final btn = find.byType(AuthButton);
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Verify success dialog
      expect(find.text('STU-ANUKI99'), findsOneWidget);

      // Dismiss dialog by tapping OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify shared notifier was updated immediately
      expect(sharedNotifier.students.any((s) => s.name == 'Anuki Rathnayaka'), isTrue);

      // 2. Now render ParentHomeView with the same shared notifier
      await tester.pumpWidget(
        MaterialApp(
          home: ParentHomeView(
            authService: mockAuthService,
            studentListNotifier: sharedNotifier,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ParentHomeView displays the newly added student
      expect(find.text('Anuki Rathnayaka'), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.noStudentsTitle), findsNothing);
    });
  });
}
