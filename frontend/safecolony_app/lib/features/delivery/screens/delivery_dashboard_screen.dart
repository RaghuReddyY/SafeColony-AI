import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery.dart';
import '../providers/delivery_provider.dart';

import '../widgets/delivery_card.dart';

import 'add_delivery_screen.dart';
import 'delivery_detail_screen.dart';

class DeliveryDashboardScreen
    extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen>
      createState() =>
          _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState
    extends ConsumerState<
        DeliveryDashboardScreen> {
  late Future<List<Delivery>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref
        .read(deliveryProvider)
        .loadDeliveries();
  }

  Future<void> _refresh() async {
    setState(() {
      _load();
    });

    await _future;
  }

  Future<void> _addDelivery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddDeliveryScreen(),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  Future<void> _openDelivery(
      Delivery delivery) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeliveryDetailScreen(
          delivery: delivery,
        ),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        title:
            const Text("Delivery Dashboard"),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addDelivery,
        icon: const Icon(Icons.add),
        label: const Text("Register"),
      ),

      body: FutureBuilder<List<Delivery>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final deliveries =
              snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [

                  SizedBox(height: 120),

                  Icon(
                    Icons.inventory_2_outlined,
                    size: 90,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 20),

                  Center(
                    child: Text(
                      "No Deliveries",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  Center(
                    child: Text(
                      "Tap Register to add a delivery",
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  deliveries.length,
              itemBuilder:
                  (context, index) {
                return DeliveryCard(
                  delivery:
                      deliveries[index],
                  onTap: () =>
                      _openDelivery(
                    deliveries[index],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}