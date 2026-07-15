import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import 'activity_timeline.dart';
import 'ai_card.dart';
import 'dashboard_header.dart';
import 'dashboard_stats.dart';
import 'quick_action_grid.dart';
import 'visitor_chart.dart';

class DashboardBody extends StatelessWidget {
  final DashboardSummary dashboard;

  const DashboardBody({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width > 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            resident: dashboard.residentName,
            unit: dashboard.unitNumber,
            score: dashboard.securityScore,
          ),

          const SizedBox(height: 30),

          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          DashboardStats(
            dashboard: dashboard,
          ),

          const SizedBox(height: 35),

          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          const QuickActionGrid(),

          const SizedBox(height: 35),

          if (isDesktop)
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 2,
                  child: VisitorChart(),
                ),

                const SizedBox(width: 20),

                const Expanded(
                  child: AICard(),
                ),
              ],
            )
          else ...[
            const VisitorChart(),
            const SizedBox(height: 20),
            const AICard(),
          ],

          const SizedBox(height: 30),

          const ActivityTimeline(),
        ],
      ),
    );
  }
}