import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/fee_summary.dart';
import 'status_badge.dart';

class FeeSummaryCard extends StatelessWidget {
  final FeeSummary feeSummary;
  final VoidCallback? onViewDetails;
  final VoidCallback? onPayNow;

  const FeeSummaryCard({
    super.key,
    required this.feeSummary,
    this.onViewDetails,
    this.onPayNow,
  });

  VoidCallback? get _onTap => onViewDetails ?? onPayNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final perTripFormatted = (feeSummary.perTrip != null && feeSummary.perTrip! > 0)
        ? (feeSummary.perTrip! % 1 == 0
            ? feeSummary.perTrip!.toInt().toString()
            : feeSummary.perTrip!.toStringAsFixed(2))
        : null;

    final tripsSubtitle = perTripFormatted != null
        ? '${feeSummary.tripsCount} of ${feeSummary.tripsTotal} trips - Rs. $perTripFormatted per trip'
        : '${feeSummary.tripsCount} of ${feeSummary.tripsTotal} trips';

    final progress = feeSummary.tripsTotal > 0
        ? (feeSummary.tripsCount / feeSummary.tripsTotal).clamp(0.0, 1.0)
        : 0.0;

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
              Expanded(
                child: Text(
                  feeSummary.title,
                  style: const TextStyle(
                    color: AppColors.surfaceWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: feeSummary.status),
            ],
          ),
          const SizedBox(height: 14),
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
          Text(
            tripsSubtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF38BDF8),
              ),
            ),
          ),
          if (feeSummary.dueDate.isNotEmpty) ...[
            const SizedBox(height: 10),
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
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.surfaceWhite,
                side: const BorderSide(
                  color: Colors.white70,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Pay cash to your driver',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
