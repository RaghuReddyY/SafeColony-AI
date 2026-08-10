import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';

class DashboardStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const DashboardStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth > 220;

        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: desktop
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          color.withOpacity(.12),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            value,
                            style: theme
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            label,
                            style: theme
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          color.withOpacity(.12),
                      child: Icon(
                        icon,
                        color: color,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      value,
                      style: theme
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      label,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        );
      },
    );
  }
}