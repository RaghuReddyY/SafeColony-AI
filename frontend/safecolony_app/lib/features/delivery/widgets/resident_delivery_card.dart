import 'package:flutter/material.dart';

import '../models/delivery.dart';

class ResidentDeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;

  const ResidentDeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
  });

  Color _statusColor() {
    switch (delivery.status.toUpperCase()) {
      case "COLLECTED":
        return Colors.green;

      case "ARRIVED":
        return Colors.orange;

      case "PENDING":
        return Colors.blue;

      case "REJECTED":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.inventory_2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.courierName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery.deliveryCategory,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor:
                        statusColor.withValues(alpha: .15),
                    label: Text(
                      delivery.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _row(
                "Tracking",
                delivery.trackingNumber?.isNotEmpty == true
                    ? delivery.trackingNumber!
                    : "-",
              ),

              _row(
                "Priority",
                delivery.priority,
              ),

              _row(
  "Created",
  "${delivery.createdAt.day.toString().padLeft(2, '0')}-"
  "${delivery.createdAt.month.toString().padLeft(2, '0')}-"
  "${delivery.createdAt.year}",
),

              if (delivery.collectedAt != null)
  _row(
    "Collected",
    "${delivery.collectedAt!.day.toString().padLeft(2, '0')}-"
    "${delivery.collectedAt!.month.toString().padLeft(2, '0')}-"
    "${delivery.collectedAt!.year}",
  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}