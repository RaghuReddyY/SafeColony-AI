import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_tile.dart';
import '../../../../shared/widgets/app_section_title.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onScanQR;
  final VoidCallback onDelivery;
  final VoidCallback onWalkIn;
  final VoidCallback onEmergency;

  /// Responsive columns passed from dashboard
  final int crossAxisCount;

  const QuickActionsSection({
    super.key,
    required this.onScanQR,
    required this.onDelivery,
    required this.onWalkIn,
    required this.onEmergency,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: "Quick Actions",
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          itemCount: 4,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,

            crossAxisSpacing: 16,

            mainAxisSpacing: 16,

            childAspectRatio:
                crossAxisCount == 4
                    ? 2.6
                    : 2.0,
          ),

          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return ActionTile(
                  icon: Icons.qr_code_scanner,
                  title: "Scan QR",
                  subtitle: "Validate Visitor",
                  color: Colors.indigo,
                  onTap: onScanQR,
                );

              case 1:
                return ActionTile(
                  icon: Icons.person_add_alt_1,
                  title: "Walk-In",
                  subtitle: "Register Visitor",
                  color: Colors.green,
                  onTap: onWalkIn,
                );

              case 2:
                return ActionTile(
                  icon: Icons.inventory_2_outlined,
                  title: "Deliveries",
                  subtitle: "Manage Deliveries",
                  color: Colors.orange,
                  onTap: onDelivery,
                );

              default:
                return ActionTile(
                  icon: Icons.warning_amber_rounded,
                  title: "Emergency",
                  subtitle: "Raise SOS",
                  color: Colors.red,
                  onTap: onEmergency,
                );
            }
          },
        ),
      ],
    );
  }
}