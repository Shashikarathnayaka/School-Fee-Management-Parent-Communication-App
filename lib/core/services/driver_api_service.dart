import '../../features/driver/domain/models/pickup_record.dart';
import '../models/driver_profile.dart';
import '../models/driver_route.dart';
import '../models/fee.dart';
import '../models/notification_model.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';

class PickupCharge {
  final String? kind;
  final double amount;

  const PickupCharge({this.kind, required this.amount});

  factory PickupCharge.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return num.tryParse(val.toString())?.toDouble() ?? 0.0;
    }

    return PickupCharge(
      kind: json['kind']?.toString(),
      amount: parseAmount(json['amount']),
    );
  }
}

class PickupUpdateResult {
  final dynamic pickup;
  final Fee? fee;
  final PickupCharge? charge;

  const PickupUpdateResult({
    this.pickup,
    this.fee,
    this.charge,
  });

  factory PickupUpdateResult.fromJson(Map<String, dynamic> json) {
    return PickupUpdateResult(
      pickup: json['pickup'],
      fee: json['fee'] is Map
          ? Fee.fromJson(Map<String, dynamic>.from(json['fee'] as Map))
          : null,
      charge: json['charge'] is Map
          ? PickupCharge.fromJson(Map<String, dynamic>.from(json['charge'] as Map))
          : null,
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'pickup':
        return pickup;
      case 'fee':
        return fee;
      case 'charge':
        return charge;
      default:
        return null;
    }
  }
}

class FeeReminderResult {
  final int sent;
  final int skipped;

  const FeeReminderResult({this.sent = 0, this.skipped = 0});

  factory FeeReminderResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return FeeReminderResult(
      sent: parseInt(json['sent']),
      skipped: parseInt(json['skipped']),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'sent':
        return sent;
      case 'skipped':
        return skipped;
      default:
        return null;
    }
  }
}

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

  Future<PickupUpdateResult> updatePickupStatus({
    required String studentId,
    required String status,
    required String routeId,
  }) async {
    final response = await _apiClient.patch(
      '${ApiConfig.driverPickup}/$studentId',
      body: {
        'status': status, // "PICKED_UP", "DROPPED", "ABSENT", "PENDING"
        'routeId': routeId,
      },
    );
    if (response is Map) {
      return PickupUpdateResult.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return const PickupUpdateResult();
  }

  // Convenience method to set a student as "get in the bus"
  Future<PickupUpdateResult> markStudentPickedUp({
    required String studentId,
    required String routeId,
  }) async {
    return await updatePickupStatus(
      studentId: studentId,
      status: 'PICKED_UP',
      routeId: routeId,
    );
  }

  // Convenience method to mark a student as dropped off
  Future<PickupUpdateResult> markStudentDropped({
    required String studentId,
    required String routeId,
  }) async {
    return await updatePickupStatus(
      studentId: studentId,
      status: 'DROPPED',
      routeId: routeId,
    );
  }

  // Convenience method to set a student as absent
  Future<PickupUpdateResult> markStudentAbsent({
    required String studentId,
    required String routeId,
  }) async {
    return await updatePickupStatus(
      studentId: studentId,
      status: 'ABSENT',
      routeId: routeId,
    );
  }

  Future<FeeReminderResult> sendFeeReminders({
    int? month,
    int? year,
  }) async {
    final body = <String, dynamic>{};
    if (month != null) body['month'] = month;
    if (year != null) body['year'] = year;

    final response = await _apiClient.post(
      ApiConfig.driverFeesRemind,
      body: body.isNotEmpty ? body : null,
    );
    if (response is Map) {
      return FeeReminderResult.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return const FeeReminderResult();
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
    if (routeId != null && routeId.isNotEmpty) {
      queryParams['route_id'] = routeId;
    }

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

  Future<List<Fee>> getStudentFees(String studentId) async {
    final response = await _apiClient.get('${ApiConfig.driverStudents}/$studentId/fees');
    if (response != null && response['fees'] is List) {
      return (response['fees'] as List)
          .map((e) => Fee.fromJson(e))
          .toList();
    }
    return [];
  }

  /// Marks a specific fee as paid (cash collected by driver).
  /// Calls PATCH /driver/students/:studentId/fees/:feeId/pay
  /// Returns the updated [Fee] on success, rethrows on failure.
  Future<Fee?> payStudentFee(String studentId, String feeId) async {
    final response = await _apiClient.patch(
      '${ApiConfig.driverStudents}/$studentId/fees/$feeId/pay',
    );
    if (response != null && response['fee'] != null) {
      return Fee.fromJson(response['fee']);
    }
    return null;
  }
}
