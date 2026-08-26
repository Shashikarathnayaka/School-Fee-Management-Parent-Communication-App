import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/models/fee_summary.dart';
import 'status_badge.dart';

class FeeSummaryCard extends StatelessWidget {
  final FeeSummary feeSummary;
  final VoidCallback onPayNow;

  const FeeSummaryCard({
    super.key,
    required this.feeSummary,
    required this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryNavy,
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feeSummary.title,
                style: const TextStyle(
                  color: AppColors.surfaceWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StatusBadge(status: feeSummary.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                feeSummary.amount,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: AppColors.surfaceWhite,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                feeSummary.dueDate,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onPayNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.payment_rounded, size: 20),
              label: const Text(
                AppStrings.payNowButton,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
