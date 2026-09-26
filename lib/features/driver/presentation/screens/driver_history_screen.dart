import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../domain/models/pickup_record.dart';

class DriverHistoryScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final DriverApiService? driverApiService;

  const DriverHistoryScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.driverApiService,
  });

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  late final DriverApiService _driverApiService = widget.driverApiService ??
      ServiceLocator.instance.driverApiService;

  List<PickupRecord> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final records = await _driverApiService.getHistory();
      if (!mounted) return;

      setState(() {
        _history = records;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load pickup history. Please try again.';
      });
    }
  }

  void _onBottomNavTapped(BuildContext context, int index) {
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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildHistoryCard(PickupRecord record) {
    final subtitleParts = <String>[];
    if (record.grade.isNotEmpty) subtitleParts.add(record.grade);
    if (record.pickupPoint.isNotEmpty) subtitleParts.add(record.pickupPoint);
    final subtitle =
        subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : 'Pickup Stop';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlueLight,
            child: Text(
              _getInitials(record.studentName),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    record.status.icon,
                    color: record.status.color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.status.label,
                    style: TextStyle(
                      color: record.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (record.time.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
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
              onPressed: () => _loadHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'No pickup history yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = _history[index];
        return _buildHistoryCard(record);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = widget.activeRoleNotifier.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'Pickup History',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        userRole: activeRole,
        onTap: (index) => _onBottomNavTapped(context, index),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () => _loadHistory(isRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip & Pickup History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review previous student pickups and trip records.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
