import 'package:flutter/material.dart';
import 'resident_approval_screen.dart';
import '../property/screens/property_list_screen.dart';
import '../section/screens/section_list_screen.dart';
import '../unit/screens/unit_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../guard/screens/guard_list_screen.dart';


class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResidentApprovalScreen(),
                      ),
                    );
                  },
              ),
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(Icons.apartment),
                title: const Text("Property Management"),
                subtitle: const Text(
                  "Create, update and manage properties",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PropertyListScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),
            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Section Management"),
                subtitle: const Text(
                  "Create, update and manage sections",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SectionListScreen(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.home_work),
                title: const Text("Unit Management"),
                subtitle: const Text(
                  "Create, update and manage units",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UnitListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
Card(
  child: ListTile(
    leading: const Icon(Icons.security),
    title: const Text("Security Guards"),
    subtitle: const Text(
      "Create and manage security guards",
    ),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GuardListScreen(),
        ),
      );
    },
  ),
),
           Card(
  child: ListTile(
    leading: const Icon(Icons.logout),
    title: const Text("Logout"),
    onTap: () async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text("Logout"),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;

      await ref.read(authProvider.notifier).logout();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => const LoginScreen(),
  ),
  (route) => false,
);
    },
  ),
),
          ],
        ),
      ),
    );
  }
}