class DriverProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? vanNumber;
  final String? licenseNo;
  final bool isOnDuty;

  DriverProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.vanNumber,
    this.licenseNo,
    required this.isOnDuty,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      vanNumber: json['van_number'] ?? json['vanNumber'],
      licenseNo: json['license_no'] ?? json['licenseNo'],
      isOnDuty: json['is_on_duty'] ?? json['isOnDuty'] ?? false,
    );
  }
}
