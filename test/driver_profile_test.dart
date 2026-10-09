import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/driver_profile.dart';

void main() {
  group('DriverProfile.fromJson', () {
    test('parses nested driver object correctly ({ "driver": { "is_on_duty": true } })', () {
      final json = {
        'id': 'drv_1',
        'name': 'Jane Driver',
        'email': 'driver@example.com',
        'phone': '0771234567',
        'driver': {
          'van_number': 'WP CA-1234',
          'license_no': 'B1234567',
          'is_on_duty': true,
        },
      };

      final profile = DriverProfile.fromJson(json);

      expect(profile.id, 'drv_1');
      expect(profile.name, 'Jane Driver');
      expect(profile.email, 'driver@example.com');
      expect(profile.phone, '0771234567');
      expect(profile.vanNumber, 'WP CA-1234');
      expect(profile.licenseNo, 'B1234567');
      expect(profile.isOnDuty, isTrue);
    });

    test('parses real backend GET /driver/profile response format with nested driver', () {
      final backendResponseProfile = {
        'id': 'drv_uuid_101',
        'name': 'Kamal Perera',
        'email': 'kamal@example.com',
        'phone': '0779998888',
        'created_at': '2026-03-01T10:00:00.000Z',
        'driver': {
          'van_number': 'NC GA-9988',
          'license_no': 'DL987654',
          'is_on_duty': true,
          'capacity': 14,
        },
      };

      final profile = DriverProfile.fromJson(backendResponseProfile);

      expect(profile.id, 'drv_uuid_101');
      expect(profile.name, 'Kamal Perera');
      expect(profile.vanNumber, 'NC GA-9988');
      expect(profile.licenseNo, 'DL987654');
      expect(profile.isOnDuty, isTrue);
    });

    test('parses old top-level format correctly', () {
      final json = {
        'id': 'drv_old',
        'name': 'Sunil Silva',
        'email': 'sunil@example.com',
        'phone': '0712223344',
        'van_number': 'WP CAD-4455',
        'license_no': 'B7654321',
        'is_on_duty': true,
      };

      final profile = DriverProfile.fromJson(json);

      expect(profile.id, 'drv_old');
      expect(profile.name, 'Sunil Silva');
      expect(profile.vanNumber, 'WP CAD-4455');
      expect(profile.licenseNo, 'B7654321');
      expect(profile.isOnDuty, isTrue);
    });

    test('parses top-level camelCase format correctly', () {
      final json = {
        'id': 'drv_camel',
        'name': 'Nimal Sir',
        'vanNumber': 'WP WP-1122',
        'licenseNo': 'L9988',
        'isOnDuty': true,
      };

      final profile = DriverProfile.fromJson(json);

      expect(profile.vanNumber, 'WP WP-1122');
      expect(profile.licenseNo, 'L9988');
      expect(profile.isOnDuty, isTrue);
    });

    test('top-level takes precedence over nested driver keys when both exist', () {
      final json = {
        'id': 'drv_override',
        'name': 'Override Driver',
        'van_number': 'TOP-LEVEL-VAN',
        'license_no': 'TOP-LEVEL-LIC',
        'is_on_duty': true,
        'driver': {
          'van_number': 'NESTED-VAN',
          'license_no': 'NESTED-LIC',
          'is_on_duty': false,
        },
      };

      final profile = DriverProfile.fromJson(json);

      expect(profile.vanNumber, 'TOP-LEVEL-VAN');
      expect(profile.licenseNo, 'TOP-LEVEL-LIC');
      expect(profile.isOnDuty, isTrue);
    });

    test('defaults isOnDuty to false when key is absent everywhere', () {
      final json = {
        'id': 'drv_default',
        'name': 'Default Driver',
        'driver': {
          'van_number': 'WP BB-5566',
        },
      };

      final profile = DriverProfile.fromJson(json);

      expect(profile.isOnDuty, isFalse);
      expect(profile.vanNumber, 'WP BB-5566');
    });

    test('nested driver with is_on_duty: false parses as false', () {
      final json = {
        'id': 'drv_off',
        'name': 'Offline Driver',
        'driver': {
          'is_on_duty': false,
        },
      };

      final profile = DriverProfile.fromJson(json);

      expect(profile.isOnDuty, isFalse);
    });
  });
}
