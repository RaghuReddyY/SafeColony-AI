import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor_create_request.dart';
import '../providers/visitor_provider.dart';

import '../../../shared/widgets/selectors/property_selector.dart';
import '../../../shared/widgets/selectors/section_selector.dart';
import '../../../shared/widgets/selectors/unit_selector.dart';
import '../../../shared/widgets/selectors/resident_selector.dart';

import '../../guard/models/guard_property.dart';
import '../../guard/models/guard_section.dart';
import '../../guard/models/guard_unit.dart';
import '../../guard/models/guard_resident.dart';

class WalkInVisitorScreen extends ConsumerStatefulWidget {
  const WalkInVisitorScreen({super.key});

  @override
  ConsumerState<WalkInVisitorScreen> createState() =>
      _WalkInVisitorScreenState();
}

class _WalkInVisitorScreenState
    extends ConsumerState<WalkInVisitorScreen> {

  final _formKey = GlobalKey<FormState>();

  GuardProperty? selectedProperty;
  GuardSection? selectedSection;
  GuardUnit? selectedUnit;
  GuardResident? selectedResident;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final purposeController = TextEditingController();
  final vehicleController = TextEditingController();

  bool loading = false;

  String visitorType = "Guest";

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    purposeController.dispose();
    vehicleController.dispose();
    super.dispose();
  }

  Future<void> createWalkInVisitor() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedResident == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select resident"),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {

      final request = VisitorCreateRequest(

        residentId: selectedResident!.id,

        visitorName: nameController.text.trim(),

        phone: phoneController.text.trim(),

        visitorType: visitorType,

        purpose: purposeController.text.trim(),

        vehicleNumber: vehicleController.text.trim(),

        entryMode: "WALK_IN",

        createdByGuard: true,

      );

      final visitor = await ref
          .read(visitorProvider)
          .createWalkInVisitor(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "${visitor.visitorName} registered successfully",
          ),
        ),
      );

      Navigator.pop(context, true);

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
          loading = false;
        });

      }

    }

  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Walk-In Visitor",
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              PropertySelector(

                initialValue: selectedProperty,

                onChanged: (property) {

                  setState(() {

                    selectedProperty = property;

                    selectedSection = null;
                    selectedUnit = null;
                    selectedResident = null;

                  });

                },

              ),

              const SizedBox(height: 16),

              SectionSelector(

                property: selectedProperty,

                initialValue: selectedSection,

                onChanged: (section) {

                  setState(() {

                    selectedSection = section;

                    selectedUnit = null;
                    selectedResident = null;

                  });

                },

              ),

              const SizedBox(height: 16),

              UnitSelector(

                section: selectedSection,

                initialValue: selectedUnit,

                onChanged: (unit) {

                  setState(() {

                    selectedUnit = unit;

                    selectedResident = null;

                  });

                },

              ),

              const SizedBox(height: 16),

              ResidentSelector(

                unit: selectedUnit,

                initialValue: selectedResident,

                onChanged: (resident) {

                  setState(() {
                    selectedResident = resident;
                  });

                },

              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: nameController,
                decoration: decoration("Visitor Name"),
                validator: (v) =>
                    v == null || v.isEmpty
                        ? "Required"
                        : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                decoration: decoration("Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty
                        ? "Required"
                        : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: visitorType,
                decoration: decoration("Visitor Type"),
                items: const [

                  DropdownMenuItem(
                    value: "Guest",
                    child: Text("Guest"),
                  ),

                  DropdownMenuItem(
                    value: "Family",
                    child: Text("Family"),
                  ),

                  DropdownMenuItem(
                    value: "Service",
                    child: Text("Service"),
                  ),

                  DropdownMenuItem(
                    value: "Delivery",
                    child: Text("Delivery"),
                  ),

                ],
                onChanged: (value) {

                  setState(() {
                    visitorType = value!;
                  });

                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: purposeController,
                decoration: decoration("Purpose"),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: vehicleController,
                decoration: decoration("Vehicle Number"),
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,

                height: 52,

                child: FilledButton.icon(

                  onPressed: loading
                      ? null
                      : createWalkInVisitor,

                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),

                  label: Text(

                    loading
                        ? "Registering..."
                        : "Register Walk-In Visitor",

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}