class ApiConfig {
  // Use 10.0.2.2 for Android Emulator connecting to localhost
  // Use localhost or 127.0.0.1 for iOS Simulator
  // Use your computer's local IP address for physical devices
  static const String baseUrl = 'http://10.0.2.2:3000';

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
  static const String driverNotifications = '$baseUrl/driver/notifications';
}
