import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_tile.dart';
import '../../../../shared/widgets/app_section_title.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onScanQR;
  final VoidCallback onDelivery;
  final VoidCallback onWalkIn;
  final VoidCallback onEmergency;

  const QuickActionsSection({
    super.key,
    required this.onScanQR,
    required this.onDelivery,
    required this.onWalkIn,
    required this.onEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: "Quick Actions",
        ),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            ActionTile(
              icon: Icons.qr_code_scanner,
              title: "Scan QR",
              subtitle: "Validate visitor",
              color: Colors.indigo,
              onTap: onScanQR,
            ),

            ActionTile(
              icon: Icons.person_add_alt_1,
              title: "Walk-In",
              subtitle: "Register visitor",
              color: Colors.green,
              onTap: onWalkIn,
            ),

            ActionTile(
              icon: Icons.inventory_2_outlined,
              title: "Delivery",
              subtitle: "Manage deliveries",
              color: Colors.orange,
              onTap: onDelivery,
            ),

            ActionTile(
              icon: Icons.warning_amber_rounded,
              title: "Emergency",
              subtitle: "Raise SOS",
              color: Colors.red,
              onTap: onEmergency,
            ),
          ],
        ),
      ],
    );
  }
}