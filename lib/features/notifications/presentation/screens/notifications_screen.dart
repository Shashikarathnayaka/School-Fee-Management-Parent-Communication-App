import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../home/data/mock_home_data.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/notification_preview_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _onBottomNavTapped(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
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
        currentIndex: 2,
        onTap: (index) => _onBottomNavTapped(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              NotificationPreviewCard(
                notifications: MockHomeData.notifications,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
