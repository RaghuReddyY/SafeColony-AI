import 'package:flutter/material.dart';

import '../models/visitor.dart';
import '../widgets/visitor_status_chip.dart';

class VisitorDetailScreen extends StatelessWidget {
  final Visitor visitor;

  const VisitorDetailScreen({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Center(
                  child: CircleAvatar(
                    radius: 45,
                    child: Icon(Icons.person, size: 40),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: Text(
                    visitor.visitorName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: VisitorStatusChip(
                    status: visitor.status,
                  ),
                ),

                const SizedBox(height: 30),

                _info("Phone", visitor.phone),

                _info("Type", visitor.visitorType),

                _info(
                  "Purpose",
                  visitor.purpose ?? "-",
                ),

                _info(
                  "Vehicle",
                  visitor.vehicleNumber ?? "-",
                ),

                const SizedBox(height: 35),

                Row(
                  children: [

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          // Sprint 3.5
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          // Sprint 3.5
                        },
                        icon: const Icon(Icons.close),
                        label: const Text("Reject"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Sprint 3.6
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text("View QR"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}