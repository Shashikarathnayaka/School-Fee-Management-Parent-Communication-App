import 'package:flutter/foundation.dart';
import '../../features/driver/domain/models/pickup_record.dart';
import '../models/driver_profile.dart';
import '../models/driver_route.dart';
import '../models/fee.dart';
import '../models/notification_model.dart';
import '../models/student_code_lookup_result.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';

export '../models/student_code_lookup_result.dart';

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

class StartRouteResult {
  final int notified;
  final int skipped;

  const StartRouteResult({this.notified = 0, this.skipped = 0});

  factory StartRouteResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return StartRouteResult(
      notified: parseInt(json['notified']),
      skipped: parseInt(json['skipped']),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'notified':
        return notified;
      case 'skipped':
        return skipped;
      default:
        return null;
    }
  }
}

class DriverApiService {
  final ApiClient _apiClient;

  /// Holds the current duty status so it outlives widget rebuilds and tab transitions.
  final ValueNotifier<bool> isOnDutyNotifier = ValueNotifier<bool>(false);

  /// Tracks whether the duty status has been loaded from the server or set at least once.
  bool hasLoadedDutyStatus = false;

  DriverApiService(this._apiClient);

  Future<DriverProfile?> getProfile() async {
    final response = await _apiClient.get(ApiConfig.driverProfile);
    if (response != null) {
      final profile = DriverProfile.fromJson(response['profile']);
      isOnDutyNotifier.value = profile.isOnDuty;
      hasLoadedDutyStatus = true;
      return profile;
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
    isOnDutyNotifier.value = isOnDuty;
    hasLoadedDutyStatus = true;
  }

  Future<DriverRoute?> createRoute({
    required String name,
    String? startTime,
    String? endTime,
    RouteDirection direction = RouteDirection.homeToSchool,
  }) async {
    final body = {
      'name': name,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'direction': direction.value,
    };

    final response = await _apiClient.post(ApiConfig.driverRoutes, body: body);
    if (response != null) {
      final routeData = response['route'] ?? response;
      if (routeData is Map) {
        return DriverRoute.fromJson(Map<String, dynamic>.from(routeData));
      }
    }
    return null;
  }

  Future<DriverRoute?> updateRoute({
    required String routeId,
    String? name,
    String? startTime,
    String? endTime,
    RouteDirection? direction,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (startTime != null) body['start_time'] = startTime;
    if (endTime != null) body['end_time'] = endTime;
    if (direction != null) body['direction'] = direction.value;

    final response = await _apiClient.patch(
      '${ApiConfig.driverRoutes}/$routeId',
      body: body,
    );
    if (response != null) {
      final routeData = response['route'] ?? response;
      if (routeData is Map) {
        return DriverRoute.fromJson(Map<String, dynamic>.from(routeData));
      }
    }
    return null;
  }

  Future<void> deleteRoute(String routeId) async {
    await _apiClient.delete('${ApiConfig.driverRoutes}/$routeId');
  }

  Future<void> archiveRoute(String routeId) async {
    await _apiClient.patch('${ApiConfig.driverRoutes}/$routeId/archive');
  }

  /// Starts a route, sending "Driver on the way" notifications to parents.
  /// Returns [StartRouteResult] with the number of parents notified and skipped.
  /// Throws [ApiException] on 409 NOT_ON_DUTY / INVALID_STATE or 404 NOT_FOUND.
  Future<StartRouteResult> startRoute(String routeId) async {
    final response = await _apiClient.post(
      ApiConfig.driverRouteStart(routeId),
    );
    if (response is Map) {
      return StartRouteResult.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    return const StartRouteResult();
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

  Future<StudentCodeLookupResult?> lookupStudentByCode(String code) async {
    final response = await _apiClient.get('${ApiConfig.driverStudentsByCode}/$code');
    if (response is Map) {
      return StudentCodeLookupResult.fromJson(Map<String, dynamic>.from(response));
    }
    return null;
  }

  Future<void> addStudentToRoute(
    String routeId,
    String studentCode, [
    double? monthlyFee,
  ]) async {
    final body = <String, dynamic>{
      'student_code': studentCode,
      if (monthlyFee != null) 'monthly_fee': monthlyFee,
    };
    await _apiClient.post(
      '${ApiConfig.driverRoutes}/$routeId/students',
      body: body,
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

  Future<void> deleteNotification(String id) async {
    await _apiClient.delete(ApiConfig.driverNotification(id));
  }

  Future<void> clearNotifications() async {
    await _apiClient.delete(ApiConfig.driverNotifications);
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
