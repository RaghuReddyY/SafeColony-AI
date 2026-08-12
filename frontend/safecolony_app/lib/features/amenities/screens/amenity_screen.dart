import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/amenity.dart';
import '../providers/amenity_provider.dart';

class AmenityScreen extends ConsumerWidget {
  const AmenityScreen({super.key});

  bool _isAdmin(String? role) =>
      role == 'SYSTEM_ADMIN' ||
      role == 'ORGANIZATION_ADMIN' ||
      role == 'PROPERTY_MANAGER';

  Future<void> _book(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final purpose = TextEditingController();
    final now = DateTime.now().add(const Duration(hours: 1));

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Book $name'),
          content: TextField(
            controller: purpose,
            decoration: const InputDecoration(
              labelText: 'Purpose',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(amenityServiceProvider).book(
                    id,
                    now,
                    now.add(const Duration(hours: 1)),
                    purpose.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Unable to book amenity: $e'),
                    ),
                  );
                }
              },
              child: const Text('Request'),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        ref.invalidate(amenitiesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request submitted.'),
          ),
        );
      }
    } finally {
      purpose.dispose();
    }
  }

  Future<void> _createAmenity(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = TextEditingController();
    final type = TextEditingController(text: 'GENERAL');
    final description = TextEditingController();
    final location = TextEditingController();
    final capacity = TextEditingController();

    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Create Amenity'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
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
                if (name.text.trim().isEmpty) return;
                try {
                  await ref.read(amenityServiceProvider).create(
                    name: name.text.trim(),
                    type: type.text.trim().toUpperCase(),
                    description: description.text.trim().isEmpty
                        ? null
                        : description.text.trim(),
                    location: location.text.trim().isEmpty
                        ? null
                        : location.text.trim(),
                    capacity: int.tryParse(capacity.text.trim()),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Unable to create amenity: $e'),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (created == true) {
        ref.invalidate(amenitiesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Amenity created successfully.')),
          );
        }
      }
    } finally {
      name.dispose();
      type.dispose();
      description.dispose();
      location.dispose();
      capacity.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(amenitiesProvider);
    final role = ref.watch(authProvider).user?.role;
    final admin = _isAdmin(role);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Amenities'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(amenitiesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              onPressed: () => _createAmenity(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Amenity'),
            )
          : null,
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load amenities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(amenitiesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(amenitiesProvider);
                await ref.read(amenitiesProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    Icons.pool_outlined,
                    size: 72,
                    color: Colors.indigo.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'No amenities configured',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      admin
                          ? 'Tap "Add Amenity" to create the first community facility.'
                          : 'Your community has not configured any bookable amenities yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(amenitiesProvider);
              await ref.read(amenitiesProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final Amenity a = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      child: Icon(
                        a.type.toUpperCase() == 'GYM'
                            ? Icons.fitness_center
                            : a.type.toUpperCase() == 'SPORTS'
                                ? Icons.sports_tennis
                                : Icons.pool,
                      ),
                    ),
                    title: Text(
                      a.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      [
                        a.type,
                        if (a.description != null &&
                            a.description!.isNotEmpty)
                          a.description!,
                      ].join(' • '),
                    ),
                    trailing: a.active
                        ? (admin
                            ? const Chip(label: Text('Active'))
                            : FilledButton(
                                onPressed: () => _book(
                                  context,
                                  ref,
                                  a.id,
                                  a.name,
                                ),
                                child: const Text('Book'),
                              ))
                        : const Chip(label: Text('Inactive')),
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
