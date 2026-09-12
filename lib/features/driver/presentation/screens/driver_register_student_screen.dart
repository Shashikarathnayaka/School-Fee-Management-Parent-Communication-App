import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/driver_route.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';

class DriverRegisterStudentScreen extends StatefulWidget {
  final AuthService authService;
  final DriverApiService? driverApiService;
  final String? initialRouteId;
  final List<DriverRoute>? initialRoutes;

  const DriverRegisterStudentScreen({
    super.key,
    required this.authService,
    this.driverApiService,
    this.initialRouteId,
    this.initialRoutes,
  });

  @override
  State<DriverRegisterStudentScreen> createState() =>
      _DriverRegisterStudentScreenState();
}

class _DriverRegisterStudentScreenState
    extends State<DriverRegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _studentCodeController = TextEditingController();
  final _monthlyFeeController = TextEditingController();

  late final DriverApiService _apiService = widget.driverApiService ??
      (ServiceLocator.instance.driverApiService);

  List<DriverRoute> _routes = [];
  String? _selectedRouteId;
  bool _isLoadingRoutes = false;
  bool _isSubmitting = false;

  /// Filters routes to those that can have students registered onto them.
  /// Any route that is not COMPLETED (e.g. SCHEDULED, ACTIVE, or unspecified) is valid.
  static List<DriverRoute> filterSelectableRoutes(List<DriverRoute> routes) {
    return routes.where((r) {
      final status = r.status?.toUpperCase();
      return status != 'COMPLETED';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialRoutes != null && widget.initialRoutes!.isNotEmpty) {
      _routes = filterSelectableRoutes(widget.initialRoutes!);
      _initSelectedRoute();
    } else {
      _fetchRoutes();
    }
  }

  void _initSelectedRoute() {
    if (_routes.isEmpty) {
      _selectedRouteId = null;
      return;
    }
    if (widget.initialRouteId != null &&
        _routes.any((r) => r.id == widget.initialRouteId)) {
      _selectedRouteId = widget.initialRouteId;
    } else {
      _selectedRouteId = _routes.first.id;
    }
  }

  Future<void> _fetchRoutes() async {
    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      final routes = await _apiService.getTodayRoutes();
      if (!mounted) return;
      setState(() {
        _routes = filterSelectableRoutes(routes);
        _initSelectedRoute();
        _isLoadingRoutes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRoutes = false;
      });
    }
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  String? _validateStudentCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.reqStudentCode;
    }
    return null;
  }

  String? _validateMonthlyFee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.reqMonthlyFee;
    }
    final fee = double.tryParse(value.trim());
    if (fee == null || fee <= 0) {
      return AppStrings.invalidMonthlyFee;
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (_selectedRouteId == null || _selectedRouteId!.isEmpty) {
      _showErrorSnackBar(AppStrings.noDriverRoutesError);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final studentCode = _studentCodeController.text.trim();
    final monthlyFee = double.parse(_monthlyFeeController.text.trim());

    try {
      await _apiService.addStudentToRoute(
        _selectedRouteId!,
        studentCode,
        monthlyFee,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      final assignedRouteName = _routes
          .firstWhere(
            (r) => r.id == _selectedRouteId,
            orElse: () => DriverRoute(id: _selectedRouteId!, name: 'Current Route'),
          )
          .name;

      _showSuccessDialog(
        studentCode: studentCode,
        monthlyFee: monthlyFee,
        routeName: assignedRouteName,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      final String message;
      if (e.code == 'NOT_FOUND' || e.statusCode == 404) {
        message = AppStrings.studentNotFound;
      } else if (e.code == 'CONFLICT' || e.statusCode == 409) {
        message = AppStrings.studentConflict;
      } else if (e.message.isNotEmpty && e.message != 'Something went wrong') {
        message = e.message;
      } else {
        message = AppStrings.registerStudentGenericError;
      }
      _showErrorSnackBar(message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      _showErrorSnackBar(AppStrings.registerStudentGenericError);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog({
    required String studentCode,
    required double monthlyFee,
    required String routeName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryBlue,
              size: 36,
            ),
          ),
          title: const Text(
            AppStrings.registerStudentSuccessTitle,
            style: TextStyle(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Student successfully assigned to $routeName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Student Code:',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            studentCode,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Transport Fee:',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Rs. ${monthlyFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.canPop()) {
                  context.pop(true);
                } else {
                  context.go(AppRoutes.driverStudents);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.surfaceWhite,
                minimumSize: const Size(120, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRouteSelector() {
    if (_isLoadingRoutes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_routes.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.noDriverRoutesError,
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_routes.length == 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryBlueLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.alt_route_rounded,
              color: AppColors.primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Route',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _routes.first.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Multiple routes available: Dropdown
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.selectRouteLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRouteId,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.alt_route_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
          ),
          items: _routes.map((route) {
            return DropdownMenuItem<String>(
              value: route.id,
              child: Text(
                route.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRouteId = value;
            });
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.primaryNavy,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.driverStudents);
                        }
                      },
                      tooltip: 'Back to Students',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Screen Header
                  Text(
                    AppStrings.registerStudentTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.registerStudentSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Route Selection / Info
                  _buildRouteSelector(),

                  // Student Code (Required)
                  AuthTextField(
                    controller: _studentCodeController,
                    label: AppStrings.studentCodeLabel,
                    hintText: AppStrings.studentCodeHint,
                    prefixIcon: Icons.qr_code_rounded,
                    textInputAction: TextInputAction.next,
                    validator: _validateStudentCode,
                  ),
                  const SizedBox(height: 18),

                  // Monthly Transport Fee (Required)
                  AuthTextField(
                    controller: _monthlyFeeController,
                    label: AppStrings.monthlyFeeLabel,
                    hintText: AppStrings.monthlyFeeHint,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    validator: _validateMonthlyFee,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  AuthButton(
                    text: AppStrings.registerStudentButton,
                    isLoading: _isSubmitting,
                    onPressed: _routes.isEmpty && !_isLoadingRoutes
                        ? null
                        : _handleSubmit,
                    icon: Icons.person_add_rounded,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
