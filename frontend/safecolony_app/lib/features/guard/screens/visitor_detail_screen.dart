import 'package:flutter/material.dart';

import '../models/guard_dashboard.dart';

class GuardVisitorDetailScreen extends StatelessWidget {

  final ExpectedVisitor visitor;

  const GuardVisitorDetailScreen({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Visitor Details",
        ),
      ),

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          Card(

            child: Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                children: [

                  const CircleAvatar(
                    radius: 40,
                    child: Icon(
                      Icons.person,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    visitor.visitorName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Chip(
                    label: Text(
                      visitor.status,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _tile(
            Icons.phone,
            "Phone",
            visitor.phone,
          ),

          _tile(
            Icons.badge,
            "Visitor Type",
            visitor.visitorType,
          ),

          if (visitor.purpose != null)

            _tile(
              Icons.assignment,
              "Purpose",
              visitor.purpose!,
            ),

          if (visitor.vehicleNumber != null)

            _tile(
              Icons.directions_car,
              "Vehicle",
              visitor.vehicleNumber!,
            ),

          if (visitor.expectedTime != null)

            _tile(
              Icons.schedule,
              "Expected Time",
              visitor.expectedTime!,
            ),

          const SizedBox(height: 30),

          FilledButton.icon(

            icon: const Icon(
              Icons.qr_code_scanner,
            ),

            label: const Text(
              "Scan QR",
            ),

            onPressed: () {

              Navigator.pushNamed(
                context,
                "/guard",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String value,
  ) {

    return Card(

      child: ListTile(

        leading: Icon(icon),

        title: Text(title),

        subtitle: Text(value),
      ),
    );
  }
}