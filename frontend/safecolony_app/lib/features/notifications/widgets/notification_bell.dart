import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_screen.dart';

/// Shared notification bell used by Resident and Admin dashboards.
///
/// It loads the current user's notification count when the dashboard
/// is shown and refreshes it periodically so the badge stays current.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({
    super.key,
    this.refreshInterval = const Duration(seconds: 10),
  });

  final Duration refreshInterval;

  @override
  ConsumerState<NotificationBell> createState() =>
      _NotificationBellState();
}

class _NotificationBellState
    extends ConsumerState<NotificationBell> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    Future.microtask(_load);

    _timer = Timer.periodic(
      widget.refreshInterval,
      (_) => _load(),
    );
  }

  Future<void> _load() async {
    if (!mounted) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    await ref.read(notificationProvider.notifier).load();
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );

    if (!mounted) return;

    await _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState =
        ref.watch(notificationProvider);

    final unreadCount =
        notificationState.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: "Notifications",
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _openNotifications,
        ),

        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99
                    ? "99+"
                    : "$unreadCount",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
