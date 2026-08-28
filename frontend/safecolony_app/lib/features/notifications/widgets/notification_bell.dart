import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/push_notification_service.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_screen.dart';
import '../../chat/screens/community_chat_screen.dart';
import '../../maintenance/screens/maintenance_resident_screen.dart';
import '../../complaints/screens/complaint_screen.dart';
import '../../incidents/screens/incident_screen.dart';
import '../../visitors/screens/visitor_list_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../admin/screens/resident_approval_screen.dart';
import '../../maintenance/screens/maintenance_admin_screen.dart';
import '../../maintenance/screens/community_finance_screen.dart';
import '../../super_app/screens/super_app_screen.dart';
import '../../marketplace/screens/marketplace_vendor_screen.dart';


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

    PushNotificationService.instance.setNotificationTapHandler(_handlePush);
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

  void _handlePush(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = (data['entity_type'] ?? data['type'] ?? '').toString().toUpperCase();
    final id = int.tryParse((data['entity_id'] ?? '').toString());
    final role = ref.read(authProvider).user?.role?.toUpperCase() ?? '';
    final notificationId = int.tryParse((data['notification_id'] ?? '').toString());
    if (notificationId != null) {
      ref.read(notificationProvider.notifier).markRead(notificationId);
    }
    switch (type) {
      case 'COMMUNITY_CHAT':
      case 'CHAT':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityChatScreen()));
        break;
      case 'MAINTENANCE':
      case 'MAINTENANCE_DUE':
      case 'MAINTENANCE_PAYMENT':
      case 'PAYMENT':
        Navigator.push(context, MaterialPageRoute(builder: (_) => role == 'RESIDENT' ? MaintenanceResidentScreen(initialBillId: id) : const MaintenanceAdminScreen()));
        break;
      case 'RESIDENT_APPROVAL':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentApprovalScreen()));
        break;
      case 'COMMUNITY_FINANCE':
      case 'COMMUNITY_FINANCE_PAYMENT':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFinanceScreen()));
        break;
      case 'SERVICE_REQUEST':
        Navigator.push(context, MaterialPageRoute(builder: (_) => role == 'VENDOR' ? const MarketplaceVendorScreen() : const SuperAppScreen()));
        break;
      case 'COMPLAINT':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen()));
        break;
      case 'INCIDENT':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentScreen()));
        break;
      case 'VISITOR':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorListScreen()));
        break;
      case 'DELIVERY':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryDashboardScreen()));
        break;
      default:
        _openNotifications();
    }
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
          icon: const Icon(Icons.notifications_outlined, color: Color(0xff334155), size: 26),
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
