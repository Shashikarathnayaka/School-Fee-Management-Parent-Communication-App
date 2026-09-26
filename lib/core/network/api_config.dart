class ApiConfig {
  // Active API Base URL: Defaults to production Vercel backend URL.
  // Can be overridden at build/run time via: --dart-define=API_BASE_URL=http://10.0.2.2:3000
  //
  // Alternative dev URLs for reference:
  // - Android Emulator: http://10.0.2.2:3000
  // - iOS Simulator / Local PC: http://localhost:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://school-fee-management-tau.vercel.app',
  );

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String registerParent = '$baseUrl/auth/register/parent';
  static const String registerDriver = '$baseUrl/auth/register/driver';

  // Parent Endpoints
  static const String parentProfile = '$baseUrl/parent/profile';
  static const String parentBecomeDriver = '$baseUrl/parent/become-driver';
  static const String parentStudents = '$baseUrl/parent/students';
  static const String parentFees = '$baseUrl/parent/fees';
  static const String parentNotifications = '$baseUrl/parent/notifications';

  // Driver Endpoints
  static const String driverProfile = '$baseUrl/driver/profile';
  static const String driverStatus = '$baseUrl/driver/status';
  static const String driverRoutes = '$baseUrl/driver/routes';
  static const String driverRoutesToday = '$baseUrl/driver/routes/today';
  static const String driverPickup = '$baseUrl/driver/pickup';
  static const String driverHistory = '$baseUrl/driver/history';
  static const String driverNotifications = '$baseUrl/driver/notifications';
  static const String driverStudents = '$baseUrl/driver/students';
}
