import 'package:flutter/material.dart';

import '../../../features/guard/models/guard_property.dart';
import '../../../features/guard/models/guard_section.dart';
import '../../../features/guard/services/guard_lookup_service.dart';

class SectionSelector extends StatefulWidget {
  final GuardProperty? property;
  final GuardSection? initialValue;
  final ValueChanged<GuardSection?> onChanged;

  const SectionSelector({
    super.key,
    required this.property,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SectionSelector> createState() =>
      _SectionSelectorState();
}

class _SectionSelectorState
    extends State<SectionSelector> {

  final GuardLookupService _service =
      GuardLookupService();

  List<GuardSection> _sections = [];

  GuardSection? _selected;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _selected = widget.initialValue;

    if (widget.property != null) {
      _loadSections();
    }
  }

  @override
  void didUpdateWidget(
      covariant SectionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.property?.id != widget.property?.id) {

      _selected = null;
      _sections = [];

      // Notify parent AFTER current build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onChanged(null);
      });

      if (widget.property != null) {
        _loadSections();
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _loadSections() async {

    if (widget.property == null) return;

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {

      final data = await _service.getSections(
        widget.property!.id,
      );

      if (!mounted) return;

      setState(() {
        _sections = data;
        _selected = null;
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
            "Unable to load sections",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (widget.property == null) {

      return DropdownButtonFormField<GuardSection>(
        value: null,
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: "Section",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.dashboard),
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

    return DropdownButtonFormField<GuardSection>(
      value: _selected,
      decoration: const InputDecoration(
        labelText: "Section",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.dashboard),
      ),
      items: _sections
          .map(
            (section) => DropdownMenuItem(
              value: section,
              child: Text(section.name),
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
          return "Please select a section";
        }
        return null;
      },
    );
  }
}