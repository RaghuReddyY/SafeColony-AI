import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import 'animated_stat_card.dart';

class DashboardStats extends StatelessWidget {
  final DashboardSummary dashboard;

  const DashboardStats({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount:
          MediaQuery.of(context).size.width > 900 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio:
          MediaQuery.of(context).size.width > 900 ? 1.45 : 1.15,
      children: [
        AnimatedStatCard(
          title: "Visitors",
          value: dashboard.visitorCount.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        AnimatedStatCard(
          title: "Deliveries",
          value: dashboard.deliveryCount.toString(),
          icon: Icons.inventory_2,
          color: Colors.orange,
        ),
        AnimatedStatCard(
          title: "Notifications",
          value: dashboard.notificationCount.toString(),
          icon: Icons.notifications,
          color: Colors.red,
        ),
        AnimatedStatCard(
          title: "Vacation",
          value: dashboard.vacationMode ? "ON" : "OFF",
          icon: Icons.beach_access,
          color: Colors.green,
        ),
      ],
    );
  }
}