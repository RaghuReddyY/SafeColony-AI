import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/guard_visitor.dart';
import '../../providers/guard_visitor_provider.dart';
import '../../screens/qr_scanner_screen.dart';

class ApprovedVisitorCard extends ConsumerWidget {
  final GuardVisitor visitor;

  final VoidCallback? onDetails;

  const ApprovedVisitorCard({
    super.key,
    required this.visitor,
    this.onDetails,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final isResidentCreated =
        visitor.isResidentCreated;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  child: const Icon(
                    Icons.person,
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
                        isResidentCreated
                            ? "Resident-created visitor"
                            : "Walk-in visitor",
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "APPROVED",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ====================================================
            // DETAILS
            // ====================================================

            _InfoRow(
              icon: Icons.phone,
              text: visitor.phone,
            ),

            if (visitor.purpose.isNotEmpty)
              _InfoRow(
                icon: Icons.assignment,
                text: visitor.purpose,
              ),

            if (visitor.vehicleNumber.isNotEmpty)
              _InfoRow(
                icon: Icons.directions_car,
                text: visitor.vehicleNumber,
              ),

            const Spacer(),

            const SizedBox(height: 12),

            // ====================================================
            // ACTIONS
            // ====================================================

            if (isResidentCreated)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(
                        Icons.visibility_outlined,
                      ),
                      label:
                          const Text("Details"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const QRScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.qr_code_scanner,
                      ),
                      label:
                          const Text("Scan QR"),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await _checkIn(
                      context,
                      ref,
                    );
                  },
                  icon: const Icon(
                    Icons.login,
                  ),
                  label:
                      const Text("CHECK IN"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkIn(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              const Text("Check In Visitor"),
          content: Text(
            "Check in ${visitor.visitorName}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
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

    if (confirm != true) {
      return;
    }

    try {
      await ref
          .read(
            guardVisitorProvider.notifier,
          )
          .checkIn(visitor.id);

      if (!context.mounted) return;

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
    } catch (e) {
      if (!context.mounted) return;

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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}