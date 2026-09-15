import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/user_role.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class DriverUpgradeScreen extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;

  const DriverUpgradeScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
  });

  @override
  State<DriverUpgradeScreen> createState() => _DriverUpgradeScreenState();
}

class _DriverUpgradeScreenState extends State<DriverUpgradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vanNumberController = TextEditingController();
  final _licenseNoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _vanNumberController.dispose();
    _licenseNoController.dispose();
    super.dispose();
  }

  String? _validateVanNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.reqVanNumber;
    }
    return null;
  }

  String? _validateLicenseNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.reqLicenseNo;
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.authService.becomeDriver(
        vanNumber: _vanNumberController.text.trim(),
        licenseNo: _licenseNoController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Set active role to parent (they came from parent mode)
        widget.activeRoleNotifier.value = UserRole.parent;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.becomeDriverSuccess),
            backgroundColor: AppColors.primaryNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        context.go(AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.becomeDriverError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final errorMessage = formatErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
                      onPressed: () => context.go(AppRoutes.home),
                      tooltip: 'Back to Home',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Header Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.airport_shuttle_rounded,
                      size: 36,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Section
                  Text(
                    AppStrings.becomeDriverScreenTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.becomeDriverSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  AuthTextField(
                    controller: _vanNumberController,
                    label: AppStrings.vanNumberLabel,
                    hintText: AppStrings.vanNumberHint,
                    prefixIcon: Icons.airport_shuttle_outlined,
                    textInputAction: TextInputAction.next,
                    validator: _validateVanNumber,
                  ),
                  const SizedBox(height: 18),

                  AuthTextField(
                    controller: _licenseNoController,
                    label: AppStrings.licenseNoLabel,
                    hintText: AppStrings.licenseNoHint,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.done,
                    validator: _validateLicenseNo,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  AuthButton(
                    text: AppStrings.becomeDriverButton,
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                    icon: Icons.airport_shuttle_rounded,
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
