import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'api_auth_service.dart';
import 'auth_service.dart';
import 'driver_api_service.dart';
import 'parent_api_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late SharedPreferences prefs;
  late ApiClient apiClient;
  late AuthService authService;
  late ParentApiService parentApiService;
  late DriverApiService driverApiService;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    apiClient = ApiClient(prefs);
    authService = ApiAuthService(apiClient);
    parentApiService = ParentApiService(apiClient);
    driverApiService = DriverApiService(apiClient);
  }

  static ServiceLocator get instance => _instance;
}
