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

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String get displayGrade {
    final g = grade ?? '';
    final s = section ?? '';
    if (g.isEmpty) return 'N/A';
    if (g.startsWith('Grade')) {
      return s.isNotEmpty ? '$g - $s' : g;
    }
    return s.isNotEmpty ? 'Grade $g - $s' : 'Grade $g';
  }

  String get displaySchoolName => schoolName ?? 'N&D School';
}
