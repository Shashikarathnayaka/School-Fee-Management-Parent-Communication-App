enum FeeStatus {
  paid,
  due,
  overdue,
  pending;

  String get label {
    switch (this) {
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.due:
        return 'Payment Due';
      case FeeStatus.overdue:
        return 'Overdue';
      case FeeStatus.pending:
        return 'Pending';
    }
  }
}

class FeeSummary {
  final String id;
  final String title;
  final FeeStatus status;
  final String amount;
  final String dueDate;
  final String currency;
  final int tripsCount;
  final int tripsTotal;
  final double? perTrip;

  const FeeSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.amount,
    required this.dueDate,
    this.currency = 'Rs.',
    this.tripsCount = 0,
    this.tripsTotal = 40,
    this.perTrip,
  });
}
