import '../domain/models/fee_summary.dart';
import '../domain/models/notification_item.dart';
import '../domain/models/payment_record.dart';
import '../domain/models/student.dart';

abstract class MockHomeData {
  static const String parentName = 'Shashi';

  static final List<Student> students = [
    const Student(
      id: 'st_01',
      name: 'Alex Johnson',
      grade: 'Grade 08 - A',
      schoolName: 'N&D International School',
      initials: 'AJ',
    ),
    const Student(
      id: 'st_02',
      name: 'Sarah Johnson',
      grade: 'Grade 05 - B',
      schoolName: 'N&D International School',
      initials: 'SJ',
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
    ),
    const PaymentRecord(
      id: 'pay_02',
      title: 'School Fee',
      date: '28 Jul 2026',
      amount: 'Rs. 15,000',
      status: FeeStatus.paid,
      hasReceipt: true,
    ),
  ];

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
