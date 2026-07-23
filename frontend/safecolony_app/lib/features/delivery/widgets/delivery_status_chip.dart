import 'package:flutter/material.dart';

class DeliveryStatusChip extends StatelessWidget {

  final String status;

  const DeliveryStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    Color color;

    switch (status) {

      case "COLLECTED":
        color = Colors.green;
        break;

      case "NOTIFIED":
        color = Colors.orange;
        break;

      case "REJECTED":
        color = Colors.red;
        break;

      default:
        color = Colors.blue;
    }

    return Chip(

      backgroundColor: color.withValues(alpha: .12),

      label: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}