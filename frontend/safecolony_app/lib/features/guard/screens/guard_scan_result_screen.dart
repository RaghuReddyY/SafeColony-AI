import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/info_tile.dart';

import '../models/guard_scan_result.dart';
import '../providers/guard_provider.dart';
import '../providers/guard_visitor_provider.dart';

class GuardScanResultScreen extends ConsumerWidget {
  final GuardScanResult visitor;

  const GuardScanResultScreen({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state = ref.watch(guardProvider);

    final status =
        visitor.status.toUpperCase().trim();

    final isApproved =
        status == 'APPROVED';

    final isCheckedIn =
        status == 'CHECKED_IN';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Visitor Details",
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ==================================================
              // AVATAR
              // ==================================================

              CircleAvatar(
                radius: 45,
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // VISITOR NAME
              // ==================================================

              Text(
                visitor.visitorName,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // STATUS
              // ==================================================

              AppStatusChip(
                status: visitor.status,
              ),

              const SizedBox(height: 28),

              // ==================================================
              // INFORMATION
              // ==================================================

              AppCard(
                child: Column(
                  children: [
                    InfoTile(
                      icon: Icons.phone,
                      title: "Phone",
                      value: visitor.phone,
                    ),

                    const Divider(),

                    InfoTile(
                      icon: Icons.badge,
                      title: "Visitor Type",
                      value:
                          visitor.visitorType,
                    ),

                    if (visitor.purpose != null &&
                        visitor.purpose!
                            .trim()
                            .isNotEmpty) ...[
                      const Divider(),

                      InfoTile(
                        icon:
                            Icons.assignment,
                        title: "Purpose",
                        value:
                            visitor.purpose!,
                      ),
                    ],

                    if (visitor.vehicleNumber !=
                            null &&
                        visitor.vehicleNumber!
                            .trim()
                            .isNotEmpty) ...[
                      const Divider(),

                      InfoTile(
                        icon: Icons
                            .directions_car,
                        title: "Vehicle",
                        value:
                            visitor.vehicleNumber!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==================================================
              // CHECK IN
              // ==================================================

              if (isApproved)
                AppPrimaryButton(
                  text: "CHECK IN",
                  icon: Icons.login,
                  isLoading:
                      state.isLoading,
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await _checkIn(
                            context,
                            ref,
                          );
                        },
                ),

              // ==================================================
              // CHECK OUT
              // ==================================================

              if (isCheckedIn)
                AppPrimaryButton(
                  text: "CHECK OUT",
                  icon: Icons.logout,
                  isLoading:
                      state.isLoading,
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await _checkOut(
                            context,
                            ref,
                          );
                        },
                ),

              // ==================================================
              // OTHER STATUS
              // ==================================================

              if (!isApproved &&
                  !isCheckedIn)
                _StatusMessage(
                  status: visitor.status,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHECK IN
  // ============================================================

  Future<void> _checkIn(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Check In Visitor",
          ),
          content: Text(
            "Check in ${visitor.visitorName}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text("Check In"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(guardProvider.notifier)
          .checkIn();

      if (!context.mounted) {
        return;
      }

      // Refresh the visitor lists before leaving.
      await ref
          .read(
            guardVisitorProvider
                .notifier,
          )
          .loadAll(
            showLoading: false,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.green,
          content: Text(
            "${visitor.visitorName} checked in successfully.",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.red,
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<void> _checkOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Check Out Visitor",
          ),
          content: Text(
            "Check out ${visitor.visitorName}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text("Check Out"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(guardProvider.notifier)
          .checkOut();

      if (!context.mounted) {
        return;
      }

      await ref
          .read(
            guardVisitorProvider
                .notifier,
          )
          .loadAll(
            showLoading: false,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.green,
          content: Text(
            "${visitor.visitorName} checked out successfully.",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.red,
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }
}

// ================================================================
// STATUS MESSAGE
// ================================================================

class _StatusMessage
    extends StatelessWidget {
  final String status;

  const _StatusMessage({
    required this.status,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey
            .withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Visitor status: $status",
            ),
          ),
        ],
      ),
    );
  }
}