import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/services/student_list_notifier.dart';
import '../../data/mock_home_data.dart';
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
  final ParentApiService? parentApiService;
  final StudentListNotifier? studentListNotifier;

  const ParentHomeView({
    super.key,
    required this.authService,
    this.parentApiService,
    this.studentListNotifier,
  });

  @override
  State<ParentHomeView> createState() => _ParentHomeViewState();
}

class _ParentHomeViewState extends State<ParentHomeView> {
  late StudentListNotifier _studentListNotifier;
  Student? _selectedStudent;

  /// Session-level flag to avoid showing the become-driver popup repeatedly.
  /// Resets on app restart (static so it persists across widget rebuilds).
  static bool _becomeDriverDismissed = false;

  @override
  void initState() {
    super.initState();
    _initNotifier();
    _studentListNotifier.addListener(_onStudentListChanged);
    _syncSelectedStudent();
    _studentListNotifier.fetchStudents();

    // Show become-driver popup after the first frame if the parent
    // hasn't already registered as a driver and hasn't dismissed it this session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowBecomeDriverDialog();
    });
  }

  void _initNotifier() {
    if (widget.studentListNotifier != null) {
      _studentListNotifier = widget.studentListNotifier!;
    } else {
      _studentListNotifier = StudentListNotifier(
        widget.parentApiService ?? ParentApiService(),
      );
    }
  }

  @override
  void didUpdateWidget(ParentHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentListNotifier != widget.studentListNotifier ||
        oldWidget.parentApiService != widget.parentApiService) {
      _studentListNotifier.removeListener(_onStudentListChanged);
      _initNotifier();
      _studentListNotifier.addListener(_onStudentListChanged);
      _onStudentListChanged();
    }
  }

  @override
  void dispose() {
    _studentListNotifier.removeListener(_onStudentListChanged);
    super.dispose();
  }

  void _onStudentListChanged() {
    if (!mounted) return;
    setState(() {
      _syncSelectedStudent();
    });
  }

  void _syncSelectedStudent() {
    final students = _studentListNotifier.students;
    if (students.isNotEmpty) {
      if (_selectedStudent == null ||
          !students.any((s) => s.id == _selectedStudent!.id)) {
        _selectedStudent = students.first;
      }
    } else {
      _selectedStudent = null;
    }
  }

  void _maybeShowBecomeDriverDialog() {
    if (_becomeDriverDismissed) return;

    // TODO: Replace MockHomeData.parentProfile with the real fetched profile
    // once GET /parent/profile returns has_driver_profile from the backend.
    final profile = MockHomeData.parentProfile;
    if (profile.hasDriverProfile) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.airport_shuttle_rounded,
              color: AppColors.accentTeal,
              size: 32,
            ),
          ),
          title: const Text(
            AppStrings.becomeDriverDialogTitle,
            style: TextStyle(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            AppStrings.becomeDriverDialogContent,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                _becomeDriverDismissed = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                AppStrings.becomeDriverNotNow,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _becomeDriverDismissed = true;
                Navigator.of(dialogContext).pop();
                context.go(AppRoutes.becomeDriver);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                AppStrings.becomeDriverUpdate,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
    final parentName =
        widget.authService.currentUser?.name ?? MockHomeData.parentName;

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

              // Student Card Section
              if (_studentListNotifier.isLoading)
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                )
              else if (_studentListNotifier.hasFetchError ||
                  (_studentListNotifier.students.isNotEmpty &&
                      _selectedStudent != null))
                StudentCard(
                  student: _selectedStudent!,
                  allStudents: _studentListNotifier.students,
                  onStudentChanged: (student) {
                    setState(() {
                      _selectedStudent = student;
                    });
                  },
                  onViewDetails: () {
                    _showPlaceholderNotice(
                      'Student profile details coming soon',
                    );
                  },
                )
              else
                // Empty State: zero students successfully loaded (not an error state)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlueLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          size: 32,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.noStudentsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No students added yet — add one from your Profile',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
                    onTap: () => _showPlaceholderNotice(
                      AppStrings.paymentModulePlaceholder,
                    ),
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
              RecentPaymentsCard(payments: MockHomeData.recentPayments),
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
              UpcomingFeeCard(upcomingFee: MockHomeData.upcomingFee),
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
