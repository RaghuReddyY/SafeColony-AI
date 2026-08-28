import '../../../core/utils/api_date_time.dart';
class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String notificationType;
  final String? entityType;
  final int? entityId;
  final String? action;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.entityType,
    this.entityId,
    this.action,
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
      entityType: json["entity_type"]?.toString(),
      entityId: (json["entity_id"] as num?)?.toInt(),
      action: json["action"]?.toString(),
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
    String? entityType,
    int? entityId,
    String? action,
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
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}