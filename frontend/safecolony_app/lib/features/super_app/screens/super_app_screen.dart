import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/super_app.dart';
import '../services/super_app_service.dart';
import '../../ai/screens/ai_assistant_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';
import 'community_map_screen.dart';
import 'delivery_hub_screen.dart';

class SuperAppScreen extends StatefulWidget {
  const SuperAppScreen({super.key});

  @override
  State<SuperAppScreen> createState() => _SuperAppScreenState();
}

class _SuperAppScreenState extends State<SuperAppScreen> {
  final api = SuperAppService();
  late Future<SuperAppOverview> future;

  @override
  void initState() {
    super.initState();
    future = api.overview();
  }

  void reload() => setState(() => future = api.overview());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('SafeColony Hub'),
          actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
        ),
        backgroundColor: const Color(0xffF5F7FB),
        body: FutureBuilder<SuperAppOverview>(
          future: future,
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (s.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Unable to load SafeColony Hub.\n${s.error}')));
            final o = s.data!;
            final isAdmin = {'SYSTEM_ADMIN', 'ORGANIZATION_ADMIN', 'PROPERTY_MANAGER'}.contains(o.role);
            return RefreshIndicator(
              onRefresh: () async { reload(); await future; },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _hero(),
                  const SizedBox(height: 16),
                  _actions(),
                  const SizedBox(height: 16),
                  _communityDays(o),
                  const SizedBox(height: 12),
                  _services(o),
                  const SizedBox(height: 12),
                  _hub(o),
                  const SizedBox(height: 12),
                  _utilities(o),
                  const SizedBox(height: 12),
                  _map(o),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    _adminTools(o),
                  ],
                  const SizedBox(height: 24),
                  _requests(),
                ],
              ),
            );
          },
        ),
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xff312E81), Color(0xff0F766E)]),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, size: 34, color: Colors.white),
            SizedBox(height: 10),
            Text('Everything your community needs', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Shopping, services, deliveries, recurring orders, payments and AI — connected in one place.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );

  Widget _actions() => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _action(Icons.shopping_basket, 'Marketplace', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()))),
          _action(Icons.build, 'Home & Vehicle Services', _newService),
          _action(Icons.repeat, 'Recurring Orders', _newRecurring),
          _action(Icons.auto_awesome, 'SafeColony AI', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAssistantScreen()))),
        ],
      );

  Widget _action(IconData icon, String title, VoidCallback action) => SizedBox(
        width: MediaQuery.of(context).size.width / 2 - 26,
        child: Card(
          child: InkWell(
            onTap: action,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))]),
            ),
          ),
        ),
      );

  Widget _communityDays(SuperAppOverview o) => _card(
        'Community Days',
        o.communityDays.isEmpty
            ? [const Text('No community day scheduled yet.')]
            : o.communityDays.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
                  title: Text(e['title'] ?? ''),
                  subtitle: Text('${e['category']} • ${e['vendor'] ?? 'Community vendor'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                )).toList(),
      );

  Widget _services(SuperAppOverview o) => _card(
        'Trusted Community Services',
        o.services.isEmpty
            ? [const Text('No service providers listed yet.')]
            : o.services.take(8).map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.handyman),
                  title: Text(e['name'] ?? ''),
                  subtitle: Text('${e['category']} • ${e['description'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone_outlined),
                    onPressed: e['phone'] == null ? null : () => _call(e['phone'].toString()),
                  ),
                )).toList(),
      );

  Widget _hub(SuperAppOverview o) => Card(
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryHubScreen())),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const CircleAvatar(child: Icon(Icons.inventory_2)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Delivery Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text('${o.hub['at_hub'] ?? 0} parcels waiting'), Text('${o.hub['total_parcels'] ?? 0} total community parcels')])) ,
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      );

  Widget _utilities(SuperAppOverview o) => _card(
        'Utilities',
        [
          if (o.utilities.isNotEmpty)
            ...o.utilities.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(e['provider'] ?? ''),
                  subtitle: Text('${e['type']} • ${e['status']}'),
                  trailing: Text('₹${e['amount']}'),
                )),
          if (o.utilities.isEmpty && o.supportedUtilityProviders.isNotEmpty) ...[
            const Text('Supported utility providers'),
            const SizedBox(height: 8),
            ...o.supportedUtilityProviders.map((p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.electrical_services_outlined),
                  title: Text(p.name),
                  subtitle: Text('${p.utilityType} • ${p.integrationType}'),
                  trailing: const Icon(Icons.check_circle_outline),
                )),
          ],
          if (o.utilities.isEmpty && o.supportedUtilityProviders.isEmpty)
            const Text('No utility providers are onboarded for this community yet.'),
        ],
      );

  Widget _map(SuperAppOverview o) => Card(
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityMapScreen(points: o.mapPoints))),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const CircleAvatar(child: Icon(Icons.map_outlined)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Community Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(o.mapPoints.isEmpty ? 'No locations configured yet.' : '${o.mapPoints.length} mapped community locations'), const SizedBox(height: 4), const Text('Tap to view locations and open directions in Maps.', style: TextStyle(color: Color(0xff64748B)))])),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      );

  Widget _adminTools(SuperAppOverview o) => _card('Community Admin Tools', [
        if (o.supportedUtilityProviders.isNotEmpty) ...[
          const Text('Utility Providers', style: TextStyle(fontWeight: FontWeight.w700)),
          ...o.supportedUtilityProviders.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.electrical_services_outlined),
                title: Text(p.name),
                subtitle: Text('${p.utilityType} • ${p.integrationType} • ${p.status}'),
                trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editUtilityProvider(p)),
              )),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_business_outlined),
          title: const Text('Utility Provider Onboarding'),
          subtitle: const Text('Add a provider and mark it onboarding/active/inactive.'),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: _addUtilityProvider,
        ),
        const Divider(),
        if (o.mapPoints.isNotEmpty) ...[
          const Text('Community Map Locations', style: TextStyle(fontWeight: FontWeight.w700)),
          ...o.mapPoints.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(p.name),
                subtitle: Text('${p.pointType} • ${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}'),
                trailing: IconButton(icon: const Icon(Icons.edit_location_alt_outlined), onPressed: () => _editMapPoint(p)),
              )),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_location_alt_outlined),
          title: const Text('Add Community Map Location'),
          subtitle: Text('${o.mapPoints.length} active map point(s)'),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: _addMapPoint,
        ),
      ]);

  Widget _card(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...children]),
        ),
      );

  Widget _requests() => FutureBuilder<List<ServiceRequest>>(
        future: api.requests(),
        builder: (context, snapshot) {
          final children = snapshot.hasData && snapshot.data!.isNotEmpty
              ? snapshot.data!.map((r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.title),
                    subtitle: Text('${r.category} • ${r.status}${r.vendorName == null ? (r.providerName == null ? ' • Awaiting provider' : ' • ${r.providerName}') : ' • ${r.vendorName}'}${r.quotedAmount == null ? '' : ' • Quote ₹${r.quotedAmount}'}'),
                    trailing: r.status == 'QUOTED'
                        ? FilledButton(onPressed: () async { await api.updateRequest(r.id, 'APPROVED'); if (mounted) setState(() {}); }, child: const Text('Approve'))
                        : null,
                  )).toList()
              : <Widget>[const Text('No service requests yet.')];
          return _card('My Service Requests', children);
        },
      );

  Future<void> _newService() async {
    List<ServiceProvider> providers = [];
    try {
      providers = await api.serviceProviders();
    } catch (_) {}
    if (!mounted) return;

    final categories = <String>{...providers.map((p) => p.category)}.toList()..sort();
    final title = TextEditingController();
    final desc = TextEditingController();
    final slot = TextEditingController();
    String category = categories.isNotEmpty ? categories.first : 'HOME_SERVICE';
    ServiceProvider? selected;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request a Service'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: categories.contains(category) ? category : null,
                  decoration: const InputDecoration(labelText: 'Service category', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: categories.isEmpty ? null : (value) async {
                    if (value == null) return;
                    setDialogState(() { category = value; selected = null; });
                    try {
                      final loaded = await api.serviceProviders(category: category);
                      if (context.mounted) setDialogState(() { providers = loaded; });
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ServiceProvider>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Provider / vendor (optional)', border: OutlineInputBorder()),
                  items: providers.where((p) => p.category.toUpperCase() == category.toUpperCase()).map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.providerType == 'VENDOR' ? 'Vendor' : 'Community service'})'))).toList(),
                  onChanged: (value) => setDialogState(() => selected = value),
                ),
                const SizedBox(height: 10),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'What do you need?', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Describe the problem', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: slot, decoration: const InputDecoration(labelText: 'Preferred time', hintText: 'e.g. Tomorrow 10–11 AM', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                const Align(alignment: Alignment.centerLeft, child: Text('If no provider is selected, the request stays unassigned unless exactly one matching vendor exists.')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Request')),
          ],
        ),
      ),
    );
    try {
      if (ok != true || title.text.trim().isEmpty) return;
      final created = await api.createRequest(
        category: category,
        title: title.text.trim(),
        description: desc.text.trim().isEmpty ? null : desc.text.trim(),
        preferredSlot: slot.text.trim().isEmpty ? null : slot.text.trim(),
        providerId: selected?.providerId,
        vendorId: selected?.vendorId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(created.vendorName == null && created.providerName == null ? 'Request created and waiting for provider assignment.' : 'Service request sent to ${created.vendorName ?? created.providerName}.')));
        reload();
      }
    } finally {
      title.dispose();
      desc.dispose();
      slot.dispose();
    }
  }

  Future<void> _newRecurring() async {
    final d = TextEditingController();
    final day = TextEditingController();
    List<ServiceProvider> providers = [];
    ServiceProvider? selected;
    try {
      providers = await api.serviceProviders();
    } catch (_) {}
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Recurring Community Order'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: d,
                  decoration: const InputDecoration(
                    labelText: 'What should we repeat?',
                    hintText: '500ml milk every morning',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ServiceProvider>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Responsible vendor (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: providers
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selected = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: day,
                  decoration: const InputDecoration(
                    labelText: 'Preferred day/time',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'If a vendor is selected, the recurring order is routed to that vendor. '
                    'Otherwise SafeColony auto-assigns when exactly one matching vendor exists.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (ok != true || d.text.trim().isEmpty) return;
      await api.createRecurring(
        category: 'DAILY_LIFE',
        description: d.text.trim(),
        cadence: 'WEEKLY',
        day: day.text.trim().isEmpty ? null : day.text.trim(),
        vendorId: selected?.vendorId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selected == null
                ? 'Recurring order saved.'
                : 'Recurring order saved for ${selected!.name}.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      d.dispose();
      day.dispose();
    }
  }

  Future<void> _addUtilityProvider() async {
    final name = TextEditingController();
    final type = TextEditingController(text: 'ELECTRICITY');
    final contact = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final notes = TextEditingController();
    String status = 'ONBOARDING';
    String integration = 'MANUAL';
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Utility Provider Onboarding'),
            content: SingleChildScrollView(child: Column(children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Provider name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: type, decoration: const InputDecoration(labelText: 'Utility type', hintText: 'ELECTRICITY / WATER / GAS', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: integration, decoration: const InputDecoration(labelText: 'Integration type', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'MANUAL', child: Text('Manual')), DropdownMenuItem(value: 'API', child: Text('API')), DropdownMenuItem(value: 'WEBHOOK', child: Text('Webhook'))], onChanged: (v) => setDialogState(() => integration = v ?? 'MANUAL')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Onboarding status', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ONBOARDING', child: Text('Onboarding')), DropdownMenuItem(value: 'ACTIVE', child: Text('Active')), DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive'))], onChanged: (v) => setDialogState(() => status = v ?? 'ONBOARDING')),
              const SizedBox(height: 10),
              TextField(controller: contact, decoration: const InputDecoration(labelText: 'Contact name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Contact email', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact phone', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes / integration details', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: Text('API/Webhook only records onboarding metadata today; provider-specific credentials and bill fetching are not automatically connected.')),
            ])),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
          ),
        ),
      );
      if (ok != true || name.text.trim().isEmpty) return;
      await api.createUtilityProvider(name: name.text.trim(), utilityType: type.text.trim().toUpperCase(), integrationType: integration, status: status, contactName: contact.text.trim().isEmpty ? null : contact.text.trim(), contactEmail: email.text.trim().isEmpty ? null : email.text.trim(), contactPhone: phone.text.trim().isEmpty ? null : phone.text.trim(), notes: notes.text.trim().isEmpty ? null : notes.text.trim());
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utility provider saved.'))); reload(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      for (final c in [name, type, contact, email, phone, notes]) c.dispose();
    }
  }

  Future<void> _editUtilityProvider(UtilityProvider provider) async {
    String status = provider.status;
    String integration = provider.integrationType;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(provider.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: integration, decoration: const InputDecoration(labelText: 'Integration type', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'MANUAL', child: Text('Manual')), DropdownMenuItem(value: 'API', child: Text('API')), DropdownMenuItem(value: 'WEBHOOK', child: Text('Webhook'))], onChanged: (v) => setDialogState(() => integration = v ?? integration)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ONBOARDING', child: Text('Onboarding')), DropdownMenuItem(value: 'ACTIVE', child: Text('Active')), DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive'))], onChanged: (v) => setDialogState(() => status = v ?? status)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Update'))],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await api.updateUtilityProvider(provider.id, {'integration_type': integration, 'status': status});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utility provider updated.'))); reload(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addMapPoint() async {
    final type = TextEditingController(text: 'GATE');
    final name = TextEditingController();
    final description = TextEditingController();
    final address = TextEditingController();
    final lat = TextEditingController();
    final lng = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Add Community Map Location'),
          content: SingleChildScrollView(child: Column(children: [TextField(controller: type, decoration: const InputDecoration(labelText: 'Type', hintText: 'GATE / BLOCK / AMENITY / DELIVERY_HUB / VENDOR', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: description, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: address, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder())))]), const SizedBox(height: 8), const Align(alignment: Alignment.centerLeft, child: Text('Use the exact community location coordinates.'))])),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
        ),
      );
      if (ok != true || name.text.trim().isEmpty) return;
      final latitude = double.tryParse(lat.text.trim());
      final longitude = double.tryParse(lng.text.trim());
      if (latitude == null || longitude == null || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid latitude and longitude.'))); return; }
      await api.createMapPoint(pointType: type.text.trim().toUpperCase(), name: name.text.trim(), description: description.text.trim().isEmpty ? null : description.text.trim(), address: address.text.trim().isEmpty ? null : address.text.trim(), latitude: latitude, longitude: longitude);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Map location added.'))); reload(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      for (final c in [type, name, description, address, lat, lng]) c.dispose();
    }
  }

  Future<void> _editMapPoint(MapPoint point) async {
    final name = TextEditingController(text: point.name);
    final description = TextEditingController(text: point.description ?? '');
    final address = TextEditingController(text: point.address ?? '');
    final lat = TextEditingController(text: point.latitude.toString());
    final lng = TextEditingController(text: point.longitude.toString());
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Edit ${point.name}'),
          content: SingleChildScrollView(child: Column(children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: description, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: address, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder())))]), const SizedBox(height: 8), const Text('To retire a point, ask for it to be marked inactive in the backend; this UI keeps the existing location active.')])),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update'))],
        ),
      );
      if (ok != true) return;
      final latitude = double.tryParse(lat.text.trim());
      final longitude = double.tryParse(lng.text.trim());
      if (name.text.trim().isEmpty || latitude == null || longitude == null || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid location details.'))); return; }
      await api.updateMapPoint(point.id, {'name': name.text.trim(), 'description': description.text.trim().isEmpty ? null : description.text.trim(), 'address': address.text.trim().isEmpty ? null : address.text.trim(), 'latitude': latitude, 'longitude': longitude});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Map location updated.'))); reload(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      name.dispose(); description.dispose(); address.dispose(); lat.dispose(); lng.dispose();
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }
}
