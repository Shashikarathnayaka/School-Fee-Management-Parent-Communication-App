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
    final driver = (json['driver'] is Map)
        ? Map<String, dynamic>.from(json['driver'])
        : const <String, dynamic>{};

    final rawIsOnDuty = json['is_on_duty'] ??
        json['isOnDuty'] ??
        driver['is_on_duty'] ??
        driver['isOnDuty'];

    final bool parsedIsOnDuty;
    if (rawIsOnDuty is bool) {
      parsedIsOnDuty = rawIsOnDuty;
    } else if (rawIsOnDuty is num) {
      parsedIsOnDuty = rawIsOnDuty == 1;
    } else if (rawIsOnDuty is String) {
      parsedIsOnDuty = rawIsOnDuty.toLowerCase() == 'true';
    } else {
      parsedIsOnDuty = false;
    }

    return DriverProfile(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      vanNumber: json['van_number'] ??
          json['vanNumber'] ??
          driver['van_number'] ??
          driver['vanNumber'],
      licenseNo: json['license_no'] ??
          json['licenseNo'] ??
          driver['license_no'] ??
          driver['licenseNo'],
      isOnDuty: parsedIsOnDuty,
    );
  }
}
