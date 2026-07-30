import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';

import '../../section/screens/section_list_screen.dart';
import '../models/property.dart';
import '../models/property_request.dart';
import '../providers/property_provider.dart';

class PropertyFormScreen extends ConsumerStatefulWidget {
  final Property? property;

  const PropertyFormScreen({
    super.key,
    this.property,
  });

  @override
  ConsumerState<PropertyFormScreen> createState() =>
      _PropertyFormScreenState();
}

class _PropertyFormScreenState
    extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController =
      TextEditingController(text: "India");
  final _pincodeController = TextEditingController();

  String _propertyType = "APARTMENT";
  bool _hasMultipleSections = false;
  bool _saving = false;

  bool get _isEdit => widget.property != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final property = widget.property!;

      _nameController.text = property.name;
      _addressController.text = property.address;
      _cityController.text = property.city;
      _stateController.text = property.state;
      _countryController.text = property.country;
      _pincodeController.text = property.pincode;

      _propertyType = property.propertyType;
      _hasMultipleSections = property.hasMultipleSections;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final request = PropertyRequest(
        name: _nameController.text.trim(),
        propertyType: _propertyType,
        hasMultipleSections: _hasMultipleSections,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        pincode: _pincodeController.text.trim(),
      );

      Property createdProperty;

      if (_isEdit) {
        createdProperty = await ref
            .read(propertyProvider)
            .updateProperty(widget.property!.id, request);
      } else {
        createdProperty = await ref
            .read(propertyProvider)
            .createProperty(request);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            _isEdit
                ? "Property updated successfully."
                : "Property created successfully.",
          ),
        ),
      );

      if (_isEdit) {
        Navigator.pop(context, true);
      } else if (createdProperty.hasMultipleSections) {
        final result = await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SectionListScreen(
              propertyId: createdProperty.id,
              isSetupFlow: true,
            ),
          ),
        );

        if (mounted) {
          Navigator.pop(context, result ?? true);
        }
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildForm() {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isEdit ? Icons.edit : Icons.apartment,
              size: 70,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            Text(
              _isEdit
                  ? "Edit Property"
                  : "Create Property",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            AppTextField(
              controller: _nameController,
              hint: "Property Name",
              icon: Icons.business,
            ),

            const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
              value: _propertyType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.apartment),
                border: OutlineInputBorder(),
                labelText: "Property Type",
              ),
              items: const [
                DropdownMenuItem(
                  value: "APARTMENT",
                  child: Text("Apartment"),
                ),
                DropdownMenuItem(
                  value: "VILLA",
                  child: Text("Villa"),
                ),
                DropdownMenuItem(
                  value: "GATED_COMMUNITY",
                  child: Text("Gated Community"),
                ),
                DropdownMenuItem(
                  value: "RESIDENTIAL_LAYOUT",
                  child: Text("Residential Layout"),
                ),
                DropdownMenuItem(
                  value: "OFFICE_CAMPUS",
                  child: Text("Office Campus"),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _propertyType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Property has multiple sections",
              ),
              subtitle: const Text(
                "Examples: Block A, Block B, Wing A, Wing B",
              ),
              value: _hasMultipleSections,
              onChanged: (value) {
                setState(() {
                  _hasMultipleSections = value;
                });
              },
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _addressController,
              hint: "Address",
              icon: Icons.location_on,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cityController,
                    hint: "City",
                    icon: Icons.location_city,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _stateController,
                    hint: "State",
                    icon: Icons.map,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _countryController,
                    hint: "Country",
                    icon: Icons.public,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _pincodeController,
                    hint: "Pincode",
                    icon: Icons.pin_drop,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            _saving
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : PrimaryButton(
                    title: _isEdit
                        ? "UPDATE PROPERTY"
                        : "CREATE PROPERTY",
                    onPressed: _saveProperty,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? "Edit Property"
              : "Create Property",
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 600,
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }
}