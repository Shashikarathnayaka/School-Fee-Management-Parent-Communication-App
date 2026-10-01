import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/admin_api_service.dart';
import '../../../../core/services/auth_service.dart';
import 'pickups_review_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final AuthService authService;
  final AdminApiService? adminApiService;

  const AdminHomeScreen({
    super.key,
    required this.authService,
    this.adminApiService,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        content: const Text('Are you sure you want to sign out of the Admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.authService.logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? extraContent,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (extraContent != null) ...[
              const SizedBox(height: 20),
              extraContent,
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Coming soon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesTab() {
    if (widget.adminApiService == null) {
      return _buildPlaceholderTab(
        icon: Icons.alt_route_rounded,
        title: 'Routes Management',
        subtitle: 'View and manage driver routes across the system.',
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: widget.adminApiService!.getRoutes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        final routes = snapshot.data ?? [];
        return _buildPlaceholderTab(
          icon: Icons.alt_route_rounded,
          title: 'Routes Management',
          subtitle: 'View and manage driver routes across the system.',
          extraContent: Text(
            '${routes.length} Active System Routes',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickupsTab() {
    if (widget.adminApiService == null) {
      return _buildPlaceholderTab(
        icon: Icons.local_shipping_rounded,
        title: 'Pickups Review',
        subtitle: 'Review student pickup statuses and log tickets.',
      );
    }
    return PickupsReviewScreen(adminApiService: widget.adminApiService!);
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildPickupsTab();
      case 1:
        return _buildRoutesTab();
      case 2:
        return _buildPlaceholderTab(
          icon: Icons.history_rounded,
          title: 'Pickup History',
          subtitle: 'Search and inspect historical student pickup records.',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.surfaceWhite,
            ),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surfaceWhite,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping_rounded),
                label: 'Pickups',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alt_route_outlined),
                activeIcon: Icon(Icons.alt_route_rounded),
                label: 'Routes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
