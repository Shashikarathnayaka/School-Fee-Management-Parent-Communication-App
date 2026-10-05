import 'student.dart';

enum RouteDirection {
  homeToSchool('HOME_TO_SCHOOL', 'Home -> School', 'Morning'),
  schoolToHome('SCHOOL_TO_HOME', 'School -> Home', 'Evening');

  final String value;
  final String label;
  final String shortLabel;

  const RouteDirection(this.value, this.label, this.shortLabel);

  static RouteDirection fromString(String? val) {
    if (val == null) return RouteDirection.homeToSchool;
    final upper = val.toUpperCase().trim();
    if (upper == 'SCHOOL_TO_HOME' || upper == 'EVENING') {
      return RouteDirection.schoolToHome;
    }
    return RouteDirection.homeToSchool;
  }
}

class DriverRoute {
  final String id;
  final String name;
  final String? startTime;
  final String? endTime;
  final String? status;
  final List<Student>? students;
  final RouteDirection direction;

  DriverRoute({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.status,
    this.students,
    this.direction = RouteDirection.homeToSchool,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    List<Student>? parsedStudents;
    final rawStudents = json['students'];
    if (rawStudents is List) {
      parsedStudents = [];
      for (final item in rawStudents) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          if (itemMap['student'] is Map) {
            final studentMap = Map<String, dynamic>.from(itemMap['student'] as Map);
            if ((studentMap['pickup_status'] == null ||
                    (studentMap['pickup_status'] is List &&
                        (studentMap['pickup_status'] as List).isEmpty)) &&
                itemMap['pickup_status'] != null) {
              studentMap['pickup_status'] = itemMap['pickup_status'];
            }
            parsedStudents.add(Student.fromJson(studentMap));
          } else {
            parsedStudents.add(Student.fromJson(itemMap));
          }
        }
      }
    }

    return DriverRoute(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? json['startTime']?.toString(),
      endTime: json['end_time']?.toString() ?? json['endTime']?.toString(),
      status: json['status']?.toString(),
      students: parsedStudents,
      direction: RouteDirection.fromString(
        json['direction']?.toString() ?? json['route_direction']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      'direction': direction.value,
      if (students != null) 'students': students!.map((s) => s.toJson()).toList(),
    };
  }
}
