import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/incident.dart';
import '../providers/incident_provider.dart';

class IncidentScreen extends ConsumerWidget {
  const IncidentScreen({super.key});

  bool _canManage(String role) => {
        'SYSTEM_ADMIN',
        'ORGANIZATION_ADMIN',
        'PROPERTY_MANAGER',
        'SECURITY_MANAGER',
      }.contains(role.toUpperCase());

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final type = TextEditingController(text: 'SECURITY');
    final location = TextEditingController();
    String severity = 'MEDIUM';

    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Report Incident'),
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
                    controller: type,
                    decoration: const InputDecoration(
                      labelText: 'Incident type',
                      hintText: 'SECURITY / FIRE / SUSPICIOUS_ACTIVITY',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => severity = value);
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
                      description.text.trim().length < 3 ||
                      type.text.trim().length < 2) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid title, type and description.'),
                      ),
                    );
                    return;
                  }

                  try {
                    await ref.read(incidentServiceProvider).create(
                      title: title.text.trim(),
                      description: description.text.trim(),
                      incidentType: type.text.trim().toUpperCase(),
                      severity: severity,
                      location: location.text.trim().isEmpty
                          ? null
                          : location.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Unable to report incident: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Report'),
              ),
            ],
          ),
        ),
      );

      if (created == true) {
        ref.invalidate(incidentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incident reported successfully.')),
          );
        }
      }
    } finally {
      title.dispose();
      description.dispose();
      type.dispose();
      location.dispose();
    }
  }

  Future<void> _manage(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
  ) async {
    String status = incident.status;
    final investigation = TextEditingController();
    final resolution = TextEditingController();

    try {
      final updated = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('Manage Incident #${incident.id}'),
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
                      DropdownMenuItem(
                        value: 'INVESTIGATING',
                        child: Text('Investigating'),
                      ),
                      DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                      DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: investigation,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Investigation notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resolution,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Resolution notes',
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
                        content: Text('Resolution notes are required.'),
                      ),
                    );
                    return;
                  }
                  try {
                    await ref.read(incidentServiceProvider).update(
                      incident.id,
                      {
                        'status': status,
                        'investigation_notes': investigation.text.trim().isEmpty
                            ? null
                            : investigation.text.trim(),
                        'resolution_notes': resolution.text.trim().isEmpty
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
                        content: Text('Unable to update incident: $e'),
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

      if (updated == true) ref.invalidate(incidentsProvider);
    } finally {
      investigation.dispose();
      resolution.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentsProvider);
    final role = ref.watch(authProvider).user?.role ?? '';
    final canManage = _canManage(role);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Incident Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(incidentsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Incident'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load incidents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(incidentsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incidentsProvider);
            await ref.read(incidentsProvider.future);
          },
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No incidents reported',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final x = items[i];
                    final critical = x.severity == 'CRITICAL';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: critical
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          child: Icon(
                            critical ? Icons.warning_rounded : Icons.report_problem_outlined,
                            color: critical ? Colors.red : Colors.orange,
                          ),
                        ),
                        title: Text(
                          x.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${x.incidentType} • ${x.severity}\n'
                            '${x.location ?? 'Community'}\n'
                            '${x.description}',
                          ),
                        ),
                        isThreeLine: true,
                        trailing: canManage
                            ? OutlinedButton(
                                onPressed: () => _manage(context, ref, x),
                                child: Text(x.status),
                              )
                            : Chip(label: Text(x.status)),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
