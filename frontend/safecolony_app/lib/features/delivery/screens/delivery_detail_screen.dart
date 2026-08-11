import 'package:flutter/material.dart';

import '../models/delivery.dart';

class DeliveryDetailScreen extends StatelessWidget {
  final Delivery delivery;

  const DeliveryDetailScreen({
    super.key,
    required this.delivery,
  });

  Color getStatusColor() {
    switch (delivery.status.toUpperCase()) {
      case "COLLECTED":
        return Colors.green;
      case "NOTIFIED":
      case "ARRIVED":
        return Colors.orange;
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otp = delivery.otp;
    final isCollected =
        delivery.status.toUpperCase() == "COLLECTED";

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Delivery Details"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.orange,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              delivery.courierName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(delivery.deliveryCategory),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 35),
                  infoRow(
                    "Tracking",
                    delivery.trackingNumber ?? "-",
                  ),
                  infoRow("Priority", delivery.priority),
                  infoRow("Status", delivery.status),
                  infoRow(
                    "Received By",
                    delivery.receivedBy ?? "-",
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Chip(
                      backgroundColor:
                          getStatusColor().withValues(alpha: .15),
                      label: Text(
                        delivery.status,
                        style: TextStyle(
                          color: getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // =====================================================
          // Resident OTP
          // =====================================================
          if (!isCollected)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 34,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Collection OTP",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Share this OTP with the security guard when collecting your package.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          otp?.isNotEmpty == true ? otp! : "------",
                          style: const TextStyle(
                            fontSize: 32,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (otp == null || otp.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "OTP is not available in this response. Refresh the delivery list.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Package has already been collected.",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // A resident must NOT see the guard's "Collect Package"
          // action. The guard enters the OTP in the guard module.
          if (!isCollected)
            const Text(
              "Give the OTP to the security guard when you collect the package.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
