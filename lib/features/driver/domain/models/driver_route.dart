class DriverRoute {
  final String id;
  final String routeName;
  final String pathDescription;
  final String startTime;
  final String endTime;
  final int studentCount;
  final String status;

  const DriverRoute({
    required this.id,
    required this.routeName,
    required this.pathDescription,
    required this.startTime,
    required this.endTime,
    required this.studentCount,
    required this.status,
  });
}
