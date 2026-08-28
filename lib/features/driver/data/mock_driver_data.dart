import '../domain/models/driver_route.dart';
import '../domain/models/driver_summary.dart';
import '../domain/models/pickup_record.dart';

abstract class MockDriverData {
  static const String driverName = 'Kamal Silva';

  static const DriverRoute currentRoute = DriverRoute(
    id: 'route_01',
    routeName: 'Morning School Route',
    pathDescription: 'School → Student Pickup → School',
    startTime: '07:00 AM',
    endTime: '08:30 AM',
    studentCount: 12,
    status: 'Scheduled',
  );

  static const List<PickupRecord> pickups = [
    PickupRecord(
      id: 'pickup_01',
      time: '07:15 AM',
      studentName: 'Alex Johnson',
      grade: 'Grade 08',
      pickupPoint: 'Main Road',
      status: PickupStatus.pending,
    ),
    PickupRecord(
      id: 'pickup_02',
      time: '07:30 AM',
      studentName: 'Emma Perera',
      grade: 'Grade 06',
      pickupPoint: 'Lake Road',
      status: PickupStatus.pickedUp,
    ),
    PickupRecord(
      id: 'pickup_03',
      time: '07:45 AM',
      studentName: 'Nimali Fernando',
      grade: 'Grade 07',
      pickupPoint: 'Station Road',
      status: PickupStatus.absent,
    ),
    PickupRecord(
      id: 'pickup_04',
      time: '08:00 AM',
      studentName: 'Kasun Jayasinghe',
      grade: 'Grade 09',
      pickupPoint: 'City Center',
      status: PickupStatus.pending,
    ),
  ];

  static const DriverSummary todaySummary = DriverSummary(
    totalTrips: 2,
    totalStudents: 24,
    completedPickups: 18,
    pendingPickups: 6,
  );

  static const List<String> announcements = [
    'Morning route starts at 7:00 AM.',
    'Vehicle inspection reminder scheduled for this Friday.',
  ];
}
