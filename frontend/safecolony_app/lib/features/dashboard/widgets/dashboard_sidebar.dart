import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/dashboard_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../visitors/screens/visitor_list_screen.dart';
import '../../auth/login_screen.dart';
import '../../guard/screens/guard_dashboard_screen.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: const Color(0xff1E293B),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff4F46E5),
                      Color(0xff2563EB),
                    ],
                  ),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 38,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Raghunatha Reddy",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Resident",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _menu(
                context,
                ref,
                icon: Icons.dashboard,
                title: "Dashboard",
                selected: true,
              ),

              _menu(
                context,
                ref,
                icon: Icons.people,
                title: "Visitors",
              ),

              _menu(
                context,
                ref,
                icon: Icons.qr_code_scanner,
                title: "Guard Scanner",
              ),

              _menu(
                context,
                ref,
                icon: Icons.inventory_2,
                title: "Deliveries",
              ),

              _menu(
                context,
                ref,
                icon: Icons.beach_access,
                title: "Vacation",
              ),

              _menu(
                context,
                ref,
                icon: Icons.notifications,
                title: "Notifications",
              ),

              _menu(
                context,
                ref,
                icon: Icons.auto_awesome,
                title: "AI Assistant",
              ),

              const Divider(
                color: Colors.white24,
                height: 30,
              ),

              _menu(
                context,
                ref,
                icon: Icons.settings,
                title: "Settings",
              ),

              _menu(
                context,
                ref,
                icon: Icons.logout,
                title: "Logout",
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        onTap: () async {
          Navigator.pop(context);

          switch (title) {
            case "Dashboard":
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                ),
              );
              break;

            case "Visitors":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VisitorListScreen(),
                ),
              );
              break;

            case "Guard Scanner":
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const GuardDashboardScreen(),
    ),
  );
  break;

            case "Deliveries":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeliveryDashboardScreen(),
                ),
              );
              break;

            case "Logout":
              await ref.read(authProvider.notifier).logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => const LoginScreen(),
  ),
  (_) => false,
);
              break;

            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$title module is coming soon."),
                ),
              );
          }
        },
      ),
    );
  }
}