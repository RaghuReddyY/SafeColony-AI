import 'package:flutter/material.dart';

class AppStatusChip extends StatelessWidget {
  final String status;

  const AppStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();

    Color color;

    switch (upper) {
      case 'APPROVED':
        color = Colors.green;
        break;

      case 'CHECKED_IN':
        color = Colors.orange;
        break;

      case 'CHECKED_OUT':
        color = Colors.grey;
        break;

      case 'PENDING':
        color = Colors.blue;
        break;

      case 'REJECTED':
        color = Colors.red;
        break;

      default:
        color = Colors.black54;
    }

    return Chip(
      label: Text(
        upper.replaceAll('_', ' '),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}