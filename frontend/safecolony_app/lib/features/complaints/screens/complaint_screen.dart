import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';

class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key});

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  bool _canManage(String role) => {
        'SYSTEM_ADMIN',
        'ORGANIZATION_ADMIN',
        'PROPERTY_MANAGER',
      }.contains(role.toUpperCase());

  Future<void> _create() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController(text: 'GENERAL');
    String priority = 'MEDIUM';

    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Raise Complaint'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => priority = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().length < 3 ||
                      description.text.trim().length < 3) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid title and description.'),
                      ),
                    );
                    return;
                  }
                  try {
                    await ref.read(complaintServiceProvider).create(
                      title: title.text.trim(),
                      description: description.text.trim(),
                      category: category.text.trim().isEmpty
                          ? 'GENERAL'
                          : category.text.trim().toUpperCase(),
                      priority: priority,
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Unable to raise complaint: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      );

      if (created == true) ref.invalidate(complaintsProvider);
    } finally {
      title.dispose();
      description.dispose();
      category.dispose();
    }
  }

  Future<void> _manage(Complaint complaint) async {
    String status = complaint.status;
    final resolution = TextEditingController(text: complaint.resolution ?? '');

    try {
      final updated = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('Manage Complaint #${complaint.id}'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                      DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
                      DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                      DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                      DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resolution,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Resolution / closure notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (status == 'RESOLVED' && resolution.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Resolution details are required.'),
                      ),
                    );
                    return;
                  }
                  try {
                    await ref.read(complaintServiceProvider).update(
                      complaint.id,
                      {
                        'status': status,
                        'resolution': resolution.text.trim().isEmpty
                            ? null
                            : resolution.text.trim(),
                      },
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Unable to update complaint: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );

      if (updated == true) ref.invalidate(complaintsProvider);
    } finally {
      resolution.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintsProvider);
    final role = ref.watch(authProvider).user?.role ?? '';
    final canManage = _canManage(role);

    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Complaint'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 52, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Unable to load complaints'),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(complaintsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(complaintsProvider);
            await ref.read(complaintsProvider.future);
          },
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('No complaints')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: Text(
                          c.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${c.category} • ${c.priority}\n${c.description}',
                        ),
                        isThreeLine: true,
                        trailing: canManage
                            ? OutlinedButton(
                                onPressed: () => _manage(c),
                                child: Text(c.status),
                              )
                            : Chip(label: Text(c.status)),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
