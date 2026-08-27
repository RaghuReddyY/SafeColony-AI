import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(notificationProvider.notifier).load();
    });
  }

  Future<void> _markRead(int notificationId) async {
    await ref.read(notificationProvider.notifier).markRead(notificationId);
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationProvider.notifier).markAllRead();
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'SECURITY':
        return Icons.security;
      case 'VISITOR':
        return Icons.person;
      case 'DELIVERY':
        return Icons.local_shipping;
      case 'PAYMENT':
        return Icons.payments;
      case 'MAINTENANCE':
        return Icons.build;
      case 'EMERGENCY':
        return Icons.warning;
      case 'INCIDENT':
        return Icons.report_problem;
      case 'COMPLAINT':
        return Icons.support_agent;
      case 'AMENITY':
        return Icons.pool;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'SECURITY':
        return Colors.red;
      case 'VISITOR':
        return Colors.blue;
      case 'DELIVERY':
        return Colors.deepPurple;
      case 'PAYMENT':
        return Colors.green;
      case 'MAINTENANCE':
        return Colors.orange;
      case 'EMERGENCY':
        return Colors.redAccent;
      case 'INCIDENT':
        return Colors.deepOrange;
      case 'COMPLAINT':
        return Colors.deepPurple;
      case 'AMENITY':
        return Colors.cyan;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime value) {
    // API timestamps are UTC. Display them in the phone's local timezone.
    // This works correctly for India (IST, UTC+05:30) and for residents
    // travelling or using a different device timezone.
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.unreadCount} unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: state.unreadCount > 0 ? _markAllRead : null,
            child: const Text('Mark All'),
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationState state,
  ) {
    if (state.loading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(notificationProvider.notifier).load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationProvider.notifier).load();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Icon(
                Icons.notifications_none,
                size: 70,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'You are all caught up.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationProvider.notifier).load();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          final isUnread = !notification.isRead;
          final iconColor = _colorForType(notification.notificationType);

          return Card(
            elevation: isUnread ? 3 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            color: isUnread ? Colors.white : Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isUnread
                    ? Colors.blue.withOpacity(0.25)
                    : Colors.grey.shade300,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isUnread
                  ? () => _markRead(notification.id)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          isUnread ? iconColor : Colors.grey.shade300,
                      child: Icon(
                        _iconForType(notification.notificationType),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? Colors.blue.withOpacity(0.10)
                                      : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isUnread ? 'UNREAD' : 'READ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUnread
                                        ? Colors.blue
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: isUnread
                                  ? Colors.black87
                                  : Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _formatDate(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              if (isUnread)
                                const Text(
                                  'Tap to mark as read',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
