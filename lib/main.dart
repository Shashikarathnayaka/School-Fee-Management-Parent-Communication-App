import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all core services and dependencies
  await ServiceLocator.instance.init();
  
  runApp(SmartSchoolPayApp(
    authService: ServiceLocator.instance.authService,
  ));
}
