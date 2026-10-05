import 'package:flutter/material.dart';

import '../../../../core/models/driver_route.dart';
import '../../../home/domain/models/notification_item.dart';

enum PickupStatus {
  pending,
  pickedUp,
  dropped,
  absent,
  cancelled,
}

extension PickupStatusX on PickupStatus {
  String get label {
    switch (this) {
      case PickupStatus.pending:
        return 'Pending';
      case PickupStatus.pickedUp:
        return 'Picked Up';
      case PickupStatus.dropped:
        return 'Dropped Off';
      case PickupStatus.absent:
        return 'Absent';
      case PickupStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData get icon {
    switch (this) {
      case PickupStatus.pending:
        return Icons.schedule_rounded;
      case PickupStatus.pickedUp:
        return Icons.check_circle_outline_rounded;
      case PickupStatus.dropped:
        return Icons.home_rounded;
      case PickupStatus.absent:
        return Icons.cancel_outlined;
      case PickupStatus.cancelled:
        return Icons.do_not_disturb_on_outlined;
    }
  }

  Color get color {
    switch (this) {
      case PickupStatus.pending:
        return const Color(0xFFF59E0B);
      case PickupStatus.pickedUp:
        return const Color(0xFF10B981);
      case PickupStatus.dropped:
        return const Color(0xFF2563EB);
      case PickupStatus.absent:
        return const Color(0xFFEF4444);
      case PickupStatus.cancelled:
        return const Color(0xFF64748B);
    }
  }
}

class PickupRecord {
  final String id;
  final String time;
  final String studentName;
  final String grade;
  final String pickupPoint;
  final PickupStatus status;
  final RouteDirection? direction;

  const PickupRecord({
    required this.id,
    required this.time,
    required this.studentName,
    required this.grade,
    required this.pickupPoint,
    required this.status,
    this.direction,
  });

  factory PickupRecord.fromJson(Map<String, dynamic> json) {
    String studentName = '';
    String grade = '';
    String pickupPoint = '';

    final student = json['student'];
    if (student is Map) {
      studentName = student['name'] ??
          student['student_name'] ??
          student['studentName'] ??
          '';
      grade = student['grade'] ?? '';
      pickupPoint = student['pickup_location'] ??
          student['pickupLocation'] ??
          '';
    } else {
      studentName = json['student_name'] ??
          json['studentName'] ??
          '';
      grade = json['grade'] ?? '';
      pickupPoint = json['pickup_location'] ??
          json['pickupLocation'] ??
          '';
    }

    PickupStatus status = PickupStatus.pending;
    final rawStatus = (json['status'] as String?)?.trim().toUpperCase();
    switch (rawStatus) {
      case 'PICKED_UP':
        status = PickupStatus.pickedUp;
        break;
      case 'DROPPED':
        status = PickupStatus.dropped;
        break;
      case 'ABSENT':
        status = PickupStatus.absent;
        break;
      case 'CANCELLED':
        status = PickupStatus.cancelled;
        break;
      case 'PENDING':
      default:
        status = PickupStatus.pending;
        break;
    }

    String time = '';
    final rawDate = json['date'] ??
        json['updated_at'] ??
        json['updatedAt'] ??
        json['created_at'] ??
        json['createdAt'];
    if (rawDate != null) {
      final dt = rawDate is DateTime
          ? rawDate
          : DateTime.tryParse(rawDate.toString());
      if (dt != null) {
        time = NotificationItem.formatTime(dt);
      } else {
        time = rawDate.toString();
      }
    }

    RouteDirection? direction;
    final rawDir = json['direction'] ??
        json['route_direction'] ??
        (json['route'] is Map ? json['route']['direction'] : null);
    if (rawDir != null) {
      direction = RouteDirection.fromString(rawDir.toString());
    }

    return PickupRecord(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      time: time,
      studentName: studentName.isNotEmpty ? studentName : 'Student',
      grade: grade,
      pickupPoint: pickupPoint,
      status: status,
      direction: direction,
    );
  }
}
