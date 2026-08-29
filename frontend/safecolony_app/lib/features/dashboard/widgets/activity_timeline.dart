import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';

class ActivityTimeline extends StatelessWidget {
  final List<DashboardActivity> activities;
  final ValueChanged<DashboardActivity>? onOpen;

  const ActivityTimeline({
    super.key,
    required this.activities,
    this.onOpen,
  });

  IconData _icon(String type) {
    switch (type.toUpperCase()) {
      case 'DELIVERY':
        return Icons.local_shipping;
      case 'VISITOR':
        return Icons.people;
      case 'VACATION':
        return Icons.beach_access;
      case 'SECURITY':
        return Icons.shield;
      case 'MAINTENANCE':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _color(String type) {
    switch (type.toUpperCase()) {
      case 'DELIVERY':
        return Colors.orange;
      case 'VISITOR':
        return Colors.green;
      case 'VACATION':
        return Colors.blue;
      case 'SECURITY':
        return Colors.red;
      case 'MAINTENANCE':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  String _relative(DateTime value) {
    final local = value.toLocal();
    final difference = DateTime.now().difference(local);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    if (difference.inDays < 7) return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.black.withValues(alpha: .04)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                if (onOpen != null && activities.isNotEmpty) TextButton(onPressed: () => onOpen!.call(activities.first), child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No recent activity.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...activities.map(
                (activity) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .035),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _color(activity.notificationType)
                          .withValues(alpha: .15),
                      child: Icon(
                        _icon(activity.notificationType),
                        color: _color(activity.notificationType),
                      ),
                    ),
                    title: Text(
                      activity.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${activity.message}\n${_relative(activity.createdAt)}',
                    ),
                    trailing: activity.count > 1
                        ? CircleAvatar(
                            radius: 13,
                            child: Text(
                              '${activity.count}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          )
                        : null,
                    onTap: onOpen == null
                        ? null
                        : () => onOpen!.call(activity),
                    isThreeLine: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
