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
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;

        if (constraints.maxWidth > 1200) {
          columns = 4;
        } else if (constraints.maxWidth > 800) {
          columns = 2;
        } else {
          columns = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,

            // Bigger cards = no overflow
            childAspectRatio:
                columns == 4 ? 1.55 : 1.25,
          ),

          itemCount: 4,

          itemBuilder: (_, index) {
            switch (index) {
              case 0:
                return AnimatedStatCard(
                  title: "Visitors",
                  value: dashboard.visitorCount.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                );

              case 1:
                return AnimatedStatCard(
                  title: "Deliveries",
                  value: dashboard.deliveryCount.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.orange,
                );

              case 2:
                return AnimatedStatCard(
                  title: "Notifications",
                  value:
                      dashboard.notificationCount.toString(),
                  icon: Icons.notifications,
                  color: Colors.red,
                );

              default:
                return AnimatedStatCard(
                  title: "Vacation",
                  value:
                      dashboard.vacationMode ? "ON" : "OFF",
                  icon: Icons.beach_access,
                  color: Colors.green,
                );
            }
          },
        );
      },
    );
  }
}