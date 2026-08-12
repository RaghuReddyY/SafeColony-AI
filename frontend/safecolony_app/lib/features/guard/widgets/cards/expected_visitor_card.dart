import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_status_chip.dart';

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
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 500;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //---------------------------------------------------
              // HEADER
              //---------------------------------------------------

              Row(
                children: [

                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          visitor.visitorType,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
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

              const SizedBox(height: 18),

              //---------------------------------------------------
              // DETAILS
              //---------------------------------------------------

              _RowItem(
                icon: Icons.phone,
                text: visitor.phone,
              ),

              if (visitor.purpose != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: _RowItem(
                    icon: Icons.assignment,
                    text: visitor.purpose!,
                  ),
                ),

              if (visitor.vehicleNumber != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: _RowItem(
                    icon: Icons.directions_car,
                    text:
                        visitor.vehicleNumber!,
                  ),
                ),

              if (visitor.expectedTime != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: _RowItem(
                    icon: Icons.schedule,
                    text:
                        visitor.expectedTime!,
                  ),
                ),

              const Spacer(),

              //---------------------------------------------------
              // BUTTONS
              //---------------------------------------------------

              if (desktop)

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.visibility,
                        ),
                        label:
                            const Text("Details"),
                        onPressed: onDetails,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: AppPrimaryButton(
                        text: "Scan",
                        icon:
                            Icons.qr_code_scanner,
                        onPressed: onScan,
                      ),
                    ),
                  ],
                )

              else

                Column(
                  children: [

                    SizedBox(
                      width: double.infinity,
                      child:
                          OutlinedButton.icon(
                        icon: const Icon(
                          Icons.visibility,
                        ),
                        label:
                            const Text("Details"),
                        onPressed: onDetails,
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        text: "Scan QR",
                        icon:
                            Icons.qr_code_scanner,
                        onPressed: onScan,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RowItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade700,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}