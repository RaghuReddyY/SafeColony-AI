import 'package:flutter/material.dart';

import '../models/delivery.dart';
import '../widgets/otp_dialog.dart';

class DeliveryDetailScreen extends StatelessWidget {
  final Delivery delivery;

  const DeliveryDetailScreen({
    super.key,
    required this.delivery,
  });

  Color getStatusColor() {
    switch (delivery.status) {
      case "COLLECTED":
        return Colors.green;

      case "NOTIFIED":
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
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Delivery Details",
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [

          Card(
            elevation: 1,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Padding(
              padding:
                  const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      Container(
                        height: 60,
                        width: 60,

                        decoration: BoxDecoration(
                          color: Colors.orange
                              .withValues(alpha: .15),

                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
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
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(
                              delivery.courierName,
                              style:
                                  const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height: 4),

                            Text(
                              delivery
                                  .deliveryCategory,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(
                    height: 35,
                  ),

                  infoRow(
                    "Tracking",
                    delivery.trackingNumber ??
                        "-",
                  ),

                  infoRow(
                    "Priority",
                    delivery.priority,
                  ),

                  infoRow(
                    "Status",
                    delivery.status,
                  ),

                  infoRow(
                    "Received By",
                    delivery.receivedBy ??
                        "-",
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Center(
                    child: Chip(
                      backgroundColor:
                          getStatusColor()
                              .withValues(alpha: .15),

                      label: Text(
                        delivery.status,

                        style: TextStyle(
                          color:
                              getStatusColor(),

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          if (delivery.status !=
              "COLLECTED")

            SizedBox(
              height: 55,

              child: ElevatedButton.icon(

                icon: const Icon(
                  Icons.check_circle,
                ),

                label: const Text(
                  "Collect Package",
                ),

                onPressed: () async {

                  final result =
                      await showDialog<bool>(

                    context: context,

                    barrierDismissible:
                        false,

                    builder: (_) =>
                        OTPDialog(
                      deliveryId:
                          delivery.id,
                    ),
                  );

                  if (result == true &&
                      context.mounted) {

                    Navigator.pop(
                      context,
                      true,
                    );
                  }
                },
              ),
            )

          else

            SizedBox(
              height: 55,

              child: ElevatedButton.icon(

                onPressed: null,

                icon: const Icon(
                  Icons.check,
                ),

                label: const Text(
                  "Package Already Collected",
                ),
              ),
            ),
        ],
      ),
    );
  }
}