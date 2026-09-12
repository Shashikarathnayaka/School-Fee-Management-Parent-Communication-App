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
    String? parsedPickupStatus;
    final rawStatus = json['pickup_status'];
    if (rawStatus is String) {
      parsedPickupStatus = rawStatus;
    } else if (rawStatus is List && rawStatus.isNotEmpty) {
      final first = rawStatus.first;
      if (first is Map && first['status'] != null) {
        parsedPickupStatus = first['status'].toString();
      } else if (first is String) {
        parsedPickupStatus = first;
      }
    } else if (rawStatus is Map && rawStatus['status'] != null) {
      parsedPickupStatus = rawStatus['status'].toString();
    }

    return Student(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      studentCode: json['student_code']?.toString(),
      grade: json['grade']?.toString(),
      section: json['section']?.toString(),
      schoolName: json['school_name']?.toString(),
      pickupLocation: json['pickup_location']?.toString(),
      pickupStatus: parsedPickupStatus,
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
