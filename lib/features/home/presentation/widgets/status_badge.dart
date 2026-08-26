import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/fee_summary.dart';

class StatusBadge extends StatelessWidget {
  final FeeStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case FeeStatus.paid:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case FeeStatus.due:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = const Color(0xFFD97706); // Accessible Amber/Orange
        icon = Icons.schedule_rounded;
        break;
      case FeeStatus.overdue:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        icon = Icons.error_outline_rounded;
        break;
      case FeeStatus.pending:
        bg = AppColors.primaryBlueLight;
        fg = AppColors.primaryBlue;
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
