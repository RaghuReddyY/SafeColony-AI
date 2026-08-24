import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../models/community_service.dart';
import '../services/community_service.dart';

class CommunityServicesScreen extends StatefulWidget {
  const CommunityServicesScreen({super.key});

  @override
  State<CommunityServicesScreen> createState() => _CommunityServicesScreenState();
}

class _CommunityServicesScreenState extends State<CommunityServicesScreen> {
  final _api = CommunityServicesApi();
  final _searchController = TextEditingController();
  List<CommunityServiceEntry> _items = [];
  bool _loading = true;
  String? _error;
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e);
        _loading = false;
      });
    }
  }

  List<String> get _categories {
    final values = _items.map((e) => e.category.trim()).where((e) => e.isNotEmpty).toSet().toList();
    values.sort();
    return ['All', ...values];
  }

  List<CommunityServiceEntry> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final categoryMatch = _category == 'All' || item.category == _category;
      final text = '${item.name} ${item.category} ${item.workDescription} ${item.phone}'.toLowerCase();
      return categoryMatch && (query.isEmpty || text.contains(query));
    }).toList();
  }

  Future<void> _openForm([CommunityServiceEntry? existing]) async {
    final result = await showDialog<CommunityServiceEntry>(
      context: context,
      builder: (_) => _CommunityServiceDialog(existing: existing, api: _api),
    );
    if (result == null || !mounted) return;
    await _load();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open the phone dialer.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Services'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [const SizedBox(height: 120), Center(child: Text('$_error')), const SizedBox(height: 12), Center(child: ElevatedButton(onPressed: _load, child: const Text('Retry')))])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      _introCard(),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search electrician, plumber, tutor...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final category = _categories[index];
                            return ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) => setState(() => _category = category),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        _emptyState()
                      else
                        ...filtered.map(_serviceCard),
                    ],
                  ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xffEEF2FF), Color(0xffF8FAFC)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE0E7FF)),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 27, backgroundColor: Color(0xff4F46E5), child: Icon(Icons.handyman_rounded, color: Colors.white)),
          SizedBox(width: 14),
          Expanded(child: Text('Find trusted services in your community. Residents and staff can add or update contact details so everyone can find help quickly.', style: TextStyle(fontSize: 14, height: 1.35))),
        ],
      ),
    );
  }

  Widget _serviceCard(CommunityServiceEntry item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xffE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: const Color(0xffEEF2FF), foregroundColor: const Color(0xff4F46E5), child: Icon(_iconFor(item.category))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(item.category, style: const TextStyle(color: Color(0xff4F46E5), fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(item.workDescription, style: const TextStyle(color: Color(0xff475569)))])),
                IconButton(onPressed: () => _openForm(item), icon: const Icon(Icons.edit_outlined), tooltip: 'Update contact'),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: Text(item.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), FilledButton.icon(onPressed: () => _call(item.phone), icon: const Icon(Icons.call, size: 18), label: const Text('Call'))]),
            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.notes!, style: const TextStyle(color: Color(0xff64748B))),
            ],
            if ((item.updatedByName ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Text('Last updated by ${item.updatedByName}', style: const TextStyle(fontSize: 11, color: Color(0xff94A3B8))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffE2E8F0))),
      child: const Column(children: [Icon(Icons.handyman_outlined, size: 42, color: Color(0xff94A3B8)), SizedBox(height: 10), Text('No community services found', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 5), Text('Add the first electrician, plumber, cleaner or other useful service.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff64748B)))]),
    );
  }

  IconData _iconFor(String category) {
    final value = category.toLowerCase();
    if (value.contains('electric')) return Icons.electrical_services;
    if (value.contains('plumb')) return Icons.plumbing;
    if (value.contains('clean')) return Icons.cleaning_services;
    if (value.contains('carp')) return Icons.carpenter;
    if (value.contains('driver')) return Icons.local_taxi;
    if (value.contains('cook')) return Icons.restaurant;
    if (value.contains('security')) return Icons.security;
    return Icons.handyman_rounded;
  }
}

class _CommunityServiceDialog extends StatefulWidget {
  final CommunityServiceEntry? existing;
  final CommunityServicesApi api;

  const _CommunityServiceDialog({required this.existing, required this.api});

  @override
  State<_CommunityServiceDialog> createState() => _CommunityServiceDialogState();
}

class _CommunityServiceDialogState extends State<_CommunityServiceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _phone;
  late final TextEditingController _work;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _work = TextEditingController(text: e?.workDescription ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _category.dispose(); _phone.dispose(); _work.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2 || _category.text.trim().length < 2 || _phone.text.trim().length < 5 || _work.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name, category, phone and work details.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final e = widget.existing;
      final result = e == null
          ? await widget.api.create(name: _name.text.trim(), category: _category.text.trim(), phone: _phone.text.trim(), workDescription: _work.text.trim(), notes: _notes.text.trim().isEmpty ? null : _notes.text.trim())
          : await widget.api.update(e.id, name: _name.text.trim(), category: _category.text.trim(), phone: _phone.text.trim(), workDescription: _work.text.trim(), notes: _notes.text.trim());
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? 'Update Service' : 'Add Community Service'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Person / Business name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 10),
          TextField(controller: _category, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Category', hintText: 'Electrician, Plumber, Tutor...')),
          const SizedBox(height: 10),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 10),
          TextField(controller: _work, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Work / service details', prefixIcon: Icon(Icons.work_outline))),
          const SizedBox(height: 10),
          TextField(controller: _notes, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'Availability, area, pricing note...')),
        ]),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save')),
      ],
    );
  }
}
