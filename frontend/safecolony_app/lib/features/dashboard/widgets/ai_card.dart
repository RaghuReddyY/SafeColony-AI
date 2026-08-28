import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';

class AICard extends StatelessWidget {
  final DashboardSummary dashboard;

  const AICard({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final actions = <String>[];
    if (dashboard.pendingMaintenance > 0) {
      actions.add('Maintenance ${_money(dashboard.pendingMaintenance)} pending');
    }
    if (dashboard.pendingVisitors > 0) {
      actions.add('${dashboard.pendingVisitors} visitor${dashboard.pendingVisitors == 1 ? '' : 's'} waiting');
    }
    if (dashboard.pendingDeliveries > 0) {
      actions.add('${dashboard.pendingDeliveries} delivery${dashboard.pendingDeliveries == 1 ? '' : 'ies'} waiting');
    }
    if (actions.isEmpty) actions.add(dashboard.recommendation);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff4F46E5), Color(0xff2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.auto_awesome, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SafeColony AI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(actions.take(2).join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                  const SizedBox(height: 4),
                  Text('Security ${dashboard.securityScore}% • Tap to open AI Chat', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  String _money(double value) => '₹${value.toStringAsFixed(0)}';
}
