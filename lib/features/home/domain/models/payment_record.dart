import 'fee_summary.dart';

class PaymentRecord {
  final String id;
  final String title;
  final String date;
  final String amount;
  final FeeStatus status;
  final bool hasReceipt;

  const PaymentRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    this.hasReceipt = true,
  });
}
