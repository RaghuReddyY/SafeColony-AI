import 'package:flutter/material.dart';

import 'quick_action_card.dart';
import '../../visitors/screens/visitor_list_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../emergency/screens/emergency_sos_screen.dart';
import '../../vacation/screens/vacation_screen.dart';
import '../../complaints/screens/complaint_screen.dart';
import '../../incidents/screens/incident_screen.dart';
import '../../amenities/screens/amenity_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Four columns are useful on desktop, but four very narrow
        // tiles make labels wrap vertically on phones. Two columns
        // give each action enough room to be read and tapped.
        final columns = constraints.maxWidth >= 900 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 1.35 : 1.45,
          children: [
            QuickActionCard(
              icon: Icons.person_add_alt_1,
              title: 'Visitors',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VisitorListScreen(),
                ),
              ),
            ),
            QuickActionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Deliveries',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeliveryDashboardScreen(),
                ),
              ),
            ),
            QuickActionCard(
              icon: Icons.beach_access,
              title: 'Vacation',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VacationScreen()),
              ),
            ),
            QuickActionCard(
              icon: Icons.support_agent,
              title: 'Complaints',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintScreen()),
              ),
            ),
            QuickActionCard(
              icon: Icons.report_problem_outlined,
              title: 'Incidents',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncidentScreen()),
              ),
            ),
            QuickActionCard(
              icon: Icons.emergency_outlined,
              title: 'Emergency',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencySOSScreen()),
              ),
            ),
            QuickActionCard(
              icon: Icons.pool_outlined,
              title: 'Amenities',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AmenityScreen()),
              ),
            ),
            QuickActionCard(
              icon: Icons.storefront_rounded,
              title: 'Marketplace',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              ),
            ),
          ],
        );
      },
    );
  }
}
