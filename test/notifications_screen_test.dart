import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/auth_user.dart';
import 'package:nd_smart_schoolpay/core/models/notification_model.dart';
import 'package:nd_smart_schoolpay/core/models/user_role.dart';
import 'package:nd_smart_schoolpay/core/network/api_client.dart';
import 'package:nd_smart_schoolpay/core/services/active_role_notifier.dart';
import 'package:nd_smart_schoolpay/core/services/auth_service.dart';
import 'package:nd_smart_schoolpay/core/services/parent_api_service.dart';
import 'package:nd_smart_schoolpay/features/notifications/presentation/screens/notifications_screen.dart';

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

class FakeNotificationsParentApiService extends ParentApiService {
  List<AppNotification> notifications;
  int deleteCallCount = 0;
  String? lastDeletedId;
  int clearCallCount = 0;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnClear = false;

  FakeNotificationsParentApiService({
    required this.notifications,
  }) : super(FakeApiClient());

  @override
  Future<List<AppNotification>> getNotifications() async => notifications;

  @override
  Future<void> deleteNotification(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
    if (shouldThrowOnDelete) {
      throw Exception('Failed to delete notification');
    }
  }

  @override
  Future<void> clearNotifications() async {
    clearCallCount++;
    if (shouldThrowOnClear) {
      throw Exception('Failed to clear notifications');
    }
  }
}

void main() {
  group('NotificationsScreen Swipe to Delete & Clear All Tests', () {
    late MockAuthService mockAuth;
    late ActiveRoleNotifier activeRoleNotifier;

    setUp(() {
      mockAuth = MockAuthService();
      activeRoleNotifier = ActiveRoleNotifier();
      activeRoleNotifier.value = UserRole.parent;
    });

    final n1 = AppNotification(
      id: 'notif_1',
      title: 'Bus Arriving Soon',
      message: 'Bus is 5 mins away from your location.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    );

    final n2 = AppNotification(
      id: 'notif_2',
      title: 'Fee Payment Received',
      message: 'Payment for October has been confirmed.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    );

    testWidgets('Swipe to delete removes item from UI and calls deleteNotification once',
        (WidgetTester tester) async {
      final api = FakeNotificationsParentApiService(notifications: [n1, n2]);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            authService: mockAuth,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bus Arriving Soon'), findsOneWidget);
      expect(find.text('Fee Payment Received'), findsOneWidget);

      // Dismiss first notification by swiping right to left
      await tester.drag(find.text('Bus Arriving Soon'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Verify item removed from UI
      expect(find.text('Bus Arriving Soon'), findsNothing);
      expect(find.text('Fee Payment Received'), findsOneWidget);

      // Verify API was called once with id
      expect(api.deleteCallCount, 1);
      expect(api.lastDeletedId, 'notif_1');
      expect(find.text('Notification deleted'), findsOneWidget);
    });

    testWidgets('Swipe delete failure restores item in UI and displays error SnackBar',
        (WidgetTester tester) async {
      final api = FakeNotificationsParentApiService(notifications: [n1, n2]);
      api.shouldThrowOnDelete = true;

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            authService: mockAuth,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bus Arriving Soon'), findsOneWidget);

      // Dismiss first notification
      await tester.drag(find.text('Bus Arriving Soon'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Since API failed, item should be restored!
      expect(find.text('Bus Arriving Soon'), findsOneWidget);
      expect(
        find.text('Failed to delete notification. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Clear all action shows confirmation dialog and clears all on confirm',
        (WidgetTester tester) async {
      final api = FakeNotificationsParentApiService(notifications: [n1, n2]);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            authService: mockAuth,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bus Arriving Soon'), findsOneWidget);
      expect(find.byKey(const Key('clear_all_notifications_btn')), findsOneWidget);

      // Tap Clear all button
      await tester.tap(find.byKey(const Key('clear_all_notifications_btn')));
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Clear All Notifications?'), findsOneWidget);

      // Cancel keeps the items
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Bus Arriving Soon'), findsOneWidget);
      expect(api.clearCallCount, 0);

      // Open dialog again and confirm
      await tester.tap(find.byKey(const Key('clear_all_notifications_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(api.clearCallCount, 1);
      expect(find.text('No recent notifications'), findsOneWidget);
      expect(find.text('All notifications cleared'), findsOneWidget);
    });

    testWidgets('Clear all failure restores notifications and shows error SnackBar',
        (WidgetTester tester) async {
      final api = FakeNotificationsParentApiService(notifications: [n1, n2]);
      api.shouldThrowOnClear = true;

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            authService: mockAuth,
            activeRoleNotifier: activeRoleNotifier,
            parentApiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('clear_all_notifications_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Should be restored
      expect(find.text('Bus Arriving Soon'), findsOneWidget);
      expect(find.text('Fee Payment Received'), findsOneWidget);
      expect(
        find.text('Failed to clear notifications. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
