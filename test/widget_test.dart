import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/app/app.dart';
import 'package:nd_smart_schoolpay/core/constants/app_strings.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';

void main() {
  group('N&D Smart SchoolPay App Flow Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('Renders Splash Screen on launch', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(authService: mockAuthService));

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
      await tester.pumpWidget(SmartSchoolPayApp(authService: mockAuthService));

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

    testWidgets('Logs in successfully with test credentials and renders Home Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(SmartSchoolPayApp(authService: mockAuthService));

      // Skip splash transition
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Enter test credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'parent@test.com');
      await tester.enterText(textFields.at(1), 'Parent@123');

      // Tap Sign In
      await tester.tap(find.text(AppStrings.signInButton));
      await tester.pump(); // Start animation/async login

      // Advance time past the login mock delay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify HomeScreen dashboard is loaded
      expect(find.textContaining('Good Morning, Shashi'), findsOneWidget);
      expect(find.text('Alex Johnson'), findsAtLeastNWidgets(1));
      expect(find.text('Rs. 15,000'), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.payNowButton), findsOneWidget);
    });
  });
}
