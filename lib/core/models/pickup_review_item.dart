/// Model for a single record returned by GET /admin/pickups.
///
/// Response shape (from admin.js):
/// {
///   "id": "...",
///   "date": "2026-10-01T00:00:00.000Z",
///   "status": "PENDING" | "PICKED_UP" | "ABSENT",
///   "pickup_method": "MANUAL" | "TICKET" | "DRIVER" | null,
///   "updated_at": "2026-10-01T08:30:00.000Z",
///   "student": { "id": "...", "name": "...", "student_code": "...",
///                "grade": "5", "section": "A", "school_name": "..." },
///   "route": { "id": "...", "name": "...",
///              "driver": { "user": { "id": "...", "name": "..." } } }
/// }
class PickupReviewItem {
  final String id;
  final DateTime date;
  final String status; // 'PENDING' | 'PICKED_UP' | 'ABSENT'
  final String? pickupMethod;
  final DateTime? updatedAt;

  // student fields
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? grade;
  final String? section;
  final String? schoolName;

  // route fields
  final String? routeId;
  final String? routeName;

  // driver fields (nested: route.driver.user)
  final String? driverName;

  const PickupReviewItem({
    required this.id,
    required this.date,
    required this.status,
    this.pickupMethod,
    this.updatedAt,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.grade,
    this.section,
    this.schoolName,
    this.routeId,
    this.routeName,
    this.driverName,
  });

  factory PickupReviewItem.fromJson(Map<String, dynamic> json) {
    final student = (json['student'] as Map<String, dynamic>?) ?? {};
    final route = (json['route'] as Map<String, dynamic>?) ?? {};

    // Drill down: route.driver.user.name
    final driver = (route['driver'] as Map<String, dynamic>?) ?? {};
    final driverUser = (driver['user'] as Map<String, dynamic>?) ?? {};

    return PickupReviewItem(
      id: (json['id'] as String?) ?? '',
      date: DateTime.tryParse((json['date'] as String?) ?? '') ?? DateTime.now(),
      status: (json['status'] as String?) ?? 'PENDING',
      pickupMethod: json['pickup_method'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      studentId: (student['id'] as String?) ?? '',
      studentName: (student['name'] as String?) ?? 'Unknown',
      studentCode: (student['student_code'] as String?) ?? '',
      grade: student['grade'] as String?,
      section: student['section'] as String?,
      schoolName: student['school_name'] as String?,
      routeId: route['id'] as String?,
      routeName: route['name'] as String?,
      driverName: driverUser['name'] as String?,
    );
  }

  @override
  String toString() =>
      'PickupReviewItem(id: $id, student: $studentName, status: $status)';
}
