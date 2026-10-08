import 'dart:async';

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
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/quick_actions_grid.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../domain/models/pickup_record.dart';

/// Returns true when [now] (Sri Lanka local time) is before 12:00 noon.
/// Pass a [DateTime] for testing; defaults to [nowInSriLanka] when null.
bool isMorningNow([DateTime? now]) {
  final t = now ?? nowInSriLanka;
  return t.hour < 12;
}

/// Returns true when a manual route selection was made in a *different* period
/// than the current one, i.e. the user picked in the morning but it is now
/// afternoon (or vice-versa). When [manualPeriodIsMorning] is null there is no
/// manual selection and this returns false.
bool shouldResetManualSelection({
  required bool? manualPeriodIsMorning,
  required DateTime now,
}) {
  if (manualPeriodIsMorning == null) return false;
  return manualPeriodIsMorning != isMorningNow(now);
}

/// Pure, unit-testable function to pick the default route ID for today.
/// Before 12:00 (Sri Lanka time), it picks the first HOME_TO_SCHOOL route.
/// From 12:00 on, it picks the first SCHOOL_TO_HOME route.
/// Fallback: the first route in [routes], or null if [routes] is empty.
String? pickDefaultRouteId(List<DriverRoute> routes, DateTime nowInSriLanka) {
  if (routes.isEmpty) return null;
  if (nowInSriLanka.hour < 12) {
    for (final route in routes) {
      if (route.direction == RouteDirection.homeToSchool) {
        return route.id;
      }
    }
  } else {
    for (final route in routes) {
      if (route.direction == RouteDirection.schoolToHome) {
        return route.id;
      }
    }
  }
  return routes.first.id;
}

DateTime get nowInSriLanka =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

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

