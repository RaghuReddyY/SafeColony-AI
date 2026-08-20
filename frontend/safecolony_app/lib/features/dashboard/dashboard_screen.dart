import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_summary.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/widgets/dashboard_quick_access_fabs.dart';
import '../notifications/widgets/notification_bell.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/dashboard_body.dart';
import 'widgets/dashboard_sidebar.dart';
import '../visitors/screens/visitor_list_screen.dart';
import '../delivery/screens/delivery_dashboard_screen.dart';
import '../profile/screens/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends ConsumerState<DashboardScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      drawer: const DashboardSidebar(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'SafeColony AI',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (user?.role == "RESIDENT")
            const NotificationBell(),

          const Padding(
            padding: EdgeInsets.only(
              right: 14,
              left: 2,
            ),
            child: CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
        ],
      ),

      floatingActionButton: const DashboardQuickAccessFabs(),

      body: IndexedStack(
        index: currentIndex,
        children: [
          Builder(
            builder: (context) {
              if (user?.role == "SYSTEM_ADMIN") {
                return const Center(
                  child: Text(
                    "Welcome System Administrator",
                  ),
                );
              }

              return FutureBuilder<DashboardSummary>(
                future: ref
                    .read(dashboardProvider)
                    .loadDashboard(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text("No data"),
                    );
                  }

                  return DashboardBody(
                    dashboard: snapshot.data!,
                    showFamilyInvite: user?.role == "RESIDENT",
                  );
                },
              );
            },
          ),

          const VisitorListScreen(),

          const DeliveryDashboardScreen(),

          const ProfileScreen(),
        ],
      ),

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;

          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Visitors",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Deliveries",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
