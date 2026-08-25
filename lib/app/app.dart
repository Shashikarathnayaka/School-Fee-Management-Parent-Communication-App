import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SmartSchoolPayApp extends StatefulWidget {
  final AuthService authService;

  const SmartSchoolPayApp({
    super.key,
    required this.authService,
  });

  @override
  State<SmartSchoolPayApp> createState() => _SmartSchoolPayAppState();
}

class _SmartSchoolPayAppState extends State<SmartSchoolPayApp> {
  late final _router = AppRouter.createRouter(widget.authService);

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
