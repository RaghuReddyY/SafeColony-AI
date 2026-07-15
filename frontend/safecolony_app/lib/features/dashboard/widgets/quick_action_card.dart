import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.indigo.shade50,
        ),
        child: Column(
          children: [

            Icon(
              icon,
              size: 34,
              color: Colors.indigo,
            ),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}