import '../../features/driver/domain/models/pickup_record.dart';
import '../models/driver_profile.dart';
import '../models/driver_route.dart';
import '../models/notification_model.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';

class DriverApiService {
  final ApiClient _apiClient;

  DriverApiService(this._apiClient);

  Future<DriverProfile?> getProfile() async {
    final response = await _apiClient.get(ApiConfig.driverProfile);
    if (response != null) {
      return DriverProfile.fromJson(response['profile']);
    }
    return null;
  }

  Future<DriverProfile?> updateProfile({
    String? name,
    String? phone,
    String? vanNumber,
    String? licenseNo,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (vanNumber != null) body['van_number'] = vanNumber;
    if (licenseNo != null) body['license_no'] = licenseNo;

    final response = await _apiClient.patch(ApiConfig.driverProfile, body: body);
    if (response != null) {
      return DriverProfile.fromJson(response['profile']);
    }
    return null;
  }

  Future<void> toggleDutyStatus(bool isOnDuty) async {
    await _apiClient.patch(ApiConfig.driverStatus, body: {'is_on_duty': isOnDuty});
  }

  Future<DriverRoute?> createRoute({
    required String name,
    String? startTime,
    String? endTime,
  }) async {
    final body = {
      'name': name,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
    };

    final response = await _apiClient.post(ApiConfig.driverRoutes, body: body);
    if (response != null) {
      return DriverRoute.fromJson(response['route']);
    }
    return null;
  }

  Future<List<DriverRoute>> getTodayRoutes() async {
    final response = await _apiClient.get(ApiConfig.driverRoutesToday);
    if (response != null && response['routes'] is List) {
      return (response['routes'] as List)
          .map((e) => DriverRoute.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> addStudentToRoute(
    String routeId,
    String studentCode,
    double monthlyFee,
  ) async {
    await _apiClient.post(
      '${ApiConfig.driverRoutes}/$routeId/students',
      body: {
        'student_code': studentCode,
        'monthly_fee': monthlyFee,
      },
    );
  }

  Future<void> removeStudentFromRoute(String routeId, String studentId) async {
    await _apiClient.delete('${ApiConfig.driverRoutes}/$routeId/students/$studentId');
  }

  Future<void> updatePickupStatus({
    required String studentId,
    required String status,
    required String routeId,
  }) async {
    await _apiClient.patch(
      '${ApiConfig.driverPickup}/$studentId',
      body: {
        'status': status, // "PICKED_UP", "ABSENT", "PENDING"
        'routeId': routeId,
      },
    );
  }

  // Convenience method to set a student as "get in the bus"
  Future<void> markStudentPickedUp({
    required String studentId,
    required String routeId,
  }) async {
    await updatePickupStatus(
      studentId: studentId,
      status: 'PICKED_UP',
      routeId: routeId,
    );
  }

  // Convenience method to set a student as absent
  Future<void> markStudentAbsent({
    required String studentId,
    required String routeId,
  }) async {
    await updatePickupStatus(
      studentId: studentId,
      status: 'ABSENT',
      routeId: routeId,
    );
  }

  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiClient.get(ApiConfig.driverNotifications);
    if (response != null && response['notifications'] is List) {
      return (response['notifications'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> readNotification(String id) async {
    await _apiClient.patch('${ApiConfig.driverNotifications}/$id/read');
  }

  Future<List<PickupRecord>> getHistory({String? date, String? routeId}) async {
    final queryParams = <String, String>{};
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (routeId != null && routeId.isNotEmpty) queryParams['routeId'] = routeId;

    final url = queryParams.isEmpty
        ? ApiConfig.driverHistory
        : Uri.parse(ApiConfig.driverHistory)
            .replace(queryParameters: queryParams)
            .toString();

    final response = await _apiClient.get(url);
    if (response != null && response['history'] is List) {
      return (response['history'] as List)
          .map((e) => PickupRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }
}
