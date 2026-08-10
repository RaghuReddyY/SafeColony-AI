import 'package:flutter/material.dart';

import '../../../features/guard/models/guard_section.dart';
import '../../../features/guard/models/guard_unit.dart';
import '../../../features/guard/services/guard_lookup_service.dart';

class UnitSelector extends StatefulWidget {
  final GuardSection? section;
  final GuardUnit? initialValue;
  final ValueChanged<GuardUnit?> onChanged;

  const UnitSelector({
    super.key,
    required this.section,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<UnitSelector> createState() =>
      _UnitSelectorState();
}

class _UnitSelectorState
    extends State<UnitSelector> {

  final GuardLookupService _service =
      GuardLookupService();

  List<GuardUnit> _units = [];

  GuardUnit? _selected;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _selected = widget.initialValue;

    if (widget.section != null) {
      _loadUnits();
    }
  }

  @override
  void didUpdateWidget(
      covariant UnitSelector oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.section?.id !=
        widget.section?.id) {

      _selected = null;
      _units = [];

      // Notify parent AFTER build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onChanged(null);
      });

      if (widget.section != null) {
        _loadUnits();
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _loadUnits() async {

    if (widget.section == null) return;

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {

      final data = await _service.getUnits(
        widget.section!.id,
      );

      if (!mounted) return;

      setState(() {

        _units = data;

        _selected = null;

        _loading = false;

      });

    } catch (_) {

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to load units",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (widget.section == null) {

      return DropdownButtonFormField<GuardUnit>(
        value: null,
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: "Unit",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.home),
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

    return DropdownButtonFormField<GuardUnit>(

      value: _selected,

      decoration: const InputDecoration(
        labelText: "Unit",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.home),
      ),

      items: _units
          .map(
            (unit) => DropdownMenuItem(
              value: unit,
              child: Text(unit.unitNumber),
            ),
          )
          .toList(),

      onChanged: (value) {

        setState(() {
          _selected = value;
        });

        widget.onChanged(value);

      },

      validator: (value) {

        if (value == null) {
          return "Please select a unit";
        }

        return null;
      },
    );
  }
}