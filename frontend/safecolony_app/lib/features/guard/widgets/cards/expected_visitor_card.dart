import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_status_chip.dart';
import '../../../../shared/widgets/info_tile.dart';

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
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //------------------------------------------------------------------
          // Header
          //------------------------------------------------------------------

          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.visitorName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      visitor.visitorType,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              AppStatusChip(
                status: visitor.status,
              ),
            ],
          ),

          const SizedBox(height: 20),

          //------------------------------------------------------------------
          // Details
          //------------------------------------------------------------------

          InfoTile(
            icon: Icons.phone,
            title: "Phone",
            value: visitor.phone,
          ),

          if (visitor.purpose != null) ...[
            const Divider(),
            InfoTile(
              icon: Icons.assignment,
              title: "Purpose",
              value: visitor.purpose!,
            ),
          ],

          if (visitor.vehicleNumber != null) ...[
            const Divider(),
            InfoTile(
              icon: Icons.directions_car,
              title: "Vehicle",
              value: visitor.vehicleNumber!,
            ),
          ],

          if (visitor.expectedTime != null) ...[
            const Divider(),
            InfoTile(
              icon: Icons.schedule,
              title: "Expected Time",
              value: visitor.expectedTime!,
            ),
          ],

          const SizedBox(height: 24),

          //------------------------------------------------------------------
          // Buttons
          //------------------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text("Details"),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: AppPrimaryButton(
                  text: "Scan QR",
                  icon: Icons.qr_code_scanner,
                  onPressed: onScan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}