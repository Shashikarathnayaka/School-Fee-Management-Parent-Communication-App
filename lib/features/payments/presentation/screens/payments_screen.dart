import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../home/domain/models/payment_record.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/recent_payments_card.dart';

class PaymentsScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final ParentApiService? parentApiService;

  const PaymentsScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.parentApiService,
  });

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late final ParentApiService _apiService =
      widget.parentApiService ?? ParentApiService();

  List<PaymentRecord> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.activeRoleNotifier.value != UserRole.driver) {
      _loadPayments();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadPayments({bool isRefresh = false}) async {
    if (widget.activeRoleNotifier.value == UserRole.driver) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _payments = [];
        _errorMessage = null;
      });
      return;
    }

    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final fees = await _apiService.getFees();
      if (!mounted) return;

      setState(() {
        _payments = fees.map(PaymentRecord.fromFee).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load payment records. Please try again.';
      });
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
          'Payment History',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        userRole: activeRole,
        onTap: (index) => _onBottomNavTapped(context, index, isDriver),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () => _loadPayments(isRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'View all past fee payments and receipts.',
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
                          onPressed: () => _loadPayments(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  RecentPaymentsCard(payments: _payments),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
