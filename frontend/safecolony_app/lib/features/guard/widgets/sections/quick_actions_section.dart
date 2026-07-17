import 'package:flutter/material.dart';

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
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2.5,
          children: [
            _actionButton(
              icon: Icons.qr_code_scanner,
              title: "Scan QR",
              color: Colors.indigo,
              onTap: onScanQR,
            ),
            _actionButton(
              icon: Icons.inventory_2,
              title: "Delivery",
              color: Colors.orange,
              onTap: onDelivery,
            ),
            _actionButton(
              icon: Icons.person_add,
              title: "Walk-In",
              color: Colors.green,
              onTap: onWalkIn,
            ),
            _actionButton(
              icon: Icons.warning_amber,
              title: "Emergency",
              color: Colors.red,
              onTap: onEmergency,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: .18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}