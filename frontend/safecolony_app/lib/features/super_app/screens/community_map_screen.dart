import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/super_app.dart';

class CommunityMapScreen extends StatelessWidget {
  final List<MapPoint> points;
  const CommunityMapScreen({super.key, required this.points});

  Future<void> _openMap(BuildContext context, MapPoint point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Community Map')),
        backgroundColor: const Color(0xffF5F7FB),
        body: points.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No mapped community locations have been configured yet. Ask your community administrator to add the gate, blocks, amenities and delivery hub locations.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: points.length,
                itemBuilder: (context, index) {
                  final p = points[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(_iconFor(p.pointType)),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${p.pointType}${p.address == null || p.address!.isEmpty ? '' : '\n${p.address}'}\n${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Open in Maps',
                        icon: const Icon(Icons.directions_outlined),
                        onPressed: () => _openMap(context, p),
                      ),
                    ),
                  );
                },
              ),
      );

  IconData _iconFor(String type) {
    switch (type.toUpperCase()) {
      case 'GATE':
        return Icons.door_front_door_outlined;
      case 'BLOCK':
        return Icons.apartment_outlined;
      case 'AMENITY':
        return Icons.pool_outlined;
      case 'DELIVERY_HUB':
        return Icons.inventory_2_outlined;
      case 'VENDOR':
        return Icons.storefront_outlined;
      case 'INCIDENT':
        return Icons.warning_amber_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}
