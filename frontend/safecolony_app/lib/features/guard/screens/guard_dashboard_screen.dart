import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/login_screen.dart';
import '../../auth/providers/auth_provider.dart';

import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notification_screen.dart';

import '../../visitors/screens/walk_in_visitor_screen.dart';

import '../models/guard_dashboard.dart';
import '../providers/guard_dashboard_provider.dart';
import '../providers/guard_visitor_provider.dart';

import '../screens/qr_scanner_screen.dart';
import '../screens/visitor_detail_screen.dart';

import '../widgets/cards/ai_insight_card.dart';
import '../widgets/cards/expected_visitor_card.dart';
import '../widgets/cards/recent_activity_card.dart';

import '../widgets/hero_banner.dart';

import '../widgets/sections/approved_visitors_section.dart';
import '../widgets/sections/pending_visitors_section.dart';
import '../widgets/sections/quick_actions_section.dart';
import '../widgets/sections/visitors_inside_section.dart';

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
  Timer? _timer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!mounted) return;

      // Initial dashboard load
      await ref
          .read(guardDashboardProvider.notifier)
          .load();

      if (!mounted) return;

      // Initial visitor load
      await ref
          .read(guardVisitorProvider.notifier)
          .loadAll();

      if (!mounted) return;

      // Initial notification load
      final user = ref.read(authProvider).user;

      if (user != null) {
        await ref
            .read(notificationProvider.notifier)
            .load(user.id);
      }
    });

    // ============================================================
    // BACKGROUND AUTO REFRESH
    // ============================================================

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        if (!mounted) return;

        // --------------------------------------------------------
        // Dashboard
        // --------------------------------------------------------

        ref
            .read(guardDashboardProvider.notifier)
            .refresh();

        // --------------------------------------------------------
        // Visitors
        //
        // IMPORTANT:
        // Do not show loading spinner during background refresh.
        // Existing visitor data remains visible.
        // --------------------------------------------------------

        ref
            .read(guardVisitorProvider.notifier)
            .loadAll(
              showLoading: false,
            );

        // --------------------------------------------------------
        // Notifications
        // --------------------------------------------------------

        final user = ref.read(authProvider).user;

        if (user != null) {
          ref
              .read(notificationProvider.notifier)
              .load(user.id);
        }
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // MANUAL REFRESH
  // ============================================================

  Future<void> _refresh() async {
    final user = ref.read(authProvider).user;

    final futures = <Future<void>>[
      ref
          .read(guardDashboardProvider.notifier)
          .refresh(),

      ref
          .read(guardVisitorProvider.notifier)
          .loadAll(
            showLoading: false,
          ),
    ];

    if (user != null) {
      futures.add(
        ref
            .read(notificationProvider.notifier)
            .load(user.id),
      );
    }

    await Future.wait(futures);
  }

  // ============================================================
  // GREETING
  // ============================================================

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

  // ============================================================
  // COLONY STATUS
  // ============================================================

  String colonyStatus(
    GuardDashboard dashboard,
  ) {
    if (dashboard.summary.pendingVisitors > 20) {
      return "Busy";
    }

    if (dashboard.summary.insideVisitors > 10) {
      return "Active";
    }

    return "Normal";
  }

  // ============================================================
  // VISITOR GRID
  // ============================================================

  int visitorGridCount(double width) {
    if (width > 1500) return 4;

    if (width > 1100) return 3;

    if (width > 700) return 2;

    return 1;
  }

  // ============================================================
  // ACTION GRID
  // ============================================================

  int actionGridCount(double width) {
    if (width > 900) return 4;

    return 2;
  }

  // ============================================================
  // STAT GRID
  // ============================================================

  int statGridCount(double width) {
    if (width > 900) return 4;

    return 2;
  }

  // ============================================================
  // QR SCANNER
  // ============================================================

  Future<void> _scanQR() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QRScannerScreen(),
      ),
    );

    if (!mounted) return;

    await _refresh();
  }

  // ============================================================
  // WALK-IN VISITOR
  // ============================================================

  Future<void> _walkIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WalkInVisitorScreen(),
      ),
    );

    if (!mounted) return;

    await _refresh();
  }

  // ============================================================
  // DELIVERY
  // ============================================================

  void _delivery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Delivery module coming soon",
        ),
      ),
    );
  }

  // ============================================================
  // EMERGENCY
  // ============================================================

  void _emergency() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Emergency module coming soon",
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await ref
        .read(authProvider.notifier)
        .logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // Dashboard state
    // ----------------------------------------------------------

    final dashboardState =
        ref.watch(guardDashboardProvider);

    final dashboard =
        dashboardState.dashboard;

    // ----------------------------------------------------------
    // Notification state
    // ----------------------------------------------------------

    final notificationState =
        ref.watch(notificationProvider);

    // ----------------------------------------------------------
    // Initial loading
    //
    // Only show full-screen loading if there is no existing
    // dashboard data.
    //
    // During background refresh, dashboard remains visible.
    // ----------------------------------------------------------

    if (dashboardState.loading &&
        dashboard == null) {
      return const Scaffold(
        backgroundColor:
            Color(0xffF5F7FB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ----------------------------------------------------------
    // Initial error
    // ----------------------------------------------------------

    if (dashboardState.error != null &&
        dashboard == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xffF5F7FB),
        body: ErrorStateWidget(
          title: "Unable to load dashboard",
          message: "Please try again.",
          onRetry: () {
            ref
                .read(
                  guardDashboardProvider.notifier,
                )
                .load();
          },
        ),
      );
    }

    // ----------------------------------------------------------
    // No dashboard data
    // ----------------------------------------------------------

    if (dashboard == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xffF5F7FB),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ref
                  .read(
                    guardDashboardProvider.notifier,
                  )
                  .load();
            },
            child: const Text(
              "Load Dashboard",
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // MAIN SCAFFOLD
    // ==========================================================

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          "Guard Dashboard",
        ),

        actions: [
          // ----------------------------------------------------
          // Notification
          // ----------------------------------------------------

          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationScreen(),
                    ),
                  );

                  if (!mounted) return;

                  // Refresh notification count when
                  // returning from notification screen.
                  final user =
                      ref.read(authProvider).user;

                  if (user != null) {
                    ref
                        .read(
                          notificationProvider
                              .notifier,
                        )
                        .load(user.id);
                  }
                },
              ),

              if (notificationState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.all(4),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${notificationState.unreadCount}",
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ----------------------------------------------------
          // Logout
          // ----------------------------------------------------

          IconButton(
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: ListView(
          padding:
              const EdgeInsets.all(24),

          children: [
            // ==================================================
            // HERO
            // ==================================================

            GuardHeroBanner(
              greeting: greeting(),

              guardName:
                  "Security Guard",

              colonyStatus:
                  colonyStatus(
                dashboard,
              ),

              expectedVisitors:
                  dashboard
                      .summary
                      .pendingVisitors,

              checkedInVisitors:
                  dashboard
                      .summary
                      .insideVisitors,

              deliveries:
                  dashboard
                      .summary
                      .deliveries,
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // AI INSIGHT
            // ==================================================

            AIInsightCard(
              message:
                  dashboard.aiMessage,
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================

            QuickActionsSection(
              crossAxisCount:
                  actionGridCount(
                MediaQuery.of(context)
                    .size
                    .width,
              ),

              onScanQR: _scanQR,

              onDelivery:
                  _delivery,

              onWalkIn:
                  _walkIn,

              onEmergency:
                  _emergency,
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // LIVE STATUS
            // ==================================================

            const Text(
              "Live Status",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            GridView.count(
              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              crossAxisCount:
                  statGridCount(
                MediaQuery.of(context)
                    .size
                    .width,
              ),

              crossAxisSpacing: 16,

              mainAxisSpacing: 16,

              childAspectRatio: 1.8,

              children: [
                DashboardStatChip(
                  icon:
                      Icons.hourglass_top,

                  value:
                      "${dashboard.summary.pendingVisitors}",

                  label:
                      "Pending",

                  color:
                      Colors.orange,
                ),

                DashboardStatChip(
                  icon:
                      Icons.verified,

                  value:
                      "${dashboard.summary.approvedVisitors}",

                  label:
                      "Approved",

                  color:
                      Colors.blue,
                ),

                DashboardStatChip(
                  icon:
                      Icons.login,

                  value:
                      "${dashboard.summary.insideVisitors}",

                  label:
                      "Inside",

                  color:
                      Colors.green,
                ),

                DashboardStatChip(
                  icon:
                      Icons.inventory_2,

                  value:
                      "${dashboard.summary.deliveries}",

                  label:
                      "Deliveries",

                  color:
                      Colors.deepPurple,
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // TODAY'S EXPECTED VISITORS
            // ==================================================

            const Text(
              "Today's Expected Visitors",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            if (dashboard
                .expectedVisitors
                .isEmpty)
              const EmptyStateWidget(
                icon:
                    Icons.people_outline,

                color:
                    Colors.green,

                title:
                    "No Visitors Today",

                message:
                    "Enjoy your peaceful shift.",
              )
            else
              GridView.builder(
                shrinkWrap: true,

                physics:
                    const NeverScrollableScrollPhysics(),

                itemCount:
                    dashboard
                        .expectedVisitors
                        .length,

                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      visitorGridCount(
                    MediaQuery.of(context)
                        .size
                        .width,
                  ),

                  crossAxisSpacing:
                      18,

                  mainAxisSpacing:
                      18,

                  // ------------------------------------------------
                  // FIX:
                  // Use fixed card height instead of childAspectRatio.
                  //
                  // This prevents huge cards on wide screens.
                  // ------------------------------------------------

                  mainAxisExtent:
                      220,
                ),

                itemBuilder:
                    (_, index) {
                  final visitor =
                      dashboard
                              .expectedVisitors[
                          index];

                  return ExpectedVisitorCard(
                    visitor:
                        visitor,

                    onDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GuardVisitorDetailScreen(
                            visitor:
                                visitor,
                          ),
                        ),
                      );
                    },

                    onScan:
                        _scanQR,
                  );
                },
              ),

            const SizedBox(
              height: 36,
            ),

            // ==================================================
            // PENDING VISITORS
            // ==================================================

            const PendingVisitorsSection(),

            const SizedBox(
              height: 36,
            ),

            // ==================================================
            // APPROVED VISITORS
            // ==================================================

            const ApprovedVisitorsSection(),

            const SizedBox(
              height: 36,
            ),

            // ==================================================
            // VISITORS INSIDE
            // ==================================================

            const VisitorsInsideSection(),

            const SizedBox(
              height: 36,
            ),

            // ==================================================
            // RECENT ACTIVITY
            // ==================================================

            const Text(
              "Recent Activity",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (dashboard
                .recentActivities
                .isEmpty)
              const EmptyStateWidget(
                icon:
                    Icons.history,

                color:
                    Colors.grey,

                title:
                    "No Activity",

                message:
                    "Everything is quiet.",
              )
            else
              ...dashboard
                  .recentActivities
                  .map(
                (activity) =>
                    Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child:
                      RecentActivityCard(
                    icon:
                        activity.icon,

                    title:
                        activity.title,

                    time:
                        activity.time,
                  ),
                ),
              ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}