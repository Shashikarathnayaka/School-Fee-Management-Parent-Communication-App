class Student {
  final String id;
  final String name;
  final String? studentCode;
  final String? grade;
  final String? section;
  final String? schoolName;
  final String? pickupLocation;
  final String? pickupStatus; // "PICKED_UP", "ABSENT", "PENDING"

  Student({
    required this.id,
    required this.name,
    this.studentCode,
    this.grade,
    this.section,
    this.schoolName,
    this.pickupLocation,
    this.pickupStatus,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      studentCode: json['student_code'],
      grade: json['grade'],
      section: json['section'],
      schoolName: json['school_name'],
      pickupLocation: json['pickup_location'],
      pickupStatus: json['pickup_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'student_code': studentCode,
      'grade': grade,
      'section': section,
      'school_name': schoolName,
      'pickup_location': pickupLocation,
      'pickup_status': pickupStatus,
    };
  }
}
