import '../../../../core/models/fee.dart';
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

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  factory PaymentRecord.fromFee(Fee fee) {
    final String title;
    if (fee.description != null && fee.description!.trim().isNotEmpty) {
      title = fee.description!;
    } else if (fee.studentName != null && fee.studentName!.trim().isNotEmpty) {
      title = fee.studentName!;
    } else {
      title = 'School Van Fee';
    }

    final String date = fee.dueDate != null
        ? '${fee.dueDate!.day.toString().padLeft(2, '0')} ${_monthName(fee.dueDate!.month)} ${fee.dueDate!.year}'
        : '';

    final String amount = 'Rs. ${fee.amount.toStringAsFixed(2)}';

    final FeeStatus status;
    switch (fee.status.trim().toUpperCase()) {
      case 'PAID':
        status = FeeStatus.paid;
        break;
      case 'DUE':
      case 'PENDING':
        status = FeeStatus.due;
        break;
      case 'OVERDUE':
        status = FeeStatus.overdue;
        break;
      default:
        status = FeeStatus.due;
    }

    return PaymentRecord(
      id: fee.id,
      title: title,
      date: date,
      amount: amount,
      status: status,
      hasReceipt: status == FeeStatus.paid,
      studentId: fee.studentId,
      studentName: fee.studentName ?? '',
    );
  }
}
