import 'package:flutter/material.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: const Color(0xff1E293B),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff4F46E5),
                    Color(0xff2563EB),
                  ],
                ),
              ),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Raghunatha Reddy",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Resident",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _menu(Icons.dashboard, "Dashboard", true),
            _menu(Icons.people, "Visitors", false),
            _menu(Icons.inventory_2, "Deliveries", false),
            _menu(Icons.beach_access, "Vacation", false),
            _menu(Icons.notifications, "Notifications", false),
            _menu(Icons.auto_awesome, "AI Assistant", false),

            const Spacer(),

            const Divider(color: Colors.white24),

            _menu(Icons.settings, "Settings", false),
            _menu(Icons.logout, "Logout", false),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _menu(
      IconData icon,
      String title,
      bool selected,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: .12)
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
        onTap: () {},
      ),
    );
  }
}