import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/driver_route.dart';
import '../../../../core/models/fee.dart';
import '../../../../core/models/student.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../home/domain/models/fee_summary.dart';
import '../../../home/domain/models/payment_record.dart';
import '../../../home/presentation/widgets/app_bottom_nav_bar.dart';
import '../../domain/models/pickup_record.dart';

class DriverStudentsScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final DriverApiService? driverApiService;

  const DriverStudentsScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.driverApiService,
  });

  @override
  State<DriverStudentsScreen> createState() => _DriverStudentsScreenState();
}

class _DriverStudentsScreenState extends State<DriverStudentsScreen> {
  late final DriverApiService _driverApiService = widget.driverApiService ??
      ServiceLocator.instance.driverApiService;

  List<DriverRoute> _routes = [];
  String? _selectedRouteId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutesAndStudents();
  }

  Future<void> _loadRoutesAndStudents({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final routes = await _driverApiService.getTodayRoutes();
      if (!mounted) return;

      setState(() {
        _routes = routes;
        _isLoading = false;
        _errorMessage = null;
        if (_selectedRouteId != null &&
            !_routes.any((r) => r.id == _selectedRouteId)) {
          _selectedRouteId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't load assigned students. Please try again.";
      });
    }
  }

  List<Student> get _displayedStudents {
    if (_routes.isEmpty) return [];

    if (_selectedRouteId != null) {
      final selectedRoute = _routes.firstWhere(
        (r) => r.id == _selectedRouteId,
        orElse: () => _routes.first,
      );
      return selectedRoute.students ?? [];
    }

    // Otherwise, collect all students across today's routes
    final allStudents = <Student>[];
    final seenIds = <String>{};

    for (final route in _routes) {
      if (route.students != null) {
        for (final student in route.students!) {
          if (seenIds.add(student.id)) {
            allStudents.add(student);
          }
        }
      }
    }
    return allStudents;
  }

  PickupStatus _mapPickupStatus(String? status) {
    if (status == null) return PickupStatus.pending;
    switch (status.toUpperCase()) {
      case 'PICKED_UP':
        return PickupStatus.pickedUp;
      case 'ABSENT':
        return PickupStatus.absent;
      case 'CANCELLED':
        return PickupStatus.cancelled;
      default:
        return PickupStatus.pending;
    }
  }

  Future<void> _navigateToRegisterStudent() async {
    final result = await context.push<bool>(
      AppRoutes.driverRegisterStudent,
      extra: {
        'routeId': _selectedRouteId ?? (_routes.isNotEmpty ? _routes.first.id : null),
        'routes': _routes,
      },
    );

    if (result == true || mounted) {
      _loadRoutesAndStudents(isRefresh: true);
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

  void _showPaymentStatus(BuildContext context, Student student) {
    Future<List<Fee>> feesFuture = _driverApiService.getStudentFees(student.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryBlueLight,
                            child: Text(
                              student.initials,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                Text(
                                  student.displayGrade,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Fee Payment Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<Fee>>(
                        future: feesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryBlue,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Failed to load fee payments. Please try again.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        feesFuture = _driverApiService
                                            .getStudentFees(student.id);
                                      });
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final fees = snapshot.data ?? [];
                          final payments =
                              fees.map(PaymentRecord.fromFee).toList();

                          if (payments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                'No payment record found for this student.',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            );
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: payments
                                .map((p) => _buildPaymentRow(p))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentRow(PaymentRecord p) {
    final isPaid = p.status == FeeStatus.paid;
    final color = isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final label = isPaid ? 'Paid' : 'Not Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.title} • ${p.date}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
                Text(
                  p.amount,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFilter() {
    if (_routes.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surfaceWhite,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All Routes'),
              selected: _selectedRouteId == null,
              selectedColor: AppColors.primaryBlueLight,
              labelStyle: TextStyle(
                color: _selectedRouteId == null
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedRouteId = null;
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            ..._routes.map((route) {
              final isSelected = _selectedRouteId == route.id;
              final count = route.students?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('${route.name} ($count)'),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBlueLight,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedRouteId = selected ? route.id : null;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_errorMessage != null && _routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadRoutesAndStudents(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final students = _displayedStudents;

    if (students.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 42,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Students Assigned',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Register students using their student code and monthly transport fee to assign them to your route.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToRegisterStudent,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Register Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        final pickupStatus = _mapPickupStatus(student.pickupStatus);

        return GestureDetector(
          onTap: () => _showPaymentStatus(context, student),
          child: Container(
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
                    student.initials,
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
                        student.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.displayGrade} • ${student.pickupLocation ?? 'Pickup Stop'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      pickupStatus.icon,
                      color: pickupStatus.color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pickupStatus.label,
                      style: TextStyle(
                        color: pickupStatus.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRole = widget.activeRoleNotifier.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'Assigned Students',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_rounded,
              color: AppColors.surfaceWhite,
            ),
            tooltip: 'Register Student',
            onPressed: _navigateToRegisterStudent,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        userRole: activeRole,
        onTap: (index) => _onBottomNavTapped(context, index),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRegisterStudent,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(
          Icons.person_add_rounded,
          color: AppColors.surfaceWhite,
        ),
        label: const Text(
          'Register Student',
          style: TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildRouteFilter(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: () => _loadRoutesAndStudents(isRefresh: true),
                child: _buildBody(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
