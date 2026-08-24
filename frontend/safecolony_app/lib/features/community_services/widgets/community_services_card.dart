import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../models/community_service.dart';
import '../screens/community_services_screen.dart';
import '../services/community_service.dart';

class CommunityServicesCard extends StatefulWidget {
  const CommunityServicesCard({super.key});

  @override
  State<CommunityServicesCard> createState() => _CommunityServicesCardState();
}

class _CommunityServicesCardState extends State<CommunityServicesCard> {
  final _api = CommunityServicesApi();
  Future<List<CommunityServiceEntry>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _openAll() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityServicesScreen()));
  }

  Future<void> _call(String phone) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open the phone dialer.')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CommunityServiceEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _shell(const SizedBox(height: 130, child: Center(child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return _shell(Column(children: [const Icon(Icons.handyman_outlined, size: 34, color: Color(0xff64748B)), const SizedBox(height: 8), const Text('Community Services unavailable'), const SizedBox(height: 4), Text(ApiClient.errorMessage(snapshot.error!), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff64748B), fontSize: 12)), const SizedBox(height: 10), TextButton(onPressed: () => setState(() => _future = _api.list()), child: const Text('Retry'))]));
        }
        final items = snapshot.data ?? const <CommunityServiceEntry>[];
        return _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Community Services', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('Useful local contacts shared by the community', style: TextStyle(color: Color(0xff64748B), fontSize: 12))])), TextButton(onPressed: _openAll, child: const Text('View all'))]),
          const SizedBox(height: 10),
          if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No services added yet. Add electricians, plumbers and other useful contacts.', style: TextStyle(color: Color(0xff64748B)))) else ...items.take(3).map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [CircleAvatar(radius: 18, backgroundColor: const Color(0xffEEF2FF), foregroundColor: const Color(0xff4F46E5), child: const Icon(Icons.handyman_rounded, size: 19)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${item.category} • ${item.workDescription}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xff64748B)))])), IconButton(onPressed: () => _call(item.phone), tooltip: 'Call ${item.name}', icon: const Icon(Icons.call_rounded, size: 20))]))),
        ]));
      },
    );
  }

  Widget _shell(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xffE2E8F0))),
      child: child,
    );
  }
}
