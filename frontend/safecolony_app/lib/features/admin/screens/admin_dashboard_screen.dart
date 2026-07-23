import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeColony AI"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Admin 👋",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Manage your community from one place.",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 40),

            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Resident Approvals"),
                subtitle: const Text("View and approve pending residents"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate in next step
                },
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () {
                  // Implement later
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}