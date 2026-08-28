import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/auth_service.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/quick_actions_grid.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../data/mock_driver_data.dart';
import '../../domain/models/pickup_record.dart';

class DriverHomeView extends StatefulWidget {
  final AuthService authService;

  const DriverHomeView({
    super.key,
    required this.authService,
  });

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  bool _isOnDuty = true;

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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driverName = widget.authService.currentUser?.name ?? MockDriverData.driverName;
    final route = MockDriverData.currentRoute;
    final pickups = MockDriverData.pickups;
    final summary = MockDriverData.todaySummary;
    final announcements = MockDriverData.announcements;

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
              // Header Greeting
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

              // Driver Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnDuty ? AppColors.success : AppColors.error,
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
                          Text(
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isOnDuty = !_isOnDuty;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isOnDuty ? AppColors.error : AppColors.primaryBlue,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isOnDuty ? 'Go Offline' : 'Go On Duty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isOnDuty ? AppColors.error : AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),


              Container(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            route.status,
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
                      route.routeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Route: ${route.pathDescription}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          route.startTime,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${route.studentCount} Students',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              ),
              const SizedBox(height: 24),


              // Today's Pickups Section
              SectionHeader(
                title: "Today's Pickups",
                onViewAll: () => context.go(AppRoutes.driverStudents),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  for (int i = 0; i < pickups.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pickups[i].time,
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
                                  pickups[i].studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pickups[i].grade} • ${pickups[i].pickupPoint}',
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
                              Icon(pickups[i].status.icon, color: pickups[i].status.color, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                pickups[i].status.label,
                                style: TextStyle(
                                  color: pickups[i].status.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),


              // Quick Actions Section
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

              // Trip Summary Section
              Text(
                "Today's Summary",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat('Trips', summary.totalTrips.toString(), Icons.directions_bus_rounded),
                    _buildSummaryStat('Students', summary.totalStudents.toString(), Icons.school_rounded),
                    _buildSummaryStat('Picked Up', summary.completedPickups.toString(), Icons.check_circle_rounded),
                    _buildSummaryStat('Pending', summary.pendingPickups.toString(), Icons.pending_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Driver Announcements Section
              SectionHeader(
                title: 'Latest Updates',
                onViewAll: () => context.go(AppRoutes.notifications),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: announcements.map((announcement) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              announcement,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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
}
