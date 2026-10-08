class Fee {
  final String id;
  final String studentId;
  final String? studentName;
  final double amount;
  final String status; // "PENDING", "PAID"
  final DateTime? dueDate;
  final String? description;
  final int tripsCount;
  final int tripsTotal;
  final double? perTripAmount;
  final int? month;
  final int? year;
  final int cycle;

  Fee({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.amount,
    required this.status,
    this.dueDate,
    this.description,
    this.tripsCount = 0,
    this.tripsTotal = 40,
    this.perTripAmount,
    this.month,
    this.year,
    this.cycle = 1,
  });

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return num.tryParse(value.toString())?.toDouble() ?? 0.0;
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return num.tryParse(value.toString())?.toDouble();
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentId: (json['studentId'] ?? json['student_id'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['student_name'])?.toString(),
      amount: _parseAmount(json['amount']),
      status: (json['status'] ?? 'PENDING').toString(),
      dueDate: json['dueDate'] != null || json['due_date'] != null
          ? DateTime.tryParse((json['dueDate'] ?? json['due_date']).toString())
          : null,
      description: json['description']?.toString(),
      tripsCount: _parseInt(
        json['trips_count'] ?? json['tripsCount'],
        defaultValue: 0,
      ),
      tripsTotal: _parseInt(
        json['trips_total'] ?? json['tripsTotal'],
        defaultValue: 40,
      ),
      perTripAmount: _parseNullableDouble(
        json['per_trip_amount'] ?? json['perTripAmount'],
      ),
      month: _parseNullableInt(json['month']),
      year: _parseNullableInt(json['year']),
      cycle: _parseInt(json['cycle'], defaultValue: 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      if (studentName != null) 'student_name': studentName,
      'amount': amount,
      'status': status,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (description != null) 'description': description,
      'trips_count': tripsCount,
      'trips_total': tripsTotal,
      if (perTripAmount != null) 'per_trip_amount': perTripAmount,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      'cycle': cycle,
    };
  }
}
