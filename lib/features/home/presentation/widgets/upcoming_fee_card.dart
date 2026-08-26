import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/fee_summary.dart';

class UpcomingFeeCard extends StatelessWidget {
  final FeeSummary upcomingFee;

  const UpcomingFeeCard({
    super.key,
    required this.upcomingFee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upcomingFee.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  upcomingFee.dueDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            upcomingFee.amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}
