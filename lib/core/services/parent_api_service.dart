import '../models/fee.dart';
import '../models/notification_model.dart';
import '../models/parent_profile.dart';
import '../models/student.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';

class ParentApiService {
  final ApiClient? _apiClient;

  ParentApiService([this._apiClient]);

  Future<ParentProfile?> getProfile() async {
    final response = await _apiClient?.get(ApiConfig.parentProfile);
    if (response != null) {
      return ParentProfile.fromJson(response['profile']);
    }
    return null;
  }

  Future<ParentProfile?> updateProfile({String? name, String? phone}) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;

    final response =
        await _apiClient?.patch(ApiConfig.parentProfile, body: body);
    if (response != null) {
      return ParentProfile.fromJson(response['profile']);
    }
    return null;
  }

  Future<List<Student>> getStudents() async {
    final response = await _apiClient?.get(ApiConfig.parentStudents);
    if (response != null && response['students'] is List) {
      return (response['students'] as List)
          .map((e) => Student.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<Student?> addStudent({
    required String name,
    String? grade,
    String? section,
    String? schoolName,
    String? pickupLocation,
  }) async {
    final body = {
      'name': name,
      if (grade != null) 'grade': grade,
      if (section != null) 'section': section,
      if (schoolName != null) 'school_name': schoolName,
      if (pickupLocation != null) 'pickup_location': pickupLocation,
    };

    final response =
        await _apiClient?.post(ApiConfig.parentStudents, body: body);
    if (response != null) {
      return Student.fromJson(response['student']);
    }
    return null;
  }

  Future<Student?> getStudentDetails(String id) async {
    final response = await _apiClient?.get('${ApiConfig.parentStudents}/$id');
    if (response != null) {
      return Student.fromJson(response['student']);
    }
    return null;
  }

  Future<dynamic> getPickupStatus(String studentId, {String? date}) async {
    String url = '${ApiConfig.parentStudents}/$studentId/pickup-status';
    if (date != null) {
      url += '?date=$date';
    }
    final response = await _apiClient?.get(url);
    if (response != null) {
      return response['status'];
    }
    return null;
  }

  Future<List<Fee>> getFees() async {
    final response = await _apiClient?.get(ApiConfig.parentFees);
    if (response != null && response['fees'] is List) {
      return (response['fees'] as List).map((e) => Fee.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> payFee(String feeId) async {
    await _apiClient?.patch('${ApiConfig.parentFees}/$feeId/pay');
  }

  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiClient?.get(ApiConfig.parentNotifications);
    if (response != null && response['notifications'] is List) {
      return (response['notifications'] as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> readNotification(String id) async {
    await _apiClient?.patch('${ApiConfig.parentNotifications}/$id/read');
  }
}
