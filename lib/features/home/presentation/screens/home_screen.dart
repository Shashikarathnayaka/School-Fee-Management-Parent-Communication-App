import 'package:flutter/material.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/services/active_role_notifier.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/driver_api_service.dart';
import '../../../../core/services/parent_api_service.dart';
import '../../../../core/services/student_list_notifier.dart';
import '../../../driver/presentation/screens/driver_home_view.dart';
import '../views/parent_home_view.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;
  final ActiveRoleNotifier activeRoleNotifier;
  final ParentApiService? parentApiService;
  final DriverApiService? driverApiService;
  final StudentListNotifier? studentListNotifier;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.activeRoleNotifier,
    this.parentApiService,
    this.driverApiService,
    this.studentListNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // Use activeRoleNotifier to decide which view to show,
    // so dual-role users see the correct mode.
    final activeRole = activeRoleNotifier.value;

    if (activeRole == UserRole.driver) {
      return DriverHomeView(
        authService: authService,
        driverApiService: driverApiService,
      );
    }
    return ParentHomeView(
      authService: authService,
      parentApiService: parentApiService,
      studentListNotifier: studentListNotifier,
    );
  }
}
