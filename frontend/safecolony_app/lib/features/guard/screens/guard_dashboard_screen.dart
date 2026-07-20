import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guard_dashboard.dart';
import '../providers/guard_dashboard_provider.dart';

import '../widgets/cards/ai_insight_card.dart';
import '../widgets/cards/expected_visitor_card.dart';
import '../widgets/sections/quick_actions_section.dart';

import 'visitor_detail_screen.dart';
import '../widgets/cards/recent_activity_card.dart';
import 'dart:async';
import '../../visitors/screens/walk_in_visitor_screen.dart';
import 'qr_scanner_screen.dart';
import '../widgets/hero_banner.dart';
import '../../../../shared/widgets/dashboard_stat_chip.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';

class GuardDashboardScreen extends ConsumerStatefulWidget {
  const GuardDashboardScreen({super.key});

  @override
  ConsumerState<GuardDashboardScreen> createState() =>
      _GuardDashboardScreenState();
}

class _GuardDashboardScreenState
    extends ConsumerState<GuardDashboardScreen> {

  late Future<GuardDashboard> _future;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadDashboard();

    _startAutoRefresh();
  }

  void _loadDashboard() {
    _future = ref
        .read(guardDashboardProvider)
        .loadDashboard();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted) return;

        setState(() {
          _loadDashboard();
        });
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadDashboard();
    });

    await _future;
  }

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning 👋";
    }

    if (hour < 17) {
      return "Good Afternoon ☀";
    }

    return "Good Evening 🌙";
  }

  String colonyStatus(
    GuardDashboard dashboard,
  ) {
    if (dashboard.summary.expectedVisitors > 20) {
      return "🟡 Busy";
    }

    if (dashboard.summary.checkedInToday > 10) {
      return "🟢 Active";
    }

    return "🟢 Normal";
  }

Future<void> _onScanQR() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const QRScannerScreen(),
    ),
  );

  if (!mounted) return;

  _refresh();
}

void _onDelivery() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Delivery module coming soon"),
    ),
  );
}

void _onWalkIn() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const WalkInVisitorScreen(),
    ),
  );
}

void _onEmergency() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Emergency module coming soon"),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Guard Dashboard"),
      ),

      body: FutureBuilder<GuardDashboard>(
        future: _future,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
  title: "Unable to load dashboard",
  message: "Please check your internet connection and try again.",
  onRetry: () {
    setState(() {
      _loadDashboard();
    });
  },
);
          }

          final dashboard = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,

            child: ListView(
              padding: const EdgeInsets.all(20),

              children: [

              GuardHeroBanner(
  greeting: greeting(),
  guardName: "Security Guard",
  colonyStatus: colonyStatus(dashboard),
  expectedVisitors: dashboard.summary.expectedVisitors,
  checkedInVisitors: dashboard.summary.checkedInToday,
  deliveries: dashboard.summary.deliveries,
),

const SizedBox(height: 20),

                AIInsightCard(
                  message: dashboard.aiMessage,
                ),

                const SizedBox(height: 24),

                QuickActionsSection(
  onScanQR: _onScanQR,
  onDelivery: _onDelivery,
  onWalkIn: _onWalkIn,
  onEmergency: _onEmergency,
),

                const SizedBox(height: 30),

                const Text(
                  "Today's Expected Visitors",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                if (dashboard.expectedVisitors.isEmpty)

                const EmptyStateWidget(
  icon: Icons.celebration,
  color: Colors.green,
  title: "No Visitors Today",
  message: "Enjoy your peaceful shift 🎉",
)
                else

                  ...dashboard.expectedVisitors.map(

                    (visitor) {

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),

                        child: ExpectedVisitorCard(

                          visitor: visitor,

                          onDetails: () {

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>
                                    GuardVisitorDetailScreen(
                                  visitor: visitor,
                                ),
                              ),
                            );
                          },

                          onScan: () {

                            Navigator.push(
                              context,
                                  MaterialPageRoute(
      builder: (_) => const QRScannerScreen(),
    ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                const Text(
                  "Live Status",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

GridView.count(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 1.3,
  children: [
    DashboardStatChip(
      icon: Icons.people,
      value: "${dashboard.summary.expectedVisitors}",
      label: "Expected Visitors",
      color: Colors.blue,
    ),

    DashboardStatChip(
      icon: Icons.login,
      value: "${dashboard.summary.checkedInToday}",
      label: "Checked In",
      color: Colors.green,
    ),

    DashboardStatChip(
      icon: Icons.inventory_2,
      value: "${dashboard.summary.deliveries}",
      label: "Deliveries",
      color: Colors.orange,
    ),

    DashboardStatChip(
      icon: Icons.home_work,
      value: "${dashboard.summary.vacantHouses}",
      label: "Vacation Homes",
      color: Colors.deepPurple,
    ),
  ],
),

                const SizedBox(height: 30),

                const Text(
                  "Recent Activity",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                if (dashboard
                    .recentActivities.isEmpty)

const EmptyStateWidget(
  icon: Icons.history_toggle_off,
  color: Colors.grey,
  title: "No Recent Activity",
  message: "Everything is quiet right now.",
)

                else

                  ...dashboard
                      .recentActivities
                      .map(

                    (activity) {

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),

                        child:
                            RecentActivityCard(

                          icon: activity.icon,

                          title: activity.title,

                          time: activity.time,
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}