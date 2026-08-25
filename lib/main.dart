import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = MockAuthService();
  runApp(SmartSchoolPayApp(authService: authService));
}
