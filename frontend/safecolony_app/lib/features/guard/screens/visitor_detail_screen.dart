import 'package:flutter/material.dart';

import '../models/guard_visitor.dart';
import 'qr_scanner_screen.dart';

class GuardVisitorDetailScreen extends StatelessWidget {
  final GuardVisitor visitor;

  const GuardVisitorDetailScreen({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context) {
    final desktop =
        MediaQuery.of(context).size.width > 850;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor Details"),
      ),
      backgroundColor: const Color(0xffF5F7FB),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: desktop
                ? _desktopLayout(context)
                : _mobileLayout(context),
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Expanded(
          flex: 3,
          child: _profileCard(context),
        ),

        const SizedBox(width: 24),

        Expanded(
          flex: 4,
          child: Column(
            children: [

              _visitDetails(),

              const SizedBox(height: 20),

              _actionCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Column(
      children: [

        _profileCard(context),

        const SizedBox(height: 20),

        _visitDetails(),

        const SizedBox(height: 20),

        _actionCard(context),
      ],
    );
  }

  Widget _profileCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            CircleAvatar(
              radius: 45,
              backgroundColor:
                  Colors.indigo.shade100,
              child: const Icon(
                Icons.person,
                size: 48,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              visitor.visitorName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              visitor.visitorType,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 18),

            Chip(
              avatar: const Icon(
                Icons.verified,
                color: Colors.white,
                size: 18,
              ),
              backgroundColor:
                  Colors.green,
              label: Text(
                visitor.status,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visitDetails() {
    return Card(
      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              "Visit Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _info(
              Icons.phone,
              "Phone",
              visitor.phone,
            ),

            _info(
              Icons.assignment,
              "Purpose",
              visitor.purpose ?? "-",
            ),

            _info(
              Icons.directions_car,
              "Vehicle",
              visitor.vehicleNumber ??
                  "-",
            ),

            _info(
              Icons.schedule,
              "Expected Time",
              visitor.expectedAt == null
                  ? "-"
                  : visitor.expectedAt!.toLocal().toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context) {
    return Card(
      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Actions",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(
                  Icons.qr_code_scanner,
                ),
                label: const Text(
                  "Scan QR",
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QRScannerScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.call,
                ),
                label: const Text(
                  "Call Visitor",
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.message,
                ),
                label: const Text(
                  "Send SMS",
                ),
                onPressed: () {},
              ),
            ),
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
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [

          CircleAvatar(
            radius: 20,
            backgroundColor:
                Colors.indigo.shade50,
            child: Icon(
              icon,
              color: Colors.indigo,
              size: 20,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 16,
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