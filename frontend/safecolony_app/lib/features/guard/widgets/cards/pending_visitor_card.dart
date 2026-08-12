import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_status_chip.dart';

import '../../models/guard_visitor.dart';

class PendingVisitorCard extends StatelessWidget {
  final GuardVisitor visitor;

  const PendingVisitorCard({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {
    final bool residentCreated =
        visitor.isResidentCreated;

    return AppCard(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const CircleAvatar(
                child: Icon(Icons.person),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.visitorName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    Text(
                      visitor.phone,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              AppStatusChip(
                status: visitor.status,
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            'Purpose : ${visitor.purpose}',
          ),

          if (visitor.vehicleNumber
              .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 8,
              ),
              child: Text(
                'Vehicle : ${visitor.vehicleNumber}',
              ),
            ),

          const SizedBox(
            height: 16,
          ),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration:
                BoxDecoration(
              color: residentCreated
                  ? Colors.green.withValues(
                      alpha: .10,
                    )
                  : Colors.orange.withValues(
                      alpha: .10,
                    ),
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                Icon(
                  residentCreated
                      ? Icons.verified
                      : Icons.hourglass_top,

                  color: residentCreated
                      ? Colors.green
                      : Colors.orange,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    residentCreated
                        ? 'Visitor created by resident. Please complete the authorized entry process.'
                        : 'Waiting for resident approval. Guard cannot approve a walk-in visitor.',
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