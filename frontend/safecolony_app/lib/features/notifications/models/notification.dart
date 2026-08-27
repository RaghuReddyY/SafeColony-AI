import '../../../core/utils/api_date_time.dart';
class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppNotification(
      id: json["id"] as int,
      userId: json["user_id"] as int,
      title: json["title"] as String? ?? "",
      message: json["message"] as String? ?? "",
      notificationType:
          json["notification_type"] as String? ?? "GENERAL",
      isRead: json["is_read"] as bool? ?? false,
      createdAt: ApiDateTime.parse(json['created_at']),
    );
  }

  AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? notificationType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType:
          notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}