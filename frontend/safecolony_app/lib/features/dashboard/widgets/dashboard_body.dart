import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import 'activity_timeline.dart';
import 'ai_card.dart';
import 'dashboard_header.dart';
import 'dashboard_stats.dart';
import 'quick_action_grid.dart';
import 'visitor_chart.dart';
import 'family_invite_card.dart';

class DashboardBody extends StatelessWidget {
  final DashboardSummary dashboard;
  final bool showFamilyInvite;

  const DashboardBody({
    super.key,
    required this.dashboard,
    this.showFamilyInvite = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 1000;
    final horizontalPadding = width < 600 ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            resident: dashboard.residentName,
            unit: dashboard.unitNumber,
            block: dashboard.sectionName,
            organizationName: dashboard.organizationName,
            organizationCode: dashboard.organizationCode,
            score: dashboard.securityScore,
          ),
          const SizedBox(height: 24),
          const Text(
            'Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          DashboardStats(dashboard: dashboard),
          const SizedBox(height: 26),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          const QuickActionGrid(),
          const SizedBox(height: 28),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: VisitorChart(
                    weeklyVisitors: dashboard.weeklyVisitors,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: AICard(dashboard: dashboard)),
              ],
            )
          else ...[
            VisitorChart(weeklyVisitors: dashboard.weeklyVisitors),
            const SizedBox(height: 18),
            AICard(dashboard: dashboard),
          ],
          if (showFamilyInvite) ...[
            const SizedBox(height: 20),
            const FamilyInviteCard(),
          ],
          const SizedBox(height: 20),
          ActivityTimeline(activities: dashboard.recentActivity),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
