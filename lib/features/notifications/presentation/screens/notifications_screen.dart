import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../home/domain/models/notification_item.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/notification_preview_card.dart';

class NotificationsScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final ParentApiService? parentApiService;
  final DriverApiService? driverApiService;

  const NotificationsScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.parentApiService,
    this.driverApiService,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ParentApiService can be constructed with no mandatory args (ApiClient is
  // optional), so default locally like the other screens.
  late final ParentApiService _parentApiService =
      widget.parentApiService ?? ParentApiService();

  // DriverApiService requires an ApiClient, so fall back to ServiceLocator when
  // no test mock is injected.
  late final DriverApiService _driverApiService =
      widget.driverApiService ?? ServiceLocator.instance.driverApiService;

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.activeRoleNotifier.addListener(_onRoleChanged);
    _loadNotifications();
  }

  @override
  void dispose() {
    widget.activeRoleNotifier.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() {
    if (!mounted) return;
    _loadNotifications();
  }

  static NotificationItem toNotificationItem(AppNotification n) =>
      NotificationItem.fromNotification(n);

  NotificationItem _toNotificationItem(AppNotification n) =>
      toNotificationItem(n);

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final isDriver = widget.activeRoleNotifier.value == UserRole.driver;
      final List<AppNotification> rawList;
      if (isDriver) {
        rawList = await _driverApiService.getNotifications();
      } else {
        rawList = await _parentApiService.getNotifications();
      }

      if (!mounted) return;
      setState(() {
        _notifications = rawList.map(_toNotificationItem).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notifications. Please try again.';
      });
    }
  }

  /// Called when the user taps a notification row.
  /// Marks it as read via the API and immediately reflects the change in the
  /// UI without waiting for a full re-fetch.
  Future<void> _onNotificationTap(NotificationItem item) async {
    if (item.isRead) return;

    // Optimistically update the UI.
    final index = _notifications.indexWhere((n) => n.id == item.id);
    if (index != -1) {
      setState(() {
        _notifications = List<NotificationItem>.from(_notifications)
          ..[index] = item.copyWith(isRead: true);
      });
    }

    try {
      final isDriver = widget.activeRoleNotifier.value == UserRole.driver;
      if (isDriver) {
        await _driverApiService.readNotification(item.id);
      } else {
        await _parentApiService.readNotification(item.id);
      }
    } catch (_) {
      // Silently revert the optimistic update on failure.
      if (!mounted) return;
      if (index != -1) {
        setState(() {
          _notifications = List<NotificationItem>.from(_notifications)
            ..[index] = item;
        });
      }
    }
  }

  void _onBottomNavTapped(BuildContext context, int index, bool isDriver) {
    if (isDriver) {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.driverRoute);
          break;
        case 2:
          context.go(AppRoutes.driverStudents);
          break;
        case 3:
          context.go(AppRoutes.notifications);
          break;
        case 4:
          context.go(AppRoutes.profile);
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.payments);
          break;
        case 2:
          context.go(AppRoutes.notifications);
          break;
        case 3:
          context.go(AppRoutes.profile);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = widget.activeRoleNotifier.value;
    final isDriver = activeRole == UserRole.driver;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: isDriver ? 3 : 2,
        userRole: activeRole,
        onTap: (index) => _onBottomNavTapped(context, index, isDriver),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () => _loadNotifications(isRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Updates & Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Stay informed about fee due dates and school announcements.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  Container(
                    height: 140,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _loadNotifications(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  NotificationPreviewCard(
                    notifications: _notifications,
                    onItemTap: _onNotificationTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
