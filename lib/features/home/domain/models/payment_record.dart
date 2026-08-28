import 'fee_summary.dart';

class PaymentRecord {
  final String id;
  final String title;
  final String date;
  final String amount;
  final FeeStatus status;
  final bool hasReceipt;
  final String parentId;
  final String studentId;
  final String driverId;
  final String studentName;

  const PaymentRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    this.hasReceipt = true,
    this.parentId = '',
    this.studentId = '',
    this.driverId = '',
    this.studentName = '',
  });
}
