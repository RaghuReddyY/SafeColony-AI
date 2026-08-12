import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  /// Notifications belong to the authenticated user, not to a resident id.
  /// Always use the /me endpoints so residents, guards and administrators
  /// see their own notification inbox.
  Future<List<AppNotification>> loadNotifications() async {
    final Response response = await ApiClient.dio.get('/notifications/me');
    return (response.data as List)
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AppNotification>> loadUnread() async {
    final Response response = await ApiClient.dio.get('/notifications/me/unread');
    return (response.data as List)
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> unreadCount() async {
    final Response response = await ApiClient.dio.get('/notifications/me/unread-count');
    return (response.data['count'] as num).toInt();
  }

  Future<void> markRead(int notificationId) async {
    await ApiClient.dio.put('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await ApiClient.dio.put('/notifications/me/read-all');
  }
}
