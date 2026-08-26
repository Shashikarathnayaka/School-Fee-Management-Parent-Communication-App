import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/school_pay_logo.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({
    super.key,
    required this.authService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.reqEmailOrPhone;
    }
    final trimmed = value.trim();
    // Validate if email OR 10-digit mobile number
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[0-9]{10}$');

    if (!emailRegex.hasMatch(trimmed) && !phoneRegex.hasMatch(trimmed)) {
      return AppStrings.invalidEmailOrPhone;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.reqPassword;
    }
    if (value.length < 6) {
      return AppStrings.minPasswordLen;
    }
    return null;
  }

  Future<void> _handleLogin() async {
    // Unfocus active keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await widget.authService.login(
      emailOrPhone: _emailOrPhoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.mockLoginSuccess),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.invalidCredentials),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.forgotPasswordNotice),
        backgroundColor: AppColors.primaryNavy,
      ),
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
                  const SizedBox(height: 24),
                  // Header Branding
                  const Center(
                    child: SchoolPayLogo(
                      size: 72,
                      showText: false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.welcomeBack,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.signInSubtitle,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Input Fields
                  AuthTextField(
                    controller: _emailOrPhoneController,
                    label: AppStrings.emailOrPhoneLabel,
                    hintText: AppStrings.emailOrPhoneHint,
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmailOrPhone,
                  ),
                  const SizedBox(height: 20),

                  AuthTextField(
                    controller: _passwordController,
                    label: AppStrings.passwordLabel,
                    hintText: AppStrings.passwordHint,
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _onForgotPassword,
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary Sign In Button
                  AuthButton(
                    text: AppStrings.signInButton,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Demo Account Hint Card (Development Only)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          AppStrings.demoAccountHintHeader,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppStrings.demoAccountHintBody,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Redirection Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.dontHaveAccount,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.register),
                        child: const Text(
                          AppStrings.registerNow,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
