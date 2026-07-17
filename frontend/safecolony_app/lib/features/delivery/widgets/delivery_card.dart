import 'package:flutter/material.dart';

import '../models/delivery.dart';
import 'delivery_status_chip.dart';

class DeliveryCard extends StatelessWidget {

  final Delivery delivery;

  final VoidCallback onTap;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 1,

      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      child: InkWell(

        onTap: onTap,

        borderRadius:
            BorderRadius.circular(12),

        child: Padding(

          padding: const EdgeInsets.all(18),

          child: Row(

            children: [

              Container(

                width: 55,

                height: 55,

                decoration: BoxDecoration(

                  color: Colors.orange
                      .withOpacity(.15),

                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.orange,
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
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      delivery.deliveryCategory,
                    ),

                    const SizedBox(height: 10),

                    DeliveryStatusChip(
                      status:
                          delivery.status,
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}