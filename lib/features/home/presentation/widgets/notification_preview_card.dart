import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/notification_item.dart';

class NotificationPreviewCard extends StatelessWidget {
  final List<NotificationItem> notifications;
  final void Function(NotificationItem item)? onItemTap;
  final void Function(NotificationItem item)? onItemDismissed;
  final Future<bool> Function(NotificationItem item)? confirmDismiss;

  const NotificationPreviewCard({
    super.key,
    required this.notifications,
    this.onItemTap,
    this.onItemDismissed,
    this.confirmDismiss,
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
          final isDriverOnTheWay =
              item.title.toLowerCase().contains('driver on the way');
          final iconData = item.icon ??
              (isDriverOnTheWay
                  ? Icons.directions_bus_rounded
                  : (item.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded));
          final iconColor = item.iconColor ??
              (isDriverOnTheWay
                  ? AppColors.accentTeal
                  : (item.isRead
                      ? AppColors.textSecondary
                      : AppColors.primaryBlue));
          final iconBgColor = item.iconBackgroundColor ??
              (isDriverOnTheWay
                  ? AppColors.accentTeal.withValues(alpha: 0.12)
                  : (item.isRead
                      ? AppColors.inputFill
                      : AppColors.primaryBlueLight));

          final hasDistinctTitle =
              item.title.isNotEmpty && item.title != item.message;

          final tile = ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: onItemTap != null ? () => onItemTap!(item) : null,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 18,
              ),
            ),
            title: Text(
              hasDistinctTitle ? item.title : item.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                color: isDriverOnTheWay && !item.isRead
                    ? AppColors.accentTeal
                    : AppColors.primaryNavy,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDistinctTitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );

          if (onItemDismissed != null || confirmDismiss != null) {
            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: AppColors.error,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.surfaceWhite,
                ),
              ),
              confirmDismiss: confirmDismiss != null
                  ? (direction) => confirmDismiss!(item)
                  : null,
              onDismissed: onItemDismissed != null
                  ? (_) => onItemDismissed!(item)
                  : null,
              child: tile,
            );
          }

          return tile;
        },
      ),
    );
  }
}
