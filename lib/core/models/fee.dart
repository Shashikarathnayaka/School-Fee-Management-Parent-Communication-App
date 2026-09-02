class Fee {
  final String id;
  final String studentId;
  final String? studentName;
  final double amount;
  final String status; // "PENDING", "PAID"
  final DateTime? dueDate;
  final String? description;

  Fee({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.amount,
    required this.status,
    this.dueDate,
    this.description,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] ?? json['_id'] ?? '',
      studentId: json['studentId'] ?? json['student_id'] ?? '',
      studentName: json['studentName'] ?? json['student_name'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      dueDate: json['dueDate'] != null || json['due_date'] != null
          ? DateTime.tryParse(json['dueDate'] ?? json['due_date'])
          : null,
      description: json['description'],
    );
  }
}
