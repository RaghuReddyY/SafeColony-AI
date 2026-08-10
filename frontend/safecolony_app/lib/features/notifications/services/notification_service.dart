import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  // ==========================================================
  // LOAD ALL NOTIFICATIONS
  // ==========================================================

  Future<List<AppNotification>> loadNotifications(
    int residentId,
  ) async {
    final Response response =
        await ApiClient.dio.get(
      "/notifications/resident/$residentId",
    );

    return (response.data as List)
        .map(
          (e) => AppNotification.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ==========================================================
  // LOAD UNREAD NOTIFICATIONS
  // ==========================================================

  Future<List<AppNotification>> loadUnread(
    int residentId,
  ) async {
    final Response response =
        await ApiClient.dio.get(
      "/notifications/resident/$residentId/unread",
    );

    return (response.data as List)
        .map(
          (e) => AppNotification.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ==========================================================
  // GET UNREAD COUNT
  // ==========================================================

  Future<int> unreadCount(
    int residentId,
  ) async {
    final Response response =
        await ApiClient.dio.get(
      "/notifications/resident/$residentId/unread-count",
    );

    return (response.data["count"] as num).toInt();
  }

  // ==========================================================
  // MARK SINGLE NOTIFICATION AS READ
  // ==========================================================

  Future<void> markRead(
    int notificationId,
  ) async {
    await ApiClient.dio.put(
      "/notifications/$notificationId/read",
    );
  }

  // ==========================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ==========================================================

  Future<void> markAllRead(
    int residentId,
  ) async {
    await ApiClient.dio.put(
      "/notifications/resident/$residentId/read-all",
    );
  }
}