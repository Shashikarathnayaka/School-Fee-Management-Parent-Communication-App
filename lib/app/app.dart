import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/services/active_role_notifier.dart';
import '../core/services/auth_service.dart';
import '../core/services/parent_api_service.dart';
import '../core/services/student_list_notifier.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SmartSchoolPayApp extends StatefulWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final StudentListNotifier studentListNotifier;
  final ParentApiService parentApiService;

  const SmartSchoolPayApp({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    required this.studentListNotifier,
    required this.parentApiService,
  });

  @override
  State<SmartSchoolPayApp> createState() => _SmartSchoolPayAppState();
}

class _SmartSchoolPayAppState extends State<SmartSchoolPayApp> {
  late final _router = AppRouter.createRouter(
    widget.authService,
    widget.activeRoleNotifier,
    widget.studentListNotifier,
    widget.parentApiService,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
