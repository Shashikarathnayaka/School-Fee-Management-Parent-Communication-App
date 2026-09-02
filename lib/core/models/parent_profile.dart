class ParentProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  ParentProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }
}
