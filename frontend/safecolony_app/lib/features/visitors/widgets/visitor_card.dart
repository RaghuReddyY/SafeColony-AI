import 'package:flutter/material.dart';

import '../models/visitor.dart';
import '../screens/visitor_detail_screen.dart';
import 'visitor_status_chip.dart';
import '../screens/visitor_qr_screen.dart';

class VisitorCard extends StatelessWidget {
  final Visitor visitor;

  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRefresh;

  const VisitorCard({
    super.key,
    required this.visitor,
    this.onApprove,
    this.onReject,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        visitor.phone,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                VisitorStatusChip(
                  status: visitor.status,
                ),
              ],
            ),

            const SizedBox(height: 18),

            _info(
              Icons.badge,
              "Type",
              visitor.visitorType,
            ),

            if (visitor.purpose != null)
              _info(
                Icons.assignment,
                "Purpose",
                visitor.purpose!,
              ),

            if (visitor.vehicleNumber != null)
              _info(
                Icons.directions_car,
                "Vehicle",
                visitor.vehicleNumber!,
              ),

            const SizedBox(height: 20),

            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _info(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [

          Icon(
            icon,
            size: 18,
            color: Colors.grey,
          ),

          const SizedBox(width: 8),

          Text(
            "$title : ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {

    switch (visitor.status) {

      case "PENDING":

        return Row(
          children: [

            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Approve"),
                onPressed: onApprove,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                icon: const Icon(Icons.close),
                label: const Text("Reject"),
                onPressed: onReject,
              ),
            ),

            const SizedBox(width: 10),

            IconButton(
              tooltip: "Details",
              icon: const Icon(Icons.info),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VisitorDetailScreen(
                      visitor: visitor,
                    ),
                  ),
                );
              },
            ),
          ],
        );

      case "APPROVED":

        return Row(
          children: [

            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text("View QR"),
                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VisitorQRScreen(
                        visitor: visitor,
                       ),
                    ),
                 );

              },
              ),
            ),

            const SizedBox(width: 10),

            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VisitorDetailScreen(
                      visitor: visitor,
                    ),
                  ),
                );
              },
            ),
          ],
        );

      case "CHECKED_IN":

      case "CHECKED_OUT":

      case "REJECTED":

        return Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            icon: const Icon(Icons.info),
            label: const Text("Details"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VisitorDetailScreen(
                    visitor: visitor,
                  ),
                ),
              );
            },
          ),
        );

      default:

        return const SizedBox();
    }
  }
}