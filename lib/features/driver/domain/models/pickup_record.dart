import 'package:flutter/material.dart';

enum PickupStatus {
  pending,
  pickedUp,
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

  const PickupRecord({
    required this.id,
    required this.time,
    required this.studentName,
    required this.grade,
    required this.pickupPoint,
    required this.status,
  });
}