class _DriverHomeViewState extends State<DriverHomeView>
    with WidgetsBindingObserver {
  late final DriverApiService _driverApiService =
      widget.driverApiService ?? ServiceLocator.instance.driverApiService;

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
  String? _selectedRouteId;
  bool _hasManuallySelectedRoute = false;

  /// Whether the manual selection was made during the morning period.
  /// null means no manual selection exists.
  bool? _manualPeriodIsMorning;

  DriverRoute? get _selectedRoute {
    if (_todayRoutes.isEmpty) return null;
    final match = _todayRoutes.where((r) => r.id == _selectedRouteId);
    return match.isNotEmpty ? match.first : _todayRoutes.first;
  }

  /// Returns true only when the selected route is live for the current period.
  ///
  /// Priority:
  ///   1. `route.isActiveNow` — the server-supplied flag from `is_active_now`.
  ///      Used when non-null so the app and server always agree.
  ///   2. Local-clock fallback — compares route direction against the current
  ///      Asia/Colombo hour when the server didn't include the field.
  bool get _isSelectedRouteLive {
    final route = _selectedRoute;
    if (route == null) return false;
    // Prefer the authoritative server flag when available.
    if (route.isActiveNow != null) return route.isActiveNow!;
    // Fallback: derive from the local clock (UTC+5:30).
    final expectedDirection = isMorningNow()
        ? RouteDirection.homeToSchool
        : RouteDirection.schoolToHome;
    return route.direction == expectedDirection;
  }

  // ── Notifications (drives the "Latest Updates" section) ─────────────────
  List<AppNotification> _notifications = [];
  bool _isLoadingNotifications = true;

  // ── 60-second period-flip timer ──────────────────────────────────────────
  Timer? _periodTimer;

  /// Remembers the last known period so we can detect flips.
  late bool _lastKnownIsMorning;

  @override
  void initState() {
    super.initState();
    _lastKnownIsMorning = isMorningNow();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _loadTodayRoutes();
    _loadNotifications();

    // Check every 60 seconds whether the period has flipped.
    _periodTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final nowMorning = isMorningNow();
      if (nowMorning != _lastKnownIsMorning) {
        _lastKnownIsMorning = nowMorning;
        _loadTodayRoutes();
        _loadNotifications();
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowMorning
                  ? 'Morning rides are now available'
                  : 'Evening rides are now available',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTodayRoutes();
      _loadNotifications();
    }
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

        // Reset manual selection when the period has changed since the user
        // last tapped a chip.
        final now = nowInSriLanka;
        if (shouldResetManualSelection(
          manualPeriodIsMorning: _manualPeriodIsMorning,
          now: now,
        )) {
          _hasManuallySelectedRoute = false;
          _manualPeriodIsMorning = null;
        }

        if (!_hasManuallySelectedRoute ||
            !_todayRoutes.any((r) => r.id == _selectedRouteId)) {
          _selectedRouteId = pickDefaultRouteId(_todayRoutes, now);
          _hasManuallySelectedRoute = false;
          _manualPeriodIsMorning = null;
        }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  // ── Pickup actions ───────────────────────────────────────────────────────

  /// Student id currently being updated (disables that row's buttons).
  String? _updatingStudentId;

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handlePickup(Student student, String status) async {
    if (_updatingStudentId != null) return;

    if (_selectedRoute == null) {
      _showSnack('Could not find this student\'s route.', isError: true);
      return;
    }
    final routeId = _selectedRoute!.id;

    // Guard: prevent pickup actions on the wrong time-period route.
    // Wording is derived from the selected route's *direction* (not the local
    // clock) so the message never contradicts the lock state when the server's
    // is_active_now flag and the device clock disagree.
    if (!_isSelectedRouteLive) {
      final isMorningRoute =
          _selectedRoute!.direction == RouteDirection.homeToSchool;
      _showSnack(
        isMorningRoute
            ? 'Only the morning (Home -> School) route can be used before 12:00 PM.'
            : 'Only the evening (School -> Home) route can be used from 12:00 PM.',
        isError: true,
      );
      return;
    }

    setState(() => _updatingStudentId = student.id);
    try {
      final result = await _driverApiService.updatePickupStatus(
        studentId: student.id,
        status: status,
        routeId: routeId,
      );
      await _loadTodayRoutes();

      final chargeAmount = result.charge?.amount;
      final chargeFormatted = (chargeAmount != null && chargeAmount > 0)
          ? (chargeAmount % 1 == 0
              ? chargeAmount.toInt().toString()
              : chargeAmount.toStringAsFixed(2))
          : null;

      final String message;
      switch (status) {
        case 'PICKED_UP':
          message = '${student.name} picked up';
          break;
        case 'DROPPED':
          message = (chargeFormatted != null)
              ? '${student.name} dropped off - Rs. $chargeFormatted added to this month\'s fee'
              : '${student.name} dropped off';
          break;
        case 'ABSENT':
          message = '${student.name} marked as absent.';
          break;
        case 'PENDING':
        default:
          message = '${student.name} reset to pending.';
          break;
      }
      _showSnack(message);
    } catch (e) {
      if (e is ApiException && e.code == 'WRONG_PERIOD') {
        // Server confirmed the route is not live for this period.
        // Show the server's message and refresh routes so the UI stays in sync.
        _showSnack(e.message, isError: true);
        await _loadTodayRoutes();
      } else if (e is ApiException &&
          (e.code == 'PICKUP_REQUIRED' ||
              e.message.contains('PICKUP_REQUIRED') ||
              e.statusCode == 409)) {
        _showSnack(
          'Student must be marked as Picked Up before they can be Dropped Off.',
          isError: true,
        );
      } else {
        _showSnack(formatErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _updatingStudentId = null);
    }
  }

  // ── Derived data helpers ─────────────────────────────────────────────────

  /// Maps the raw `pickup_status` string from the backend to [PickupStatus].
  PickupStatus _toPickupStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PICKED_UP':
        return PickupStatus.pickedUp;
      case 'DROPPED':
        return PickupStatus.dropped;
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
    final driverName =
        _profile?.name ?? widget.authService.currentUser?.name ?? 'Driver';

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

              // ── Route selector chips (shown when > 1 route today) ──────────
              if (!_isLoadingRoutes && _todayRoutes.length > 1) ...[
                _buildRouteChips(),
                const SizedBox(height: 12),
              ],

              // ── Missing-route hint card ────────────────────────────────────
              if (!_isLoadingRoutes && _todayRoutes.isNotEmpty)
                _buildMissingRouteHint(),

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

  // ── Route selector chips ──────────────────────────────────────────────────

  Widget _buildRouteChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _todayRoutes.map((route) {
          final isSelected = route.id == _selectedRoute?.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('${route.direction.shortLabel} - ${route.name}'),
              selected: isSelected,
              selectedColor: AppColors.primaryBlueLight,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedRouteId = route.id;
                  _hasManuallySelectedRoute = true;
                  _manualPeriodIsMorning = isMorningNow();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Missing-route hint card ───────────────────────────────────────────────

  /// Returns a hint card when the current period has no matching route.
  /// Returns an empty [SizedBox] when everything is fine.
  Widget _buildMissingRouteHint() {
    final morning = isMorningNow();
    final expectedDirection =
        morning ? RouteDirection.homeToSchool : RouteDirection.schoolToHome;
    final hasMatchingRoute =
        _todayRoutes.any((r) => r.direction == expectedDirection);

    if (hasMatchingRoute) return const SizedBox.shrink();

    final periodLabel = morning ? 'morning' : 'evening';
    final routeLabel = morning ? 'Home -> School' : 'School -> Home';
    final message = morning
        ? 'No morning route yet. Create a $routeLabel route to run the morning ride.'
        : 'No evening route yet. Create a $routeLabel route to run the afternoon ride.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryBlueLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              key: Key('create_${periodLabel}_route_btn'),
              onPressed: () => context.go(AppRoutes.driverRoute),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Create route'),
            ),
          ],
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
                          color: _isOnDuty
                              ? AppColors.success
                              : AppColors.error,
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
                      horizontal: 14,
                      vertical: 8,
                    ),
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

    final students = _selectedRoute?.students ?? <Student>[];

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
            Icon(
              Icons.people_outline_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No students assigned to today\'s route.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
    final timeHint = _selectedRoute?.startTime ?? '--:--';

    final isRowUpdating = _updatingStudentId == student.id;
    final isAnyUpdating = _updatingStudentId != null;

    final isSchoolToHome = _selectedRoute?.direction == RouteDirection.schoolToHome;
    final pickupLoc = (student.pickupLocation != null && student.pickupLocation!.trim().isNotEmpty)
        ? student.pickupLocation!.trim()
        : 'home';
    final school = (student.schoolName != null && student.schoolName!.trim().isNotEmpty)
        ? student.schoolName!.trim()
        : 'school';
    final legSubtitle = isSchoolToHome
        ? 'Pick up: $school - Drop: $pickupLoc'
        : 'Pick up: $pickupLoc - Drop: $school';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                      legSubtitle,
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
          const SizedBox(height: 12),
          if (isRowUpdating)
            Container(
              height: 40,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            )
          else
            _buildPickupActions(student, status, isAnyUpdating),
        ],
      ),
    );
  }

  Widget _buildPickupActions(
    Student student,
    PickupStatus status,
    bool isAnyUpdating,
  ) {
    // If this route is not live for the current period, replace every action
    // with a muted lock banner — no pickup is possible until the period matches.
    if (!_isSelectedRouteLive) {
      return _buildStatusBanner(
        icon: Icons.lock_clock_rounded,
        label: status == PickupStatus.pending ? 'Not available now' : status.label,
        background: AppColors.cardBorder.withValues(alpha: 0.4),
        foreground: AppColors.textSecondary,
      );
    }

    switch (status) {
      case PickupStatus.pending:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: Key('pickup_btn_${student.id}'),
                onPressed: isAnyUpdating
                    ? null
                    : () => _handlePickup(student, 'PICKED_UP'),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Picked Up'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: Key('absent_btn_${student.id}'),
                onPressed: isAnyUpdating
                    ? null
                    : () => _handlePickup(student, 'ABSENT'),
                icon: const Icon(Icons.cancel_rounded, size: 16),
                label: const Text('Absent'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );

      case PickupStatus.pickedUp:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: Key('dropped_btn_${student.id}'),
                onPressed: isAnyUpdating
                    ? null
                    : () => _handlePickup(student, 'DROPPED'),
                icon: const Icon(Icons.home_rounded, size: 16),
                label: const Text('Dropped Off'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildUndoButton(student, isAnyUpdating, 'PENDING'),
          ],
        );

      case PickupStatus.dropped:
        return Row(
          children: [
            Expanded(
              child: _buildStatusBanner(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                background: const Color(0xFFDBEAFE),
                foreground: const Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 10),
            _buildUndoButton(student, isAnyUpdating, 'PICKED_UP'),
          ],
        );

      case PickupStatus.absent:
        return Row(
          children: [
            Expanded(
              child: _buildStatusBanner(
                icon: Icons.cancel_rounded,
                label: 'Absent',
                background: AppColors.errorLight,
                foreground: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            _buildUndoButton(student, isAnyUpdating, 'PENDING'),
          ],
        );

      case PickupStatus.cancelled:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: const Text(
            'Ride Cancelled',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }

  /// Small "Undo" button used next to a status banner.
  /// NOTE: the app theme sets minimumSize to Size(double.infinity, 54) for
  /// buttons, so a button placed in a Row without Expanded must override it.
  Widget _buildUndoButton(
    Student student,
    bool isAnyUpdating,
    String targetStatus,
  ) {
    return OutlinedButton.icon(
      key: Key('undo_btn_${student.id}'),
      onPressed: isAnyUpdating
          ? null
          : () => _handlePickup(student, targetStatus),
      icon: const Icon(Icons.undo_rounded, size: 16),
      label: const Text('Undo'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Status banner shown in place of the primary button (Completed / Absent).
  Widget _buildStatusBanner({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
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

    final selected = _selectedRoute;
    final students = selected?.students ?? <Student>[];
    final totalStudents = students.length;
    final pickedUp = students
        .where((s) => s.pickupStatus?.toUpperCase() == 'PICKED_UP')
        .length;
    final droppedOff = students
        .where((s) => s.pickupStatus?.toUpperCase() == 'DROPPED')
        .length;
    final pending = students
        .where(
          (s) =>
              s.pickupStatus == null ||
              s.pickupStatus!.toUpperCase() == 'PENDING',
        )
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
            'Routes',
            selected != null ? '1' : '0',
            Icons.directions_bus_rounded,
          ),
          _buildSummaryStat(
            'Students',
            totalStudents.toString(),
            Icons.school_rounded,
          ),
          _buildSummaryStat(
            'Picked Up',
            pickedUp.toString(),
            Icons.check_circle_rounded,
          ),
          _buildSummaryStat(
            'Dropped',
            droppedOff.toString(),
            Icons.home_rounded,
          ),
          _buildSummaryStat(
            'Pending',
            pending.toString(),
            Icons.pending_rounded,
          ),
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
            Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'No notifications yet.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                Icon(
                  Icons.route_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
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

    final route = _selectedRoute!;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                timeDisplay,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$studentCount ${studentCount == 1 ? 'Student' : 'Students'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
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
        ],
      ),
    );
  }
}
