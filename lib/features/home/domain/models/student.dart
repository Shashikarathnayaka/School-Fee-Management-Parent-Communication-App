class Student {
  final String id;
  final String name;
  final String grade;
  final String schoolName;
  final String? avatarUrl;
  final String initials;
  final String? studentCode;
  final String? pickupLocation;

  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.schoolName,
    this.avatarUrl,
    required this.initials,
    this.studentCode,
    this.pickupLocation,
  });

  /// Creates a Student from an API JSON response.
  factory Student.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    final grade = json['grade'] ?? '';
    final section = json['section'] ?? '';
    return Student(
      id: json['id'] ?? '',
      name: name,
      grade: grade.isNotEmpty
          ? (section.isNotEmpty ? 'Grade $grade - $section' : 'Grade $grade')
          : 'N/A',
      schoolName: json['school_name'] ?? json['schoolName'] ?? '',
      initials: name.isNotEmpty
          ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
          : '?',
      studentCode: json['student_code'] ?? json['studentCode'],
      pickupLocation: json['pickup_location'] ?? json['pickupLocation'],
    );
  }
}

