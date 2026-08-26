import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/notification_item.dart';

class NotificationPreviewCard extends StatelessWidget {
  final List<NotificationItem> notifications;
  final VoidCallback? onItemTap;

  const NotificationPreviewCard({
    super.key,
    required this.notifications,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'No recent notifications',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: AppColors.cardBorder,
        ),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: onItemTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.isRead
                    ? AppColors.inputFill
                    : AppColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isRead
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
                color: item.isRead
                    ? AppColors.textSecondary
                    : AppColors.primaryBlue,
                size: 18,
              ),
            ),
            title: Text(
              item.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
            ),
            subtitle: Text(
              item.time,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}
