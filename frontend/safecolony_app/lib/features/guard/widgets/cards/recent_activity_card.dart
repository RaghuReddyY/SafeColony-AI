import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';

class RecentActivityCard extends StatelessWidget {
  final String icon;
  final String title;
  final String time;

  const RecentActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
  });

  IconData _getIcon() {
    switch (icon) {
      case "login":
        return Icons.login_rounded;
      case "logout":
        return Icons.logout_rounded;
      case "verified":
        return Icons.verified_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _getColor() {
    switch (icon) {
      case "login":
        return Colors.green;
      case "logout":
        return Colors.red;
      case "verified":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor();

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(),
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Activity Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}