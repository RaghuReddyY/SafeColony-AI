import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';

import '../../property/models/property.dart';
import '../../property/providers/property_provider.dart';

import '../../section/models/section.dart';
import '../../section/providers/section_provider.dart';

import '../models/unit.dart';
import '../models/unit_request.dart';
import '../providers/unit_provider.dart';

class UnitFormScreen extends StatefulWidget {
  final Unit? unit;

  const UnitFormScreen({
    super.key,
    this.unit,
  });

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _unitNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _ownerController = TextEditingController();
  final _intercomController = TextEditingController();

  final PropertyProvider _propertyProvider = PropertyProvider();
  final SectionProvider _sectionProvider = SectionProvider();
  final UnitProvider _unitProvider = UnitProvider();

  List<Property> _properties = [];
  List<Section> _sections = [];

  Property? _selectedProperty;
  Section? _selectedSection;

  String _selectedUnitType = "APARTMENT";

  bool _loading = true;
  bool _saving = false;

  final List<String> _unitTypes = const [
    "APARTMENT",
    "VILLA",
    "HOUSE",
    "COMMERCIAL",
    "OFFICE",
    "SHOP",
    "PLOT",
    "OTHER",
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _properties = await _propertyProvider.loadProperties();

      if (widget.unit != null) {
        _unitNumberController.text = widget.unit!.unitNumber;
        _floorController.text = widget.unit!.floor;
        _ownerController.text = widget.unit!.ownerName;
        _intercomController.text = widget.unit!.intercomNumber;

        _selectedUnitType = widget.unit!.unitType;

        _selectedProperty = _properties.firstWhere(
          (p) => p.id == widget.unit!.propertyId,
        );

        await _loadSections(widget.unit!.propertyId);

        _selectedSection = _sections.firstWhere(
          (s) => s.id == widget.unit!.sectionId,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadSections(int propertyId) async {
    _sections =
        await _sectionProvider.getSectionsByProperty(propertyId);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onPropertyChanged(Property? property) async {
    if (property == null) return;

    setState(() {
      _selectedProperty = property;
      _selectedSection = null;
      _sections = [];
    });

    await _loadSections(property.id);
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _floorController.dispose();
    _ownerController.dispose();
    _intercomController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.unit == null
              ? "Create Unit"
              : "Edit Unit",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Property>(
                  value: _selectedProperty,
                  decoration: const InputDecoration(
                    labelText: "Property",
                    prefixIcon: Icon(Icons.apartment),
                  ),
                  items: _properties.map((property) {
                    return DropdownMenuItem(
                      value: property,
                      child: Text(property.name),
                    );
                  }).toList(),
                  onChanged: _onPropertyChanged,
                  validator: (value) {
                    if (value == null) {
                      return "Please select a property";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<Section>(
                  value: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: "Section",
                    prefixIcon: Icon(Icons.dashboard),
                  ),
                  items: _sections.map((section) {
                    return DropdownMenuItem(
                      value: section,
                      child: Text(section.name),
                    );
                  }).toList(),
                  onChanged: (section) {
                    setState(() {
                      _selectedSection = section;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return "Please select a section";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _unitNumberController,
                  hint: "Unit Number",
                  icon: Icons.home,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedUnitType,
                  decoration: const InputDecoration(
                    labelText: "Unit Type",
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _unitTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnitType = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _floorController,
                  hint: "Floor",
                  icon: Icons.layers,
                ),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _ownerController,
                  hint: "Owner Name",
                  icon: Icons.person,
                ),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _intercomController,
                  hint: "Intercom Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 30),

                PrimaryButton(
                    title: _saving
                        ? "Saving..."
                        : widget.unit == null
                            ? "Create Unit"
                            : "Update Unit",
                    onPressed: _saveUnit,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
    Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProperty == null) {
      _showMessage("Please select a property.");
      return;
    }

    if (_selectedSection == null) {
      _showMessage("Please select a section.");
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final request = UnitRequest(
        propertyId: _selectedProperty!.id,
        sectionId: _selectedSection!.id,
        unitNumber: _unitNumberController.text.trim(),
        unitType: _selectedUnitType,
        floor: _floorController.text.trim(),
        ownerName: _ownerController.text.trim(),
        intercomNumber: _intercomController.text.trim(),
      );

      if (widget.unit == null) {
        await _unitProvider.createUnit(request);

        _showMessage("Unit created successfully.");
      } else {
        await _unitProvider.updateUnit(
          widget.unit!.id,
          request,
        );

        _showMessage("Unit updated successfully.");
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage(e.toString());
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}