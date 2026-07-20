import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/resident/models/resident_dropdown.dart';
import '../../../features/resident/providers/resident_provider.dart';

class ResidentSelector extends ConsumerStatefulWidget {
  final ResidentDropdown? initialValue;
  final ValueChanged<ResidentDropdown> onChanged;

  const ResidentSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  ConsumerState<ResidentSelector> createState() =>
      _ResidentSelectorState();
}

class _ResidentSelectorState
    extends ConsumerState<ResidentSelector> {
  late Future<List<ResidentDropdown>> _futureResidents;

  ResidentDropdown? _selectedResident;

  @override
  void initState() {
    super.initState();

    _selectedResident = widget.initialValue;

    _futureResidents = ref
        .read(residentProvider)
        .loadResidents();
  }

  Future<void> _showResidentDialog(
      List<ResidentDropdown> residents) async {
    final searchController = TextEditingController();

    List<ResidentDropdown> filtered =
        List.from(residents);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Select Resident",
              ),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration:
                          const InputDecoration(
                        prefixIcon:
                            Icon(Icons.search),
                        hintText:
                            "Search by name or flat",
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          filtered = residents
                              .where((resident) {
                            final query = value
                                .toLowerCase();

                            return resident.name
                                    .toLowerCase()
                                    .contains(query) ||
                                resident.flat
                                    .toLowerCase()
                                    .contains(query);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            filtered.length,
                        itemBuilder:
                            (context, index) {
                          final resident =
                              filtered[index];

                          return ListTile(
                            leading: const Icon(
                              Icons.home,
                            ),
                            title: Text(
                                resident.name),
                            subtitle: Text(
                                resident.flat),
                            onTap: () {
                              Navigator.pop(
                                  context);

                              setState(() {
                                _selectedResident =
                                    resident;
                              });

                              widget.onChanged(
                                  resident);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResidentDropdown>>(
      future: _futureResidents,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Text(
            snapshot.error.toString(),
          );
        }

        final residents =
            snapshot.data ?? [];

        return InkWell(
          onTap: () =>
              _showResidentDialog(residents),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Resident",
              border: OutlineInputBorder(),
              suffixIcon:
                  Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _selectedResident == null
                  ? "Select Resident"
                  : "${_selectedResident!.flat} - ${_selectedResident!.name}",
            ),
          ),
        );
      },
    );
  }
}