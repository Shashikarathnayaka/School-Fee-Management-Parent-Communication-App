import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/notification_model.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// Shared relative-time formatter used by both [fromJson] and the
  /// notifications screen when mapping [AppNotification] objects.
  static String formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    return '${dt.day} $m';
  }

  factory NotificationItem.fromNotification(AppNotification n) {
    final isDriverOnTheWay =
        n.title.toLowerCase().contains('driver on the way');
    return NotificationItem(
      id: n.id,
      title: n.title,
      message: n.message,
      time: formatTime(n.createdAt),
      isRead: n.isRead,
      icon: isDriverOnTheWay ? Icons.directions_bus_rounded : null,
      iconColor: isDriverOnTheWay ? AppColors.accentTeal : null,
      iconBackgroundColor: isDriverOnTheWay
          ? AppColors.accentTeal.withValues(alpha: 0.12)
          : null,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] ?? json['createdAt'];
    final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;
    final title = json['title'] ?? '';
    final isDriverOnTheWay =
        (title as String).toLowerCase().contains('driver on the way');
    return NotificationItem(
      id: json['id'] ?? '',
      title: title,
      message: json['message'] ?? '',
      time: formatTime(dt),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      icon: isDriverOnTheWay ? Icons.directions_bus_rounded : null,
      iconColor: isDriverOnTheWay ? AppColors.accentTeal : null,
      iconBackgroundColor: isDriverOnTheWay
          ? AppColors.accentTeal.withValues(alpha: 0.12)
          : null,
    );
  }

  NotificationItem copyWith({
    bool? isRead,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
    );
  }
}
