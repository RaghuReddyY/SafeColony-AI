import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';

import '../../property/models/property.dart';
import '../../property/providers/property_provider.dart';

import '../../section/models/section.dart';
import '../../section/providers/section_provider.dart';

import '../models/unit.dart';
import '../providers/unit_provider.dart';
import 'unit_form_screen.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  final UnitProvider _unitProvider = UnitProvider();
  final PropertyProvider _propertyProvider = PropertyProvider();
  final SectionProvider _sectionProvider = SectionProvider();

  List<Unit> _units = [];
  List<Property> _properties = [];
  List<Section> _sections = [];

  final Map<int, String> _propertyNames = {};
  final Map<int, String> _sectionNames = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      _properties = await _propertyProvider.loadProperties();
      _sections = await _sectionProvider.loadSections();
      _units = await _unitProvider.loadUnits();

      _propertyNames.clear();
      for (final property in _properties) {
        _propertyNames[property.id] = property.name;
      }

      _sectionNames.clear();
      for (final section in _sections) {
        _sectionNames[section.id] = section.name;
      }
        debugPrint("========= Properties =========");
        for (final p in _properties) {
          debugPrint("${p.id} -> ${p.name}");
        }

        debugPrint("========= Sections =========");
        for (final s in _sections) {
          debugPrint("${s.id} -> ${s.name}");
        }

        debugPrint("========= Units =========");
        for (final u in _units) {
          debugPrint(
              "${u.unitNumber} property=${u.propertyId} section=${u.sectionId}");
        }
    } catch (e) {
      debugPrint(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _openForm([Unit? unit]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitFormScreen(unit: unit),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deleteUnit(Unit unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Unit"),
          content: Text(
            "Delete ${unit.unitNumber} ?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _unitProvider.deleteUnit(unit.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unit deleted successfully",
            ),
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unit Management"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _units.isEmpty
                  ? const Center(
                      child: Text(
                        "No Units Found",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _units.length,
                      itemBuilder: (context, index) {
                        final unit = _units[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        unit.unitNumber,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == "edit") {
                                          _openForm(unit);
                                        } else {
                                          _deleteUnit(unit);
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
                                  ],
                                ),

                                const SizedBox(height: 12),

                                _buildInfoRow(
                                  Icons.apartment,
                                  "Property",
                                  _propertyNames[
                                          unit.propertyId] ??
                                      "-",
                                ),

                                _buildInfoRow(
                                  Icons.dashboard,
                                  "Section",
                                  _sectionNames[
                                          unit.sectionId] ??
                                      "-",
                                ),

                                _buildInfoRow(
                                  Icons.person,
                                  "Owner",
                                  unit.ownerName,
                                ),

                                _buildInfoRow(
                                  Icons.home_work,
                                  "Unit Type",
                                  unit.unitType,
                                ),

                                _buildInfoRow(
                                  Icons.layers,
                                  "Floor",
                                  unit.floor,
                                ),

                                _buildInfoRow(
                                  Icons.phone,
                                  "Intercom",
                                  unit.intercomNumber,
                                ),

                                _buildInfoRow(
                                  Icons.info,
                                  "Occupancy",
                                  unit.occupancyStatus,
                                ),

                                _buildInfoRow(
                                  unit.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  "Status",
                                  unit.isActive
                                      ? "Active"
                                      : "Inactive",
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            "$label : ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}