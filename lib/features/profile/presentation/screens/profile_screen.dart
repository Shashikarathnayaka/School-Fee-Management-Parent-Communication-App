import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/auth_service.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService authService;

  const ProfileScreen({
    super.key,
    required this.authService,
  });

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
    final user = authService.currentUser;
    final isDriver = user?.role == UserRole.driver;
    final userName = user?.name ?? (isDriver ? 'Kamal Silva' : 'Shashi Karathnayaka');
    final userEmail = user?.email ?? (isDriver ? 'driver@test.com' : 'parent@test.com');
    final roleLabel = isDriver ? 'School Van Driver' : 'Parent / Guardian';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: Text(
          isDriver ? 'Driver Profile' : 'Parent Profile',
          style: const TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: isDriver ? 4 : 3,
        userRole: user?.role,
        onTap: (index) => _onBottomNavTapped(context, index, isDriver),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // User Avatar & Name
              CircleAvatar(
                radius: 40,
                backgroundColor: isDriver ? AppColors.accentTeal : AppColors.primaryNavy,
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
                  color: isDriver ? AppColors.accentTeal.withValues(alpha: 0.1) : AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: isDriver ? AppColors.accentTeal : AppColors.primaryBlue,
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
                    if (!isDriver) ...[
                      ListTile(
                        leading: const Icon(Icons.child_care_rounded,
                            color: AppColors.primaryBlue),
                        title: const Text('Managed Students'),
                        subtitle: const Text('2 registered children'),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Student manager coming soon')),
                          );
                        },
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
                    await authService.logout();
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

