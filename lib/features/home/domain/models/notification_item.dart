import '../../../../core/models/notification_model.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
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
    return NotificationItem(
      id: n.id,
      title: n.title,
      message: n.message,
      time: formatTime(n.createdAt),
      isRead: n.isRead,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] ?? json['createdAt'];
    final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      time: formatTime(dt),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}
