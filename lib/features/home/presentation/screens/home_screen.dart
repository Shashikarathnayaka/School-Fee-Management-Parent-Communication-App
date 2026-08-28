import 'package:flutter/material.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/services/auth_service.dart';
import '../../../driver/presentation/screens/driver_home_view.dart';
import '../views/parent_home_view.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final role = authService.currentUser?.role;

    if (role == UserRole.driver) {
      return DriverHomeView(authService: authService);
    }
    return ParentHomeView(authService: authService);
  }
}
