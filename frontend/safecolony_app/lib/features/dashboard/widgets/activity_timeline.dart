import 'package:flutter/material.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key});

  Widget item(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .15),
        child: Icon(icon, color: color),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      subtitle: Text(subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),

      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Recent Activity",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 20),

            item(
              Icons.check_circle,
              Colors.green,
              "Visitor Approved",
              "5 minutes ago",
            ),

            item(
              Icons.local_shipping,
              Colors.orange,
              "Amazon Package Arrived",
              "20 minutes ago",
            ),

            item(
              Icons.shield,
              Colors.blue,
              "Vacation Mode Enabled",
              "Today",
            ),
          ],
        ),
      ),
    );
  }
}