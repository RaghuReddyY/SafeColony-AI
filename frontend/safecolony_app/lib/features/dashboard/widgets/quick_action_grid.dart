import 'package:flutter/material.dart';

import 'quick_action_card.dart';
import '../../visitors/screens/visitor_list_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../emergency/screens/emergency_sos_screen.dart';
import '../../vacation/screens/vacation_screen.dart';
import '../../complaints/screens/complaint_screen.dart';
import '../../incidents/screens/incident_screen.dart';
import '../../amenities/screens/amenity_screen.dart';

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VacationScreen()),
            );
          }
        ),

        QuickActionCard(
          icon: Icons.support_agent,
          title: "Complaint",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComplaintScreen()),
            );
          },
        ),

        QuickActionCard(
          icon: Icons.report_problem_outlined,
          title: "Incidents",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncidentScreen()),
            );
          },
        ),

        QuickActionCard(
          icon: Icons.pool,
          title: "Amenities",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmenityScreen()),
            );
          },
        ),

        QuickActionCard(
          icon: Icons.warning_amber,
          title: "Emergency",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmergencySOSScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}