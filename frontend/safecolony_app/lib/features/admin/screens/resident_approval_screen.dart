import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_provider.dart';

class ResidentApprovalScreen extends ConsumerStatefulWidget {
  const ResidentApprovalScreen({super.key});

  @override
  ConsumerState<ResidentApprovalScreen> createState() =>
      _ResidentApprovalScreenState();
}

class _ResidentApprovalScreenState
    extends ConsumerState<ResidentApprovalScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(adminProvider.notifier).loadPendingResidents();
    });
  }

  Future<void> _editResident(dynamic resident) async {
    final name = TextEditingController(text: resident.fullName);
    final email = TextEditingController(text: resident.email);
    final phone = TextEditingController(text: resident.phone);
    String type = resident.residentType.toString();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Resident'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Resident Type'),
                  items: const [
                    DropdownMenuItem(value: 'OWNER', child: Text('Owner')),
                    DropdownMenuItem(value: 'TENANT', child: Text('Tenant')),
                    DropdownMenuItem(value: 'FAMILY', child: Text('Family')),
                  ],
                  onChanged: (v) => setState(() { if (v != null) type = v; }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save Changes')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    try {
      await ref.read(adminProvider.notifier).updateResident(
        id: resident.id,
        fullName: name.text,
        email: email.text,
        phone: phone.text,
        residentType: type,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident updated successfully.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      name.dispose(); email.dispose(); phone.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {

    final admin = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Residents"),
      ),
      body: Builder(
        builder: (_) {

          if (admin.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (admin.error != null) {
            return Center(
              child: Text(admin.error!),
            );
          }

          if (admin.residents.isEmpty) {
            return const Center(
              child: Text("No pending residents"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admin.residents.length,
            itemBuilder: (_, index) {

              final resident = admin.residents[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        resident.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text("Property : ${resident.propertyName}"),

                      Text("Section : ${resident.sectionName}"),

                      Text("Unit : ${resident.unitNumber}"),

                      Text("Resident Type : ${resident.residentType}"),

                      Text("Phone : ${resident.phone}"),

                      Text("Email : ${resident.email}"),

                      const SizedBox(height: 20),

                      Row(
                        children: [

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {

                                await ref
                                    .read(adminProvider.notifier)
                                    .approveResident(resident.id);

                              },
                              child: const Text("Approve"),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {

                                await ref
                                    .read(adminProvider.notifier)
                                    .rejectResident(resident.id);

                              },
                              child: const Text("Reject"),
                            ),
                          ),

                        ],
                      )

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}