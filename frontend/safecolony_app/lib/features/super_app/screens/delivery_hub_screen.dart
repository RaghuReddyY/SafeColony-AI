import 'package:flutter/material.dart';
import '../models/super_app.dart';
import '../services/super_app_service.dart';

class DeliveryHubScreen extends StatefulWidget {
  const DeliveryHubScreen({super.key});

  @override
  State<DeliveryHubScreen> createState() => _DeliveryHubScreenState();
}

class _DeliveryHubScreenState extends State<DeliveryHubScreen> {
  final api = SuperAppService();
  late Future<List<Parcel>> future;

  @override
  void initState() {
    super.initState();
    future = api.parcels();
  }

  void reload() => setState(() => future = api.parcels());

  Future<void> _pickup(Parcel parcel) async {
    try {
      await api.pickup(parcel.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcel picked up successfully.')));
      reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Main Gate Delivery Hub'),
          actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
        ),
        body: FutureBuilder<List<Parcel>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Unable to load parcels.\n${snapshot.error}')));
            final parcels = snapshot.data ?? const <Parcel>[];
            if (parcels.isEmpty) return const Center(child: Text('No community parcels are waiting at the hub.'));
            return RefreshIndicator(
              onRefresh: () async { reload(); await future; },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: parcels.length,
                itemBuilder: (_, index) {
                  final p = parcels[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                      title: Text(p.apartmentLabel),
                      subtitle: Text('${p.hub} • ${p.status}\nPickup code: ${p.pickupCode}'),
                      isThreeLine: true,
                      trailing: p.status == 'AT_HUB' ? FilledButton(onPressed: () => _pickup(p), child: const Text('Pickup')) : const Icon(Icons.check_circle),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
