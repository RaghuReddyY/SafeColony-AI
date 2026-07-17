import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../models/guard_dashboard.dart';

class ExpectedVisitorCard extends StatelessWidget {
  final ExpectedVisitor visitor;
  final VoidCallback? onDetails;
  final VoidCallback? onScan;

  const ExpectedVisitorCard({
    super.key,
    required this.visitor,
    this.onDetails,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                child: Icon(Icons.person),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.visitorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      visitor.visitorType,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              _statusChip(visitor.status),
            ],
          ),

          const SizedBox(height: 20),

          _row(Icons.phone, visitor.phone),

          if (visitor.purpose != null)
            _row(
              Icons.assignment,
              visitor.purpose!,
            ),

          if (visitor.vehicleNumber != null)
            _row(
              Icons.directions_car,
              visitor.vehicleNumber!,
            ),

          if (visitor.expectedTime != null)
            _row(
              Icons.schedule,
              visitor.expectedTime!,
            ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text("Details"),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Scan QR"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "APPROVED":
        color = Colors.blue;
        break;

      case "CHECKED_IN":
        color = Colors.green;
        break;

      case "CHECKED_OUT":
        color = Colors.grey;
        break;

      case "REJECTED":
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}