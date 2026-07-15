import 'package:flutter/material.dart';

import 'quick_action_card.dart';

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
          onTap: () {},
        ),

        QuickActionCard(
          icon: Icons.inventory,
          title: "Delivery",
          onTap: () {},
        ),

        QuickActionCard(
          icon: Icons.beach_access,
          title: "Vacation",
          onTap: () {},
        ),

        QuickActionCard(
          icon: Icons.warning_amber,
          title: "Emergency",
          onTap: () {},
        ),
      ],
    );
  }
}