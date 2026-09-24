import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/driver_profile.dart';
import '../../../../core/models/driver_route.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/quick_actions_grid.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../domain/models/pickup_record.dart';

class DriverHomeView extends StatefulWidget {
  final AuthService authService;
  final DriverApiService? driverApiService;

  const DriverHomeView({
    super.key,
    required this.authService,
    this.driverApiService,
  });

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  late final DriverApiService _driverApiService = widget.driverApiService ??
      ServiceLocator.instance.driverApiService;

  // ── Profile / duty status ────────────────────────────────────────────────
  DriverProfile? _profile;
  bool _isLoadingProfile = true;

  /// Tracks whether a duty-toggle API call is in-flight.
  bool _isTogglingDuty = false;

  /// The authoritative on-duty flag shown in the UI.
  /// Seeded from [_profile.isOnDuty] once the profile loads.
  bool _isOnDuty = false;

  // ── Today's routes (drives both pickups list and summary card) ───────────
  List<DriverRoute> _todayRoutes = [];
  bool _isLoadingRoutes = true;

  // ── Notifications (drives the "Latest Updates" section) ─────────────────
  List<AppNotification> _notifications = [];
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTodayRoutes();
    _loadNotifications();
  }

  // ── Data loaders ─────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final profile = await _driverApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        // Seed the duty toggle from the real server value.
        if (profile != null) {
          _isOnDuty = profile.isOnDuty;
        }
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadTodayRoutes() async {
    try {
      final routes = await _driverApiService.getTodayRoutes();
      if (!mounted) return;
      setState(() {
        _todayRoutes = routes;
        _isLoadingRoutes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoutes = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _driverApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoadingNotifications = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  // ── Duty toggle ──────────────────────────────────────────────────────────

  Future<void> _handleDutyToggle() async {
    if (_isTogglingDuty) return;

    final newStatus = !_isOnDuty;

    // Optimistically update the UI, but track it so we can roll back.
    setState(() {
      _isTogglingDuty = true;
      _isOnDuty = newStatus;
    });

    try {
      await _driverApiService.toggleDutyStatus(newStatus);
      if (!mounted) return;
      setState(() {
        _isTogglingDuty = false;
      });
    } catch (_) {
      // Roll back on failure and inform the user.
      if (!mounted) return;
      setState(() {
        _isOnDuty = !newStatus;
        _isTogglingDuty = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't update duty status. Please try again."),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Derived data helpers ─────────────────────────────────────────────────

  /// Flattens all students across today's routes, deduplicating by student id.
  List<Student> get _allStudentsToday {
    final seen = <String>{};
    final result = <Student>[];
    for (final route in _todayRoutes) {
      for (final student in route.students ?? <Student>[]) {
        if (seen.add(student.id)) {
          result.add(student);
        }
      }
    }
    return result;
  }

  /// Maps the raw `pickup_status` string from the backend to [PickupStatus].
  PickupStatus _toPickupStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PICKED_UP':
        return PickupStatus.pickedUp;
      case 'ABSENT':
        return PickupStatus.absent;
      case 'CANCELLED':
        return PickupStatus.cancelled;
      default:
        return PickupStatus.pending;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _onBottomNavTapped(int index) {
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
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Driver name: prefer profile from API, fall back to the cached auth user.
    final driverName = _profile?.name ??
        widget.authService.currentUser?.name ??
        'Driver';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
          child: CircleAvatar(
            backgroundColor: AppColors.accentTeal,
            radius: 16,
            child: Text(
              driverName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.surfaceWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.surfaceWhite,
            ),
            tooltip: 'Notifications',
            onPressed: () => context.go(AppRoutes.notifications),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        userRole: UserRole.driver,
        onTap: _onBottomNavTapped,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Greeting ────────────────────────────────────────────
              Text(
                'Good Morning, $driverName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome to N&D Smart SchoolPay',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // ── Driver Status Card ─────────────────────────────────────────
              _buildDriverStatusCard(),
              const SizedBox(height: 20),

              // ── Today's Route Card (already wired — do not change) ─────────
              _buildTodayRouteCard(theme),
              const SizedBox(height: 24),

              // ── Today's Pickups Section ────────────────────────────────────
              SectionHeader(
                title: "Today's Pickups",
                onViewAll: () => context.go(AppRoutes.driverStudents),
              ),
              const SizedBox(height: 12),
              _buildPickupsSection(),
              const SizedBox(height: 24),

              // ── Quick Actions Section ──────────────────────────────────────
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              QuickActionsGrid(
                items: [
                  QuickActionItem(
                    label: "Today's Route",
                    icon: Icons.alt_route_rounded,
                    onTap: () => context.go(AppRoutes.driverRoute),
                  ),
                  QuickActionItem(
                    label: 'Student List',
                    icon: Icons.groups_rounded,
                    onTap: () => context.go(AppRoutes.driverStudents),
                  ),
                  QuickActionItem(
                    label: 'Pickup History',
                    icon: Icons.history_rounded,
                    onTap: () => context.go(AppRoutes.driverHistory),
                  ),
                  QuickActionItem(
                    label: 'Notifications',
                    icon: Icons.notifications_rounded,
                    onTap: () => context.go(AppRoutes.notifications),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Today's Summary Card ───────────────────────────────────────
              Text(
                "Today's Summary",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(),
              const SizedBox(height: 24),

              // ── Latest Updates (notifications) ─────────────────────────────
              SectionHeader(
                title: 'Latest Updates',
                onViewAll: () => context.go(AppRoutes.notifications),
              ),
              const SizedBox(height: 12),
              _buildLatestUpdatesSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildDriverStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Animated status dot: dim while profile is still loading.
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLoadingProfile
                  ? AppColors.textSecondary
                  : (_isOnDuty ? AppColors.success : AppColors.error),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                _isLoadingProfile
                    ? const SizedBox(
                        height: 16,
                        width: 80,
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.cardBorder,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : Text(
                        _isOnDuty ? 'On Duty' : 'Offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isOnDuty ? AppColors.success : AppColors.error,
                        ),
                      ),
              ],
            ),
          ),
          // Toggle button — shows a spinner while the API call is in-flight.
          _isTogglingDuty
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryBlue,
                  ),
                )
              : GestureDetector(
                  onTap: _isLoadingProfile ? null : _handleDutyToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isOnDuty
                            ? AppColors.error
                            : AppColors.primaryBlue,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isOnDuty ? 'Go Offline' : 'Go On Duty',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _isOnDuty
                            ? AppColors.error
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPickupsSection() {
    if (_isLoadingRoutes) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    final students = _allStudentsToday;

    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.people_outline_rounded,
                size: 20, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No students assigned to today\'s route.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < students.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildPickupRow(students[i]),
        ],
      ],
    );
  }

  Widget _buildPickupRow(Student student) {
    final status = _toPickupStatus(student.pickupStatus);
    // Use the route's start time from the first route as a display hint when
    // no per-student scheduled time is available from the backend.
    final timeHint = _todayRoutes.isNotEmpty
        ? (_todayRoutes.first.startTime ?? '--:--')
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timeHint,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.displayGrade} • ${student.pickupLocation ?? 'Pickup point not set'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(status.icon, color: status.color, size: 16),
              const SizedBox(width: 4),
              Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_isLoadingRoutes) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    final students = _allStudentsToday;
    final totalTrips = _todayRoutes.length;
    final totalStudents = students.length;
    final pickedUp = students
        .where((s) =>
            s.pickupStatus?.toUpperCase() == 'PICKED_UP')
        .length;
    final pending = students
        .where((s) =>
            s.pickupStatus == null ||
            s.pickupStatus!.toUpperCase() == 'PENDING')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat(
              'Trips', totalTrips.toString(), Icons.directions_bus_rounded),
          _buildSummaryStat(
              'Students', totalStudents.toString(), Icons.school_rounded),
          _buildSummaryStat(
              'Picked Up', pickedUp.toString(), Icons.check_circle_rounded),
          _buildSummaryStat(
              'Pending', pending.toString(), Icons.pending_rounded),
        ],
      ),
    );
  }

  Widget _buildLatestUpdatesSection() {
    if (_isLoadingNotifications) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.notifications_none_rounded,
                color: AppColors.textSecondary, size: 20),
            SizedBox(width: 12),
            Text(
              'No notifications yet.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Show at most 3 latest notifications as a preview.
    final preview = _notifications.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: preview.map((notification) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  notification.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.campaign_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (notification.message.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayRouteCard(ThemeData theme) {
    if (_isLoadingRoutes) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
    }

    if (_todayRoutes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Route",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.driverRoute),
                  child: const Text(
                    'Create Route',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.route_outlined, size: 20, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No routes scheduled for today.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final route = _todayRoutes.first;
    final startTime = route.startTime;
    final endTime = route.endTime;
    String timeDisplay;
    if (startTime != null && endTime != null) {
      timeDisplay = '$startTime - $endTime';
    } else if (startTime != null) {
      timeDisplay = 'Starts $startTime';
    } else if (endTime != null) {
      timeDisplay = 'Ends $endTime';
    } else {
      timeDisplay = 'Time not set';
    }
    final studentCount = route.students?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Route",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  route.status ?? 'SCHEDULED',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            route.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                timeDisplay,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$studentCount ${studentCount == 1 ? 'Student' : 'Students'}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.driverRoute),
                child: const Text(
                  'View Route',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (_todayRoutes.length > 1) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.go(AppRoutes.driverRoute),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alt_route_rounded,
                        size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      '+${_todayRoutes.length - 1} more ${_todayRoutes.length - 1 == 1 ? 'route' : 'routes'} today • View all',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
