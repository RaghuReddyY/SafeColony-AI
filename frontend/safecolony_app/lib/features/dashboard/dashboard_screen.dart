import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_summary.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/dashboard_body.dart';
import 'widgets/dashboard_sidebar.dart';

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

    return Scaffold(

      backgroundColor: const Color(0xffF5F7FB),

      drawer: const DashboardSidebar(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("SafeColony AI"),
        actions: const [

          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
        ],
      ),

      body: FutureBuilder<DashboardSummary>(

        future: ref
            .read(dashboardProvider)
            .loadDashboard(2),

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

          final dashboard = snapshot.data!;

          return DashboardBody(
            dashboard: dashboard,
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
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