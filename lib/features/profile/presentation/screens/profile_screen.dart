import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/student_list_notifier.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final StudentListNotifier? studentListNotifier;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.studentListNotifier,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.studentListNotifier?.addListener(_onStudentListChanged);
  }

  @override
  void dispose() {
    widget.studentListNotifier?.removeListener(_onStudentListChanged);
    super.dispose();
  }

  void _onStudentListChanged() {
    if (mounted) {
      setState(() {});
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
    final theme = Theme.of(context);
    final user = widget.authService.currentUser;
    
    // We use the active role to decide which UI mode we are currently rendering.
    final activeRole = widget.activeRoleNotifier.value;
    final isDriverMode = activeRole == UserRole.driver;
    final hasDualRole = user?.hasDualRole ?? false;

    final userName = user?.name ?? (isDriverMode ? 'Kamal Silva' : 'Shashi Karathnayaka');
    final userEmail = user?.email ?? (isDriverMode ? 'driver@test.com' : 'parent@test.com');
    final roleLabel = isDriverMode ? 'School Van Driver' : 'Parent / Guardian';

    final studentCount = widget.studentListNotifier?.students.length ?? 0;
    final String studentCountText;
    if (studentCount == 0) {
      studentCountText = 'No registered children';
    } else if (studentCount == 1) {
      studentCountText = '1 registered child';
    } else {
      studentCountText = '$studentCount registered children';
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Text(
          isDriverMode ? 'Driver Profile' : 'Parent Profile',
          style: const TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: isDriverMode ? 4 : 3,
        userRole: activeRole,
        onTap: (index) => _onBottomNavTapped(context, index, isDriverMode),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              
              if (hasDualRole) ...[
                // Segmented control for role switching
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment<UserRole>(
                      value: UserRole.parent,
                      label: Text(AppStrings.roleSwitchParent),
                      icon: Icon(Icons.family_restroom_rounded),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.driver,
                      label: Text(AppStrings.roleSwitchDriver),
                      icon: Icon(Icons.airport_shuttle_rounded),
                    ),
                  ],
                  selected: {activeRole},
                  onSelectionChanged: (Set<UserRole> newSelection) {
                    final selected = newSelection.first;
                    if (selected != activeRole) {
                      widget.activeRoleNotifier.value = selected;
                      context.go(AppRoutes.home);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return activeRole == UserRole.driver
                              ? AppColors.accentTeal.withValues(alpha: 0.2)
                              : AppColors.primaryBlueLight;
                        }
                        return AppColors.surfaceWhite;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // User Avatar & Name
              CircleAvatar(
                radius: 40,
                backgroundColor: isDriverMode ? AppColors.accentTeal : AppColors.primaryNavy,
                child: Text(
                  userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDriverMode ? AppColors.accentTeal.withValues(alpha: 0.1) : AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: isDriverMode ? AppColors.accentTeal : AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Options Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded,
                          color: AppColors.primaryBlue),
                      title: const Text('Personal Information'),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile details coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    if (!isDriverMode) ...[
                      ListTile(
                        leading: const Icon(Icons.child_care_rounded,
                            color: AppColors.primaryBlue),
                        title: const Text('Managed Students'),
                        subtitle: Text(studentCountText),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                        onTap: () => context.go(AppRoutes.manageStudents),
                      ),
                      const Divider(height: 1, color: AppColors.cardBorder),
                    ] else ...[
                      ListTile(
                        leading: const Icon(Icons.airport_shuttle_rounded,
                            color: AppColors.primaryBlue),
                        title: const Text('Vehicle & License Details'),
                        subtitle: const Text('Van # WP NC-4821'),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehicle details coming soon')),
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppColors.cardBorder),
                    ],
                    ListTile(
                      leading: const Icon(Icons.security_rounded,
                          color: AppColors.primaryBlue),
                      title: const Text('Security & Password'),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Security settings coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.authService.logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'N&D Smart SchoolPay v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
