import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../providers/property_provider.dart';
import 'property_form_screen.dart';

class PropertyListScreen extends ConsumerStatefulWidget {
  const PropertyListScreen({super.key});

  @override
  ConsumerState<PropertyListScreen> createState() =>
      _PropertyListScreenState();
}

class _PropertyListScreenState
    extends ConsumerState<PropertyListScreen> {
  late Future<List<Property>> _properties;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  void _loadProperties() {
    _properties = ref.read(propertyProvider).loadProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Properties"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PropertyFormScreen(),
            ),
          );

          if (result == true) {
            setState(() {
              _loadProperties();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Property>>(
        future: _properties,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return const Center(
              child: Text("No properties found"),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadProperties();
              });
            },
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.apartment),
                    title: Text(property.name),
                    subtitle: Text(
                      "${property.city}, ${property.state}",
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == "edit") {
                          final result =
                              await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyFormScreen(
                                property: property,
                              ),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              _loadProperties();
                            });
                          }
                        } else if (value == "delete") {
                          final confirm =
                              await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text(
                                  "Delete Property"),
                              content: const Text(
                                "Are you sure you want to delete this property?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context, false),
                                  child:
                                      const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context, true),
                                  child:
                                      const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(propertyProvider)
                                .deleteProperty(
                                    property.id);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                backgroundColor:
                                    Colors.green,
                                content: Text(
                                  "Property deleted successfully.",
                                ),
                              ),
                            );

                            setState(() {
                              _loadProperties();
                            });
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: "edit",
                          child: Text("Edit"),
                        ),
                        PopupMenuItem(
                          value: "delete",
                          child: Text("Delete"),
                        ),
                      ],
                    ),
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