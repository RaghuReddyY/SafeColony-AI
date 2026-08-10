import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_status_chip.dart';
import '../../models/guard_visitor.dart';

class PendingVisitorCard extends StatelessWidget {
  final GuardVisitor visitor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PendingVisitorCard({
    super.key,
    required this.visitor,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const CircleAvatar(
                child: Icon(Icons.person),
              ),

              const SizedBox(width: 12),

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

                    Text(visitor.phone),
                  ],
                ),
              ),

              AppStatusChip(
                status: visitor.status,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            "Purpose : ${visitor.purpose}",
          ),

          if (visitor.vehicleNumber != null)
            Padding(
              padding:
                  const EdgeInsets.only(top: 8),
              child: Text(
                "Vehicle : ${visitor.vehicleNumber}",
              ),
            ),

          const Spacer(),

          Row(
            children: [

              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}