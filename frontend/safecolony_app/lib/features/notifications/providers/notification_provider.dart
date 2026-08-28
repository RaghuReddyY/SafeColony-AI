import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import '../../settings/services/settings_service.dart';

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

  final SettingsService _settingsService =
      SettingsService();

  Future<List<AppNotification>> _applyNotificationPreferences(
    List<AppNotification> notifications,
  ) async {
    final inApp =
        await _settingsService.getInAppNotifications();

    if (!inApp) {
      return const [];
    }

    final visitor =
        await _settingsService.getVisitorNotifications();
    final delivery =
        await _settingsService.getDeliveryNotifications();
    final maintenance =
        await _settingsService.getMaintenanceNotifications();
    final security =
        await _settingsService.getSecurityNotifications();

    return notifications.where((notification) {
      final type = notification.notificationType.toUpperCase();

      switch (type) {
        case 'VISITOR':
          return visitor;
        case 'DELIVERY':
          return delivery;
        case 'MAINTENANCE':
        case 'PAYMENT':
          return maintenance;
        case 'SECURITY':
        case 'EMERGENCY':
          return security;
        default:
          return true;
      }
    }).toList();
  }

  // ==========================================================
  // LOAD NOTIFICATIONS
  // ==========================================================

  Future<void> load({String? category}) async {
    try {
      state = state.copyWith(
        loading: true,
        error: null,
      );

      final notifications =
          await _service.loadNotifications(category: category);

      final visibleNotifications =
          await _applyNotificationPreferences(
        notifications,
      );

      final visibleUnreadCount =
          visibleNotifications.where(
        (notification) => !notification.isRead,
      ).length;

      state = state.copyWith(
        loading: false,
        notifications: visibleNotifications,
        unreadCount: visibleUnreadCount,
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
      await load();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  // ==========================================================
  // MARK ALL AS READ
  // ==========================================================

  Future<void> markAllRead() async {
    try {
      // Update backend.
      await _service.markAllRead();

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
      await load();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }
}