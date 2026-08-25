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
      expect(find.text(AppStrings.registerNow), findsOneWidget);
      await tester.tap(find.text(AppStrings.registerNow));
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
  });
}
