import 'package:flutter/material.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

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
              context,
              Icons.qr_code_scanner,
              "Scan QR",
              Colors.indigo,
              () {
                Navigator.pushNamed(
                  context,
                  "/guard",
                );
              },
            ),

            _actionButton(
              context,
              Icons.inventory_2,
              "Delivery",
              Colors.orange,
              () {
                _comingSoon(context);
              },
            ),

            _actionButton(
              context,
              Icons.person_add,
              "Walk-In",
              Colors.green,
              () {
                _comingSoon(context);
              },
            ),

            _actionButton(
              context,
              Icons.warning_amber,
              "Emergency",
              Colors.red,
              () {
                _comingSoon(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
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
          mainAxisAlignment:
              MainAxisAlignment.center,

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

  void _comingSoon(BuildContext context) {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(
        content: Text(
          "Coming in next sprint 🚀",
        ),
      ),
    );
  }
}