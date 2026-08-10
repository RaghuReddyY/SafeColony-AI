import 'package:flutter/material.dart';

import '../../../features/guard/models/guard_property.dart';
import '../../../features/guard/services/guard_lookup_service.dart';

class PropertySelector extends StatefulWidget {
  final GuardProperty? initialValue;
  final ValueChanged<GuardProperty?> onChanged;

  const PropertySelector({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<PropertySelector> createState() =>
      _PropertySelectorState();
}

class _PropertySelectorState
    extends State<PropertySelector> {
  final GuardLookupService _service =
      GuardLookupService();

  List<GuardProperty> _properties = [];

  GuardProperty? _selected;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadProperties();
  }

Future<void> _loadProperties() async {

  try {

    final data = await _service.getProperties();

    if (!mounted) return;

    setState(() {

      _properties = data;

      _selected = widget.initialValue;

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
          "Failed to load properties",
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DropdownButtonFormField<GuardProperty>(
      value: _selected,
      decoration: const InputDecoration(
        labelText: "Property",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.apartment),
      ),
      items: _properties.map((property) {
        return DropdownMenuItem(
          value: property,
          child: Text(property.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selected = value;
        });

        widget.onChanged(value);
      },
      validator: (value) {
        if (value == null) {
          return "Please select a property";
        }
        return null;
      },
    );
  }
}