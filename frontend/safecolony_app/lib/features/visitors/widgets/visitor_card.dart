import 'package:flutter/material.dart';

import '../models/visitor.dart';
import 'visitor_status_chip.dart';

class VisitorCard extends StatelessWidget {
  final Visitor visitor;

  const VisitorCard({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    visitor.visitorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                VisitorStatusChip(
                  status: visitor.status,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              "Type : ${visitor.visitorType}",
            ),

            const SizedBox(height: 5),

            Text(
              "Phone : ${visitor.phone}",
            ),

            if (visitor.purpose != null) ...[
              const SizedBox(height: 5),
              Text(
                "Purpose : ${visitor.purpose}",
              ),
            ],

            if (visitor.vehicleNumber != null) ...[
              const SizedBox(height: 5),
              Text(
                "Vehicle : ${visitor.vehicleNumber}",
              ),
            ],

            const SizedBox(height: 18),

            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code),
                  label: const Text("QR"),
                ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info),
                  label: const Text("Details"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}