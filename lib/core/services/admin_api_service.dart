import '../models/pickup_review_item.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';

class AdminApiService {
  final ApiClient _apiClient;

  AdminApiService(this._apiClient);

  /// Fetches all routes managed in the system.
  /// Calls GET /admin/routes
  Future<List<dynamic>> getRoutes() async {
    final response = await _apiClient.get(ApiConfig.adminRoutes);
    if (response is List) {
      return response;
    }
    if (response != null && response['routes'] is List) {
      return response['routes'] as List<dynamic>;
    }
    return [];
  }

  /// GET /admin/pickups?date=YYYY-MM-DD[&route_id=UUID]
  ///
  /// [date]    ISO date string, e.g. '2026-10-01'. Defaults to today when null.
  /// [routeId] Optional UUID to filter by route.
  ///
  /// Returns a list of [PickupReviewItem] from the `pickups` envelope key.
  Future<List<PickupReviewItem>> getPickupsReview({
    String? date,
    String? routeId,
  }) async {
    final params = <String, String>{};
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (routeId != null && routeId.isNotEmpty) params['route_id'] = routeId;

    final url = params.isEmpty
        ? ApiConfig.adminPickups
        : Uri.parse(ApiConfig.adminPickups)
            .replace(queryParameters: params)
            .toString();

    final response = await _apiClient.get(url);
    if (response != null && response['pickups'] is List) {
      return (response['pickups'] as List)
          .map((e) => PickupReviewItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    return [];
  }

  /// PATCH /admin/pickups/:id/mark
  ///
  /// [id]     UUID of the PickupStatus record.
  /// [status] One of 'PICKED_UP', 'ABSENT', 'PENDING'.
  /// [force]  When true, allows backward status moves (e.g. PICKED_UP → PENDING).
  ///
  /// Returns the updated [PickupReviewItem] from the `pickup` envelope key.
  Future<PickupReviewItem> markPickup({
    required String id,
    required String status,
    bool force = false,
  }) async {
    final url = '${ApiConfig.adminPickupsMark}/$id/mark';
    final response = await _apiClient.patch(
      url,
      body: {
        'status': status,
        'force': force,
      },
    );
    if (response != null && response['pickup'] != null) {
      return PickupReviewItem.fromJson(
        Map<String, dynamic>.from(response['pickup'] as Map),
      );
    }
    throw Exception('Unexpected response from mark pickup endpoint.');
  }
}

