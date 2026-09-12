import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'active_role_notifier.dart';
import 'api_auth_service.dart';
import 'auth_service.dart';
import 'driver_api_service.dart';
import 'parent_api_service.dart';
import 'student_list_notifier.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late SharedPreferences prefs;
  late ApiClient apiClient;
  late AuthService authService;
  late ParentApiService parentApiService;
  late DriverApiService driverApiService;
  late ActiveRoleNotifier activeRoleNotifier;
  late StudentListNotifier studentListNotifier;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    apiClient = ApiClient(prefs);
    parentApiService = ParentApiService(apiClient);
    driverApiService = DriverApiService(apiClient);
    activeRoleNotifier = ActiveRoleNotifier();
    studentListNotifier = StudentListNotifier(parentApiService);
    authService = ApiAuthService(
      apiClient,
      studentListNotifier: studentListNotifier,
    );
  }

  static ServiceLocator get instance => _instance;
}
