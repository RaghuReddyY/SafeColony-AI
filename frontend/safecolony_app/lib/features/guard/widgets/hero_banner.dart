import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';

class GuardHeroBanner extends StatelessWidget {
  final String greeting;
  final String guardName;
  final String colonyStatus;

  final int expectedVisitors;
  final int checkedInVisitors;
  final int deliveries;

  const GuardHeroBanner({
    super.key,
    required this.greeting,
    required this.guardName,
    required this.colonyStatus,
    required this.expectedVisitors,
    required this.checkedInVisitors,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.security,
                  color: Colors.green,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Welcome back, $guardName",
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 10,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          "Colony Status : $colonyStatus",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.people,
                  value: expectedVisitors.toString(),
                  label: "Visitors",
                  color: Colors.blue,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _StatTile(
                  icon: Icons.login,
                  value: checkedInVisitors.toString(),
                  label: "Inside",
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _StatTile(
                  icon: Icons.inventory_2,
                  value: deliveries.toString(),
                  label: "Delivery",
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}