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
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final dashboard = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,

            child: ListView(
              padding: const EdgeInsets.all(20),

              children: [

                Text(
                  greeting(),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 6),

                Row(
                  children: [

                    const Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 12,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      "Colony Status : ${colonyStatus(dashboard)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                AIInsightCard(
                  message: dashboard.aiMessage,
                ),

                const SizedBox(height: 24),

                const QuickActionsSection(),

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

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(30),

                      child: Column(
                        children: const [

                          Icon(
                            Icons.celebration,
                            size: 60,
                            color: Colors.green,
                          ),

                          SizedBox(height: 20),

                          Text(
                            "No Visitors Today",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            "Enjoy your peaceful shift 🎉",
                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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

                            Navigator.pushNamed(
                              context,
                              "/guard",
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

                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children: [

                    Chip(
                      avatar: const Icon(Icons.people),
                      label: Text(
                        "${dashboard.summary.expectedVisitors} Visitors",
                      ),
                    ),

                    Chip(
                      avatar: const Icon(Icons.login),
                      label: Text(
                        "${dashboard.summary.checkedInToday} Inside",
                      ),
                    ),

                    Chip(
                      avatar: const Icon(Icons.inventory),
                      label: Text(
                        "${dashboard.summary.deliveries} Deliveries",
                      ),
                    ),

                    Chip(
                      avatar: const Icon(Icons.home),
                      label: Text(
                        "${dashboard.summary.vacantHouses} Vacation",
                      ),
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

                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "No recent activity",
                        ),
                      ),
                    ),
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