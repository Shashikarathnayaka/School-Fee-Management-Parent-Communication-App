import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/app/app.dart';
import 'package:nd_smart_schoolpay/core/constants/app_strings.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/parent_api_service.dart';
import 'package:nd_smart_schoolpay/core/services/student_list_notifier.dart';
import 'package:nd_smart_schoolpay/features/home/data/mock_home_data.dart';

void main() {
  group('N&D Smart SchoolPay Role-Based App Flow Tests', () {
    late MockAuthService mockAuthService;
    late ActiveRoleNotifier activeRoleNotifier;
    late StudentListNotifier studentListNotifier;
    late ParentApiService parentApiService;

    setUp(() {
      mockAuthService = MockAuthService();
      activeRoleNotifier = ActiveRoleNotifier();
      parentApiService = ParentApiService();
      // Pre-seed with mock students so the Parent Dashboard test can verify
      // the student card renders — in tests there's no real API, so we
      // simulate the same state the app would have for a logged-in parent.
      studentListNotifier = StudentListNotifier(
        parentApiService,
        initialStudents: MockHomeData.students,
      );
    });

    testWidgets('Renders Splash Screen on launch', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(
        authService: mockAuthService,
        activeRoleNotifier: activeRoleNotifier,
        studentListNotifier: studentListNotifier,
        parentApiService: parentApiService,
      ));

      // Verify Splash branding title and tagline are present
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.appTagline), findsOneWidget);

      // Advance timer by 2 seconds for splash transition
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should automatically navigate to LoginScreen
      expect(find.text(AppStrings.welcomeBack), findsOneWidget);
      expect(find.text(AppStrings.signInButton), findsOneWidget);
    });

    testWidgets('Navigates from Login to Registration Screen and back', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(
        authService: mockAuthService,
        activeRoleNotifier: activeRoleNotifier,
        studentListNotifier: studentListNotifier,
        parentApiService: parentApiService,
      ));

      // Skip splash
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Tap Register link on Login Screen
      final registerFinder = find.text(AppStrings.registerNow);
      expect(registerFinder, findsOneWidget);
      await tester.ensureVisible(registerFinder);
      await tester.tap(registerFinder);
      await tester.pumpAndSettle();

      // Verify Registration Screen is rendered
      expect(find.text(AppStrings.createAccount), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.registerSubtitle), findsOneWidget);

      // Tap Sign In link on Registration Screen to return
      final signInFinder = find.text(AppStrings.signIn);
      await tester.ensureVisible(signInFinder);
      await tester.tap(signInFinder);
      await tester.pumpAndSettle();

      // Verify back on Login Screen
      expect(find.text(AppStrings.welcomeBack), findsOneWidget);
    });

    testWidgets('Logs in successfully as Parent and renders Parent Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(
        authService: mockAuthService,
        activeRoleNotifier: activeRoleNotifier,
        studentListNotifier: studentListNotifier,
        parentApiService: parentApiService,
      ));

      // Skip splash transition
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Enter Parent test credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'parent@test.com');
      await tester.enterText(textFields.at(1), 'Parent@123');

      // Tap Sign In
      await tester.tap(find.text(AppStrings.signInButton));
      await tester.pump();

      // Advance time past the login mock delay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify Parent Dashboard is loaded
      expect(find.textContaining('Good Morning, Shashi Karathnayaka'), findsOneWidget);
      expect(find.text('Kaveesha Rathnayaka'), findsAtLeastNWidgets(1));
      expect(find.text('Rs. 15,000'), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.payNowButton), findsOneWidget);
    });

    testWidgets('Logs in successfully as Driver and renders Driver Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(
        authService: mockAuthService,
        activeRoleNotifier: activeRoleNotifier,
        studentListNotifier: studentListNotifier,
        parentApiService: parentApiService,
      ));

      // Skip splash transition
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Enter Driver test credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'driver@test.com');
      await tester.enterText(textFields.at(1), 'Driver@123');

      // Tap Sign In
      await tester.tap(find.text(AppStrings.signInButton));
      await tester.pump();

      // Advance time past the login mock delay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify Driver Dashboard is loaded
      expect(find.textContaining('Good Morning, Kamal Silva'), findsOneWidget);
      expect(find.text("Today's Route"), findsAtLeastNWidgets(1));
      expect(find.text('Driver Status'), findsOneWidget);
      expect(find.text('On Duty'), findsOneWidget);
      expect(find.text("Today's Pickups"), findsOneWidget);

      // Verify Parent specific content is NOT displayed
      expect(find.text('Rs. 15,000'), findsNothing);
      expect(find.text(AppStrings.payNowButton), findsNothing);
    });


    testWidgets('Displays error on invalid credentials and stays on Login screen', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(
        authService: mockAuthService,
        activeRoleNotifier: activeRoleNotifier,
        studentListNotifier: studentListNotifier,
        parentApiService: parentApiService,
      ));

      // Skip splash transition
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Enter invalid credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'wrong@test.com');
      await tester.enterText(textFields.at(1), 'wrongpass');

      // Tap Sign In
      await tester.tap(find.text(AppStrings.signInButton));
      await tester.pump();

      // Advance time past mock delay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify error snackbar appears and still on Login screen
      expect(find.text(AppStrings.invalidCredentials), findsOneWidget);
      expect(find.text(AppStrings.welcomeBack), findsOneWidget);
    });
  });
}
