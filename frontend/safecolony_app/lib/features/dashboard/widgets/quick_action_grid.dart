import 'package:flutter/material.dart';

import 'quick_action_card.dart';
import '../../visitors/screens/visitor_list_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: .95,
      children: [

        QuickActionCard(
          icon: Icons.person_add_alt_1,
          title: "Visitor",
          onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const VisitorListScreen(),
    ),
  );
}
        ),

        QuickActionCard(
          icon: Icons.inventory,
          title: "Delivery",
          onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DeliveryDashboardScreen(),
    ),
  );
}
        ),

        QuickActionCard(
          icon: Icons.beach_access,
          title: "Vacation",
          onTap: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Vacation module coming soon"),
    ),
  );
}
        ),

        QuickActionCard(
          icon: Icons.warning_amber,
          title: "Emergency",
          onTap: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Emergency module coming soon"),
    ),
  );
}
        ),
      ],
    );
  }
}