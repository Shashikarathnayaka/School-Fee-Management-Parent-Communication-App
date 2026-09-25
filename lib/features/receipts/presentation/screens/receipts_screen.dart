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

class ReceiptsScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final ParentApiService? parentApiService;

  const ReceiptsScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.parentApiService,
  });

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  late final ParentApiService _apiService =
      widget.parentApiService ?? ParentApiService();

  List<PaymentRecord> _receipts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.activeRoleNotifier.value != UserRole.driver) {
      _loadReceipts();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadReceipts({bool isRefresh = false}) async {
    if (widget.activeRoleNotifier.value == UserRole.driver) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _receipts = [];
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

      final paidFees = fees
          .where((fee) => fee.status.trim().toUpperCase() == 'PAID')
          .map(PaymentRecord.fromFee)
          .toList();

      setState(() {
        _receipts = paidFees;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load receipts. Please try again.';
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
          'Payment Receipts',
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
        child: isDriver
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Receipts are only available for parents.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () => _loadReceipts(isRefresh: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlueLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Payment Receipts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your paid fee receipts',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                onPressed: () => _loadReceipts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else
                        RecentPaymentsCard(
                          payments: _receipts,
                          emptyMessage: 'No receipts yet',
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
