class Student {
  final String id;
  final String name;
  final String grade;
  final String schoolName;
  final String? avatarUrl;
  final String initials;

  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.schoolName,
    this.avatarUrl,
    required this.initials,
  });
}
