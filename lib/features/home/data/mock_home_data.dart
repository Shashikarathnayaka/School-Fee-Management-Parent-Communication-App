import '../../../core/models/parent_profile.dart';
import '../../../core/models/student.dart';
import '../domain/models/fee_summary.dart';
import '../domain/models/notification_item.dart';
import '../domain/models/payment_record.dart';

abstract class MockHomeData {
  static const String parentName = 'Shashi';

  /// Mock parent profile — hasDriverProfile defaults to false
  /// so the become-driver popup shows for parent-only users.
  static final ParentProfile parentProfile = ParentProfile(
    id: 'usr_parent_01',
    name: parentName,
    email: 'parent@test.com',
    phone: '0712345678',
    hasDriverProfile: false,
  );

  static final List<Student> students = [
    Student(
      id: 'st_01',
      name: 'Kaveesha Rathnayaka',
      grade: '08',
      section: 'A',
      schoolName: 'N&D International School',
      studentCode: 'STU-KAV01',
    ),
    Student(
      id: 'st_02',
      name: 'Shashika Rathnayaka',
      grade: '05',
      section: 'B',
      schoolName: 'N&D International School',
      studentCode: 'STU-SHA02',
    ),
  ];

  static const FeeSummary currentFee = FeeSummary(
    id: 'fee_aug_2026',
    title: 'School Fee',
    status: FeeStatus.due,
    amount: 'Rs. 15,000',
    dueDate: 'Due 30 Aug 2026',
  );

  static const FeeSummary upcomingFee = FeeSummary(
    id: 'fee_sep_2026',
    title: 'School Fee',
    status: FeeStatus.pending,
    amount: 'Rs. 15,000',
    dueDate: 'Due 30 Sep 2026',
  );

  static final List<PaymentRecord> recentPayments = [
    const PaymentRecord(
      id: 'pay_01',
      title: 'School Fee',
      date: '28 Aug 2026',
      amount: 'Rs. 15,000',
      status: FeeStatus.paid,
      hasReceipt: true,
      parentId: 'usr_parent_01',
      studentId: 'st_01',
      driverId: '',
      studentName: 'Kaveesha Rathnayaka',
    ),
    const PaymentRecord(
      id: 'pay_02',
      title: 'School Fee',
      date: '28 Jul 2026',
      amount: 'Rs. 15,000',
      status: FeeStatus.paid,
      hasReceipt: true,
      parentId: 'usr_parent_01',
      studentId: 'st_02',
      driverId: '',
      studentName: 'Shashika Rathnayaka',
    ),
  ];

  // Fee payments made by parents of students on the driver's transport route.
  // Shown on the Driver dashboard — NOT the driver's own payments.
  static const String _routeDriverId = 'usr_driver_01';

  static final List<PaymentRecord> routeStudentPayments = [
    const PaymentRecord(
      id: 'rpay_01',
      title: 'School Fee',
      date: '25 Aug 2026',
      amount: 'Rs. 15,000',
      status: FeeStatus.paid,
      hasReceipt: true,
      parentId: 'parent_of_alex',
      studentId: 'pickup_01',
      driverId: _routeDriverId,
      studentName: 'Alex Johnson',
    ),
    const PaymentRecord(
      id: 'rpay_02',
      title: 'School Fee',
      date: '20 Aug 2026',
      amount: 'Rs. 12,000',
      status: FeeStatus.paid,
      hasReceipt: true,
      parentId: 'parent_of_emma',
      studentId: 'pickup_02',
      driverId: _routeDriverId,
      studentName: 'Emma Perera',
    ),
    const PaymentRecord(
      id: 'rpay_03',
      title: 'School Fee',
      date: '30 Aug 2026',
      amount: 'Rs. 14,500',
      status: FeeStatus.due,
      hasReceipt: false,
      parentId: 'parent_of_nimali',
      studentId: 'pickup_03',
      driverId: _routeDriverId,
      studentName: 'Nimali Fernando',
    ),
    const PaymentRecord(
      id: 'rpay_04',
      title: 'School Fee',
      date: '30 Aug 2026',
      amount: 'Rs. 13,000',
      status: FeeStatus.pending,
      hasReceipt: false,
      parentId: 'parent_of_kasun',
      studentId: 'pickup_04',
      driverId: _routeDriverId,
      studentName: 'Kasun Jayasinghe',
    ),
  ];

  // Filters route payments for a given driver id.
  static List<PaymentRecord> paymentsForDriver(String driverId) {
    return routeStudentPayments.where((p) => p.driverId == driverId).toList();
  }

  static final List<NotificationItem> notifications = [
    const NotificationItem(
      id: 'notif_01',
      title: 'Fee Due Reminder',
      message: 'School fee payment is due soon.',
      time: '2 hours ago',
      isRead: false,
    ),
    const NotificationItem(
      id: 'notif_02',
      title: 'Receipt Issued',
      message: 'Payment receipt for August is available.',
      time: '1 day ago',
      isRead: true,
    ),
  ];
}
