import 'driver_route.dart';
import 'student.dart';

class StudentLookupRoute {
  final String id;
  final String name;
  final RouteDirection direction;

  StudentLookupRoute({
    required this.id,
    required this.name,
    required this.direction,
  });

  factory StudentLookupRoute.fromJson(Map<String, dynamic> json) {
    return StudentLookupRoute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      direction: RouteDirection.fromString(
        json['direction']?.toString() ?? json['route_direction']?.toString(),
      ),
    );
  }
}

class StudentCodeLookupResult {
  final Student student;
  final double? existingMonthlyFee;
  final StudentLookupRoute? existingRoute;

  StudentCodeLookupResult({
    required this.student,
    this.existingMonthlyFee,
    this.existingRoute,
  });

  factory StudentCodeLookupResult.fromJson(Map<String, dynamic> json) {
    double? parseFee(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return num.tryParse(val.toString())?.toDouble();
    }

    final studentMap = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};

    final routeMap = json['existing_route'] is Map
        ? Map<String, dynamic>.from(json['existing_route'] as Map)
        : null;

    return StudentCodeLookupResult(
      student: Student.fromJson(studentMap),
      existingMonthlyFee: parseFee(json['existing_monthly_fee']),
      existingRoute: routeMap != null ? StudentLookupRoute.fromJson(routeMap) : null,
    );
  }
}
