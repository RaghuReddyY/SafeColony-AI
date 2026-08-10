import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';

final notificationProvider =
    StateNotifierProvider<
        NotificationNotifier,
        NotificationState>(
  (ref) => NotificationNotifier(),
);

class NotificationState {
  final bool loading;
  final String? error;
  final int unreadCount;
  final List<AppNotification> notifications;

  const NotificationState({
    this.loading = false,
    this.error,
    this.unreadCount = 0,
    this.notifications = const [],
  });

  NotificationState copyWith({
    bool? loading,
    String? error,
    int? unreadCount,
    List<AppNotification>? notifications,
  }) {
    return NotificationState(
      loading: loading ?? this.loading,
      error: error,
      unreadCount:
          unreadCount ?? this.unreadCount,
      notifications:
          notifications ?? this.notifications,
    );
  }
}

class NotificationNotifier
    extends StateNotifier<NotificationState> {
  NotificationNotifier()
      : super(
          const NotificationState(),
        );

  final NotificationService _service =
      NotificationService();

  // ==========================================================
  // LOAD NOTIFICATIONS
  // ==========================================================

  Future<void> load(
    int residentId,
  ) async {
    try {
      state = state.copyWith(
        loading: true,
        error: null,
      );

      final notifications =
          await _service.loadNotifications(
        residentId,
      );

      final count =
          await _service.unreadCount(
        residentId,
      );

      state = state.copyWith(
        loading: false,
        notifications: notifications,
        unreadCount: count,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // ==========================================================
  // MARK SINGLE NOTIFICATION AS READ
  // ==========================================================

  Future<void> markRead(
    int residentId,
    int notificationId,
  ) async {
    try {
      // First update backend.
      await _service.markRead(
        notificationId,
      );

      // Then immediately update local UI.
      final updatedNotifications =
          state.notifications.map(
        (notification) {
          if (notification.id ==
              notificationId) {
            return notification.copyWith(
              isRead: true,
            );
          }

          return notification;
        },
      ).toList();

      final newUnreadCount =
          updatedNotifications
              .where(
                (notification) =>
                    !notification.isRead,
              )
              .length;

      state = state.copyWith(
        notifications:
            updatedNotifications,
        unreadCount: newUnreadCount,
        error: null,
      );

      // Optional backend synchronization.
      await load(residentId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  // ==========================================================
  // MARK ALL AS READ
  // ==========================================================

  Future<void> markAllRead(
    int residentId,
  ) async {
    try {
      // Update backend.
      await _service.markAllRead(
        residentId,
      );

      // Immediately update UI.
      final updatedNotifications =
          state.notifications.map(
        (notification) {
          return notification.copyWith(
            isRead: true,
          );
        },
      ).toList();

      state = state.copyWith(
        notifications:
            updatedNotifications,
        unreadCount: 0,
        error: null,
      );

      // Synchronize with backend.
      await load(residentId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }
}