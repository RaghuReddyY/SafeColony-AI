import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../scopes/block_admin_service.dart';

class BlockAdminManagementScreen extends ConsumerStatefulWidget {
  const BlockAdminManagementScreen({super.key});

  @override
  ConsumerState<BlockAdminManagementScreen> createState() => _BlockAdminManagementScreenState();
}

class _BlockAdminManagementScreenState extends ConsumerState<BlockAdminManagementScreen> {
  final _service = BlockAdminService();
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final blocks = await _service.getBlocks();
      final admins = await _service.getAdmins();
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _admins = admins;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> admin) async {
    final name = TextEditingController(text: admin['full_name']?.toString() ?? '');
    final email = TextEditingController(text: admin['email']?.toString() ?? '');
    final phone = TextEditingController(text: admin['phone']?.toString() ?? '');
    final password = TextEditingController();
    final selected = <int>{...(admin['section_ids'] as List? ?? []).whereType<int>()};
    final isFinance = admin['role'].toString() == 'COMMUNITY_FINANCE_ADMIN';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isFinance ? 'Edit Finance Collector' : 'Edit Block Administrator'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'Mobile number')),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'New password (optional)')),
                  if (!isFinance) ...[
                    const SizedBox(height: 16),
                    const Align(alignment: Alignment.centerLeft, child: Text('Assign blocks', style: TextStyle(fontWeight: FontWeight.w800))),
                    ..._blocks.map((block) {
                      final id = block['section_id'] as int;
                      return CheckboxListTile(
                        value: selected.contains(id),
                        title: Text(block['section_name'].toString()),
                        onChanged: (v) => setDialogState(() => v == true ? selected.add(id) : selected.remove(id)),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (name.text.trim().length < 3 || !email.text.contains('@') || phone.text.trim().length < 10) return;
              if (!isFinance && selected.isEmpty) return;
              Navigator.pop(context, true);
            }, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _service.updateAdmin(
        userId: admin['id'] as int,
        fullName: name.text,
        email: email.text,
        phone: phone.text,
        sectionIds: isFinance ? const [] : selected.toList(),
        password: password.text.trim().isEmpty ? null : password.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrator updated successfully.')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      name.dispose(); email.dispose(); phone.dispose(); password.dispose();
    }
  }

  Future<void> _create({required bool finance}) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController(text: 'ChangeMe@123');
    final selected = <int>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(finance ? 'Add Community Finance Collector' : 'Add Block Administrator'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'Mobile number')),
                  TextField(controller: password, decoration: const InputDecoration(labelText: 'Temporary password')),
                  if (!finance) ...[
                    const SizedBox(height: 16),
                    const Align(alignment: Alignment.centerLeft, child: Text('Assign blocks', style: TextStyle(fontWeight: FontWeight.w800))),
                    ..._blocks.map((block) {
                      final id = block['section_id'] as int;
                      return CheckboxListTile(
                        value: selected.contains(id),
                        title: Text(block['section_name'].toString()),
                        onChanged: (value) => setDialogState(() => value == true ? selected.add(id) : selected.remove(id)),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      if (finance) {
        await _service.createFinanceAdmin(fullName: name.text, email: email.text, phone: phone.text, password: password.text);
      } else {
        await _service.createBlockAdmin(fullName: name.text, email: email.text, phone: phone.text, password: password.text, sectionIds: selected.toList());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrator created successfully.')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block & Finance Administration')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(child: _summary('Blocks', '${_blocks.length}', Icons.apartment_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _summary('Scoped Admins', '${_admins.length}', Icons.admin_panel_settings_rounded)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: FilledButton.icon(onPressed: () => _create(finance: false), icon: const Icon(Icons.add), label: const Text('Block Admin'))),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(onPressed: () => _create(finance: true), icon: const Icon(Icons.account_balance_wallet), label: const Text('Finance Collector'))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Current assignments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ..._admins.map((admin) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(admin['full_name'].toString().substring(0, 1).toUpperCase())),
                          title: Text(admin['full_name'].toString()),
                          subtitle: Text('${admin['role']}\n${(admin['section_names'] as List).join(', ')}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                            onPressed: () => _edit(admin),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _summary(String title, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [Icon(icon, color: Colors.indigo), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))])]),
        ),
      );
}
