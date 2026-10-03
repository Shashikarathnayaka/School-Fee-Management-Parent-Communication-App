import 'package:flutter_test/flutter_test.dart';
import 'package:nd_smart_schoolpay/core/models/pickup_review_item.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // PickupReviewItem.fromJson
  // ────────────────────────────────────────────────────────────────────────────

  group('PickupReviewItem.fromJson', () {
    final fullJson = {
      'id': 'abc-123',
      'date': '2026-10-01T00:00:00.000Z',
      'status': 'PICKED_UP',
      'pickup_method': 'MANUAL',
      'updated_at': '2026-10-01T08:30:00.000Z',
      'student': {
        'id': 'stu-1',
        'name': 'Alice Smith',
        'student_code': 'S001',
        'grade': '5',
        'section': 'A',
        'school_name': 'Springfield School',
      },
      'route': {
        'id': 'rte-1',
        'name': 'Morning Route A',
        'driver': {
          'user': {
            'id': 'drv-1',
            'name': 'Bob Driver',
          },
        },
      },
    };

    test('parses all top-level fields correctly', () {
      final item = PickupReviewItem.fromJson(fullJson);

      expect(item.id, equals('abc-123'));
      expect(item.status, equals('PICKED_UP'));
      expect(item.pickupMethod, equals('MANUAL'));
      expect(item.date.year, equals(2026));
      expect(item.date.month, equals(10));
      expect(item.updatedAt, isNotNull);
    });

    test('parses student fields correctly', () {
      final item = PickupReviewItem.fromJson(fullJson);

      expect(item.studentId, equals('stu-1'));
      expect(item.studentName, equals('Alice Smith'));
      expect(item.studentCode, equals('S001'));
      expect(item.grade, equals('5'));
      expect(item.section, equals('A'));
      expect(item.schoolName, equals('Springfield School'));
    });

    test('parses route fields correctly', () {
      final item = PickupReviewItem.fromJson(fullJson);

      expect(item.routeId, equals('rte-1'));
      expect(item.routeName, equals('Morning Route A'));
    });

    test('parses nested driver name correctly', () {
      final item = PickupReviewItem.fromJson(fullJson);

      expect(item.driverName, equals('Bob Driver'));
    });

    test('handles missing optional fields gracefully', () {
      final minimalJson = {
        'id': 'xyz-999',
        'date': '2026-09-30T00:00:00.000Z',
        'status': 'PENDING',
        'student': {
          'id': 'stu-2',
          'name': 'Bob Jones',
          'student_code': 'S002',
        },
        'route': {
          'id': 'rte-2',
          'name': 'Evening Route',
        },
      };

      final item = PickupReviewItem.fromJson(minimalJson);

      expect(item.id, equals('xyz-999'));
      expect(item.status, equals('PENDING'));
      expect(item.pickupMethod, isNull);
      expect(item.updatedAt, isNull);
      expect(item.grade, isNull);
      expect(item.section, isNull);
      expect(item.schoolName, isNull);
      expect(item.driverName, isNull); // no driver nested
    });

    test('handles completely missing student and route keys', () {
      final emptyJson = <String, dynamic>{
        'id': 'fallback-id',
        'status': 'ABSENT',
      };

      final item = PickupReviewItem.fromJson(emptyJson);

      expect(item.id, equals('fallback-id'));
      expect(item.status, equals('ABSENT'));
      expect(item.studentName, equals('Unknown'));
      expect(item.studentId, equals(''));
      expect(item.routeId, isNull);
      expect(item.driverName, isNull);
    });

    test('handles missing driver inside route', () {
      final noDriverJson = {
        'id': 'nd-1',
        'date': '2026-10-01T00:00:00.000Z',
        'status': 'PENDING',
        'student': {'id': 's1', 'name': 'Jane', 'student_code': 'J001'},
        'route': {'id': 'r1', 'name': 'Route X'},
      };

      final item = PickupReviewItem.fromJson(noDriverJson);

      expect(item.routeName, equals('Route X'));
      expect(item.driverName, isNull);
    });

    test('handles malformed date strings without throwing', () {
      final badDateJson = {
        'id': 'bd-1',
        'date': 'not-a-date',
        'status': 'PENDING',
        'student': {'id': 's1', 'name': 'Jane', 'student_code': 'J001'},
        'route': <String, dynamic>{},
      };

      expect(() => PickupReviewItem.fromJson(badDateJson), returnsNormally);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Status mapping (chip values)
  // ────────────────────────────────────────────────────────────────────────────

  group('PickupReviewItem status mapping', () {
    // These expectations validate the raw status strings stored in the model
    // match what the backend emits.
    const validStatuses = ['PENDING', 'PICKED_UP', 'ABSENT'];

    test('fromJson stores status exactly as received from backend', () {
      for (final s in validStatuses) {
        final item = PickupReviewItem.fromJson({
          'id': 'id-$s',
          'status': s,
          'student': {'id': 'x', 'name': 'X', 'student_code': 'X1'},
          'route': <String, dynamic>{},
        });
        expect(item.status, equals(s),
            reason: 'status "$s" should be stored verbatim');
      }
    });

    test('missing status defaults to PENDING', () {
      final item = PickupReviewItem.fromJson({
        'id': 'no-status',
        'student': {'id': 'x', 'name': 'X', 'student_code': 'X1'},
        'route': <String, dynamic>{},
      });
      expect(item.status, equals('PENDING'));
    });

    test('pickup_method values are stored verbatim', () {
      for (final method in ['MANUAL', 'TICKET', 'DRIVER']) {
        final item = PickupReviewItem.fromJson({
          'id': 'pm-$method',
          'status': 'PICKED_UP',
          'pickup_method': method,
          'student': {'id': 'x', 'name': 'X', 'student_code': 'X1'},
          'route': <String, dynamic>{},
        });
        expect(item.pickupMethod, equals(method));
      }
    });
  });
}
