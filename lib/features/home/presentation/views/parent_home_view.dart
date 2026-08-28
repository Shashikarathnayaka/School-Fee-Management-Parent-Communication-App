import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/mock_home_data.dart';
import '../../domain/models/student.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/fee_summary_card.dart';
import '../widgets/notification_preview_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_payments_card.dart';
import '../widgets/section_header.dart';
import '../widgets/student_card.dart';
import '../widgets/upcoming_fee_card.dart';

class ParentHomeView extends StatefulWidget {
  final AuthService authService;

  const ParentHomeView({
    super.key,
    required this.authService,
  });

  @override
  State<ParentHomeView> createState() => _ParentHomeViewState();
}

class _ParentHomeViewState extends State<ParentHomeView> {
  late Student _selectedStudent;

  @override
  void initState() {
    super.initState();
    _selectedStudent = MockHomeData.students.first;
  }

  void _showPlaceholderNotice(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
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
    final theme = Theme.of(context);
    final parentName = widget.authService.currentUser?.name ?? MockHomeData.parentName;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
          child: CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            radius: 16,
            child: Text(
              parentName.substring(0, 1).toUpperCase(),
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
        userRole: UserRole.parent,
        onTap: _onBottomNavTapped,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                '${AppStrings.greetingPrefix}$parentName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.homeSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Student Card
              StudentCard(
                student: _selectedStudent,
                allStudents: MockHomeData.students,
                onStudentChanged: (student) {
                  setState(() {
                    _selectedStudent = student;
                  });
                },
                onViewDetails: () {
                  _showPlaceholderNotice('Student profile details coming soon');
                },
              ),
              const SizedBox(height: 20),

              // Fee Summary Card
              FeeSummaryCard(
                feeSummary: MockHomeData.currentFee,
                onPayNow: () {
                  _showPlaceholderNotice(AppStrings.paymentModulePlaceholder);
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                AppStrings.quickActionsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              QuickActionsGrid(
                items: [
                  QuickActionItem(
                    label: 'Pay Fees',
                    icon: Icons.payment_rounded,
                    onTap: () =>
                        _showPlaceholderNotice(AppStrings.paymentModulePlaceholder),
                  ),
                  QuickActionItem(
                    label: 'Payment History',
                    icon: Icons.history_rounded,
                    onTap: () => context.go(AppRoutes.payments),
                  ),
                  QuickActionItem(
                    label: 'Receipts',
                    icon: Icons.receipt_long_rounded,
                    onTap: () => context.go(AppRoutes.receipts),
                  ),
                  QuickActionItem(
                    label: 'Notifications',
                    icon: Icons.notifications_rounded,
                    onTap: () => context.go(AppRoutes.notifications),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Payments
              SectionHeader(
                title: AppStrings.recentPaymentsTitle,
                onViewAll: () => context.go(AppRoutes.payments),
              ),
              const SizedBox(height: 12),
              RecentPaymentsCard(
                payments: MockHomeData.recentPayments,
              ),
              const SizedBox(height: 24),

              // Upcoming Fee
              Text(
                AppStrings.upcomingFeeTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              UpcomingFeeCard(
                upcomingFee: MockHomeData.upcomingFee,
              ),
              const SizedBox(height: 24),

              // Latest Updates
              SectionHeader(
                title: AppStrings.latestUpdatesTitle,
                onViewAll: () => context.go(AppRoutes.notifications),
              ),
              const SizedBox(height: 12),
              NotificationPreviewCard(
                notifications: MockHomeData.notifications,
                onItemTap: () => context.go(AppRoutes.notifications),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
