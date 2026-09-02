import 'student.dart';

class DriverRoute {
  final String id;
  final String name;
  final String? startTime;
  final String? endTime;
  final List<Student>? students;

  DriverRoute({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.students,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    return DriverRoute(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? json['startTime'],
      endTime: json['end_time'] ?? json['endTime'],
      students: json['students'] != null
          ? (json['students'] as List).map((i) => Student.fromJson(i)).toList()
          : null,
    );
  }
}
