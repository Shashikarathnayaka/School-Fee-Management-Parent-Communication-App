import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/driver_route.dart';
import '../../../../core/models/fee.dart';
import '../../../../core/models/student.dart';
import '../../../../core/network/api_client.dart';
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
  bool _isSendingReminders = false;
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

  Future<void> _confirmAndSendFeeReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Send Fee Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        content: const Text(
          "Send this month's fee reminder to all parents with unpaid fees?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSendingReminders = true);
    try {
      final now = DateTime.now();
      final result = await _driverApiService.sendFeeReminders(
        month: now.month,
        year: now.year,
      );
      if (!mounted) return;

      final sentCount = result.sent;
      final skippedCount = result.skipped;
      String msg =
          'Reminder sent to $sentCount parent${sentCount == 1 ? '' : 's'}';
      if (skippedCount > 0) {
        msg += ' ($skippedCount skipped)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReminders = false);
      }
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
      case 'DROPPED':
        return PickupStatus.dropped;
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
    // Mutable local state for the modal — held outside StatefulBuilder so
    // the FutureBuilder and the pay-action share the same references.
    Future<List<Fee>> feesFuture = _driverApiService.getStudentFees(student.id);
    // Fees list is extracted from the FutureBuilder result so we can update
    // individual rows in-place without re-fetching.
    List<Fee>? fees;
    // Tracks which feeIds have an in-flight PATCH request.
    final Set<String> loadingFeeIds = {};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            // ----------------------------------------------------------------
            // Confirmation + API call for marking a fee as paid.
            // ----------------------------------------------------------------
            Future<void> confirmAndPayFee(Fee fee) async {
              final confirmed = await showDialog<bool>(
                context: modalContext,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Confirm Cash Collection',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  content: const Text(
                    'Mark this fee as paid? This confirms cash was collected '
                    'from the parent.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.surfaceWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Mark as Paid'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              // Show per-row loading indicator.
              setModalState(() => loadingFeeIds.add(fee.id));

              try {
                final updated = await _driverApiService.payStudentFee(
                  student.id,
                  fee.id,
                );

                if (!mounted) return;

                // Update the fee in-place in our local list.
                setModalState(() {
                  loadingFeeIds.remove(fee.id);
                  if (updated != null && fees != null) {
                    final idx = fees!.indexWhere((f) => f.id == fee.id);
                    if (idx != -1) fees![idx] = updated;
                  }
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Marked as paid'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                setModalState(() => loadingFeeIds.remove(fee.id));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to mark as paid: ${formatErrorMessage(e)}',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.error,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: AppColors.surfaceWhite,
                        onPressed: () => confirmAndPayFee(fee),
                      ),
                    ),
                  );
                }
              }
            }

            // ----------------------------------------------------------------
            // Modal UI
            // ----------------------------------------------------------------
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
                                        fees = null;
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

                          // Seed the mutable list on first load only.
                          fees ??= List<Fee>.from(snapshot.data ?? []);

                          if (fees!.isEmpty) {
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
                            children: fees!
                                .map(
                                  (fee) => _buildPaymentRow(
                                    PaymentRecord.fromFee(fee),
                                    isLoading:
                                        loadingFeeIds.contains(fee.id),
                                    onMarkPaid: fee.status
                                                .trim()
                                                .toUpperCase() ==
                                            'PAID'
                                        ? null
                                        : () => confirmAndPayFee(fee),
                                  ),
                                )
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

  Widget _buildPaymentRow(
    PaymentRecord p, {
    bool isLoading = false,
    VoidCallback? onMarkPaid,
  }) {
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
          // --- Status label / Mark as Paid button ---
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            )
          else if (onMarkPaid != null)
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primaryBlue,
              ),
              onPressed: onMarkPaid,
              child: const Text(
                'Mark as Paid',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else
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

  Widget _buildFeeReminderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 20,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fee Reminders',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                Text(
                  'Remind parents with unpaid fees',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isSendingReminders)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: _confirmAndSendFeeReminders,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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
          if (_isSendingReminders)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.surfaceWhite,
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              key: const Key('send_fee_reminders_btn'),
              icon: const Icon(
                Icons.notification_add_rounded,
                color: AppColors.surfaceWhite,
              ),
              tooltip: 'Send fee reminders',
              onPressed: _confirmAndSendFeeReminders,
            ),
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
            _buildFeeReminderCard(),
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
