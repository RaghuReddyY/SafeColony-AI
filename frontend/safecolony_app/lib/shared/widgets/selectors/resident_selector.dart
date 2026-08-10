import 'package:flutter/material.dart';

import '../../../features/guard/models/guard_resident.dart';
import '../../../features/guard/models/guard_unit.dart';
import '../../../features/guard/services/guard_lookup_service.dart';

class ResidentSelector extends StatefulWidget {
  final GuardUnit? unit;
  final GuardResident? initialValue;
  final ValueChanged<GuardResident> onChanged;

  const ResidentSelector({
    super.key,
    required this.unit,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<ResidentSelector> createState() =>
      _ResidentSelectorState();
}

class _ResidentSelectorState
    extends State<ResidentSelector> {

  final GuardLookupService _service =
      GuardLookupService();

  List<GuardResident> _residents = [];

  GuardResident? _selectedResident;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _selectedResident = widget.initialValue;

    if (widget.unit != null) {
      _loadResidents();
    }
  }

  @override
  void didUpdateWidget(
      covariant ResidentSelector oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.unit?.id != widget.unit?.id) {

      _selectedResident = null;
      _residents.clear();

      if (widget.unit != null) {
        _loadResidents();
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _loadResidents() async {

    if (widget.unit == null) return;

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {

      final data =
          await _service.getResidents(widget.unit!.id);

      if (!mounted) return;

      setState(() {

        _residents = data;

        _loading = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to load residents",
          ),
        ),
      );
    }
  }

  Future<void> _showResidentDialog() async {

    final searchController =
        TextEditingController();

    List<GuardResident> filtered =
        List.from(_residents);

    await showDialog(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (context, dialogSetState) {

            return AlertDialog(

              title: const Text(
                "Select Resident",
              ),

              content: SizedBox(

                width: 450,

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
                            "Search resident",

                      ),

                      onChanged: (value) {

                        dialogSetState(() {

                          filtered = _residents.where(

                            (resident) {

                              return resident.fullName
                                  .toLowerCase()
                                  .contains(
                                      value.toLowerCase());

                            },

                          ).toList();

                        });

                      },

                    ),

                    const SizedBox(height: 12),

                    Expanded(

                      child: ListView.builder(

                        itemCount: filtered.length,

                        itemBuilder:
                            (context, index) {

                          final resident =
                              filtered[index];

                          return ListTile(

                            leading: const CircleAvatar(

                              child: Icon(Icons.person),

                            ),

                            title: Text(
                              resident.fullName,
                            ),

                            onTap: () {

                              Navigator.pop(context);

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

    if (widget.unit == null) {

      return InputDecorator(

        decoration: const InputDecoration(

          labelText: "Resident",

          border: OutlineInputBorder(),

          suffixIcon:
              Icon(Icons.arrow_drop_down),

        ),

        child: const Text(
          "Select Unit First",
        ),

      );
    }

    if (_loading) {

      return const Padding(

        padding: EdgeInsets.symmetric(
          vertical: 20,
        ),

        child: Center(
          child: CircularProgressIndicator(),
        ),

      );
    }

    return InkWell(

      onTap: _residents.isEmpty
          ? null
          : _showResidentDialog,

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
              : _selectedResident!.fullName,

        ),

      ),

    );
  }
}