import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_summary.dart';
import '../auth/providers/auth_provider.dart';
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

body: IndexedStack(
  index: currentIndex,
  children: [

    Builder(
      builder: (context) {

        final auth = ref.watch(authProvider);

        if (auth.user?.role == "SYSTEM_ADMIN") {
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
          builder: (context,snapshot){

            if(snapshot.connectionState==
                ConnectionState.waiting){
              return const Center(
                child:CircularProgressIndicator(),
              );
            }

            if(snapshot.hasError){
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }

            if(!snapshot.hasData){
              return const Center(
                child: Text("No data"),
              );
            }

            return DashboardBody(
              dashboard: snapshot.data!,
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
  if (index == currentIndex) return;

  setState(() {
    currentIndex = index;
  });

  switch (index) {
    case 0:
      break; // Already on Dashboard

    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VisitorListScreen(),
        ),
      );
      break;

    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DeliveryDashboardScreen(),
        ),
      );
      break;

    case 3:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile module coming soon"),
        ),
      );
      break;
  }
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