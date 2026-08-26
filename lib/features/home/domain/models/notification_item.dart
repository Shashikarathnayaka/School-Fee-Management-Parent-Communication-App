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
}
