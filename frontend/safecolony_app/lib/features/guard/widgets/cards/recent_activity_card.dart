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
        return Icons.login;

      case "logout":
        return Icons.logout;

      case "verified":
        return Icons.verified;

      default:
        return Icons.history;
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
    return AppCard(
      child: Row(
        children: [

          CircleAvatar(
            backgroundColor:
                _getColor().withValues(alpha: .12),
            child: Icon(
              _getIcon(),
              color: _getColor(),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}