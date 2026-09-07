import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/student.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/services/student_list_notifier.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';

class AddStudentScreen extends StatefulWidget {
  final AuthService authService;
  final ParentApiService? parentApiService;
  final StudentListNotifier? studentListNotifier;

  const AddStudentScreen({
    super.key,
    required this.authService,
    this.parentApiService,
    this.studentListNotifier,
  });

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _sectionController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  bool _isLoading = false;

  // Never reach into ServiceLocator — use what was injected or create locally.
  late final ParentApiService _apiService =
      widget.parentApiService ?? ParentApiService();

  late final StudentListNotifier _studentListNotifier =
      widget.studentListNotifier ?? StudentListNotifier(_apiService);

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _sectionController.dispose();
    _schoolNameController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.reqStudentName;
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
      final student = await _apiService.addStudent(
        name: _nameController.text.trim(),
        grade: _gradeController.text.trim().isEmpty
            ? null
            : _gradeController.text.trim(),
        section: _sectionController.text.trim().isEmpty
            ? null
            : _sectionController.text.trim(),
        schoolName: _schoolNameController.text.trim().isEmpty
            ? null
            : _schoolNameController.text.trim(),
        pickupLocation: _pickupLocationController.text.trim().isEmpty
            ? null
            : _pickupLocationController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (student != null) {
        _studentListNotifier.onStudentAdded(student);
        _showSuccessDialog(student);
      } else {
        _showErrorSnackBar();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar();
    }
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.addStudentError),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(Student student) {
    final studentCode = student.studentCode ?? 'N/A';

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
            AppStrings.addStudentSuccessDialogTitle,
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
                  student.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Code Container
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STUDENT CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              studentCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: studentCode));
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: const Text(AppStrings.codeCopiedToast),
                              backgroundColor: AppColors.primaryNavy,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                        tooltip: AppStrings.copyCodeButton,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  AppStrings.addStudentCodeNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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
                try {
                  context.go(AppRoutes.home);
                } catch (_) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
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

                  // Screen Header
                  Text(
                    AppStrings.addStudentScreenTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.addStudentSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // Student Name (Required)
                  AuthTextField(
                    controller: _nameController,
                    label: AppStrings.studentNameLabel,
                    hintText: AppStrings.studentNameHint,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 18),

                  // Grade (Optional)
                  AuthTextField(
                    controller: _gradeController,
                    label: AppStrings.gradeLabel,
                    hintText: AppStrings.gradeHint,
                    prefixIcon: Icons.school_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),

                  // Section (Optional)
                  AuthTextField(
                    controller: _sectionController,
                    label: AppStrings.sectionLabel,
                    hintText: AppStrings.sectionHint,
                    prefixIcon: Icons.class_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),

                  // School Name (Optional)
                  AuthTextField(
                    controller: _schoolNameController,
                    label: AppStrings.schoolNameLabel,
                    hintText: AppStrings.schoolNameHint,
                    prefixIcon: Icons.apartment_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),

                  // Pickup Location (Optional)
                  AuthTextField(
                    controller: _pickupLocationController,
                    label: AppStrings.pickupLocationLabel,
                    hintText: AppStrings.pickupLocationHint,
                    prefixIcon: Icons.location_on_outlined,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  AuthButton(
                    text: AppStrings.addStudentButton,
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
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
