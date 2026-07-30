import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';

import '../../property/models/property.dart';
import '../../property/providers/property_provider.dart';

import '../models/section.dart';
import '../models/section_request.dart';
import '../providers/section_provider.dart';

class SectionFormScreen extends ConsumerStatefulWidget {
  final Section? section;
  final int? propertyId;

  const SectionFormScreen({
    super.key,
    this.section,
    this.propertyId,
  });

  @override
  ConsumerState<SectionFormScreen> createState() =>
      _SectionFormScreenState();
}

class _SectionFormScreenState
    extends ConsumerState<SectionFormScreen> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _saving = false;

  bool get _isEdit => widget.section != null;

  List<Property> _properties = [];

  int? _selectedPropertyId;

  @override
  void initState() {
    super.initState();

    _selectedPropertyId = widget.propertyId;

    if (_isEdit) {
      _nameController.text = widget.section!.name;
      _descriptionController.text =
          widget.section!.description;

      _selectedPropertyId =
          widget.section!.propertyId;
    }

    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final properties =
        await ref.read(propertyProvider)
            .loadProperties();

    if (!mounted) return;

    setState(() {
      _properties = properties;

      if (_selectedPropertyId == null &&
          properties.isNotEmpty) {
        _selectedPropertyId =
            properties.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSection() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPropertyId == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a property",
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {

      final request = SectionRequest(
        propertyId: _selectedPropertyId!,
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim(),
      );

      if (_isEdit) {

        await ref
            .read(sectionProvider)
            .updateSection(
              widget.section!.id,
              request,
            );

      } else {

        await ref
            .read(sectionProvider)
            .createSection(
              request,
            );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            _isEdit
                ? "Section updated successfully."
                : "Section created successfully.",
          ),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [

            Icon(
              _isEdit
                  ? Icons.edit
                  : Icons.dashboard,
              size: 70,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            Text(
              _isEdit
                  ? "Edit Section"
                  : "Create Section",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

if (widget.propertyId == null)
  DropdownButtonFormField<int>(
    value: _selectedPropertyId,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.apartment),
      labelText: "Property",
    ),
    items: _properties
        .map(
          (property) => DropdownMenuItem(
            value: property.id,
            child: Text(property.name),
          ),
        )
        .toList(),
    onChanged: (value) {
      setState(() {
        _selectedPropertyId = value;
      });
    },
  ),

            if (widget.propertyId == null)
              const SizedBox(height: 16),

            AppTextField(
              controller: _nameController,
              hint: "Section Name",
              icon: Icons.business,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller:
                  _descriptionController,
              hint: "Description",
              icon: Icons.description,
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            _saving
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : PrimaryButton(
                    title: _isEdit
                        ? "UPDATE SECTION"
                        : "CREATE SECTION",
                    onPressed:
                        _saveSection,
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
              ? "Edit Section"
              : "Create Section",
        ),
      ),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
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