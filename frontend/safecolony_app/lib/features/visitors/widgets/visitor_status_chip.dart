import 'package:flutter/material.dart';

class VisitorStatusChip extends StatelessWidget {
  final String status;

  const VisitorStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case "APPROVED":
        color = Colors.green;
        break;

      case "PENDING":
        color = Colors.orange;
        break;

      case "REJECTED":
        color = Colors.red;
        break;

      case "CHECKED_IN":
        color = Colors.blue;
        break;

      case "CHECKED_OUT":
        color = Colors.grey;
        break;

      default:
        color = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}