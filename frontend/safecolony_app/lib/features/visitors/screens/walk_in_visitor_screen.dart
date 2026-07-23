import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor_create_request.dart';
import '../providers/visitor_provider.dart';
import '../../../shared/widgets/selectors/resident_selector.dart';
import '../../resident/models/resident_dropdown.dart';

class WalkInVisitorScreen extends ConsumerStatefulWidget {
  const WalkInVisitorScreen({super.key});

  @override
  ConsumerState<WalkInVisitorScreen> createState() =>
      _WalkInVisitorScreenState();
}

class _WalkInVisitorScreenState
    extends ConsumerState<WalkInVisitorScreen> {
  final _formKey = GlobalKey<FormState>();

ResidentDropdown? selectedResident;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final purposeController = TextEditingController();
  final vehicleController = TextEditingController();

  String visitorType = "Guest";

  bool loading = false;


  Future<void> createWalkInVisitor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
if (selectedResident == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please select a resident"),
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
        vehicleNumber:
            vehicleController.text.trim(),
        entryMode: "WALK_IN",
        createdByGuard: true,
      );

      final visitor = await ref
          .read(visitorProvider)
          .createVisitor(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Walk-in Visitor ${visitor.visitorName} created successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
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
        title:
            const Text("Walk-In Visitor Registration"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// Resident ID
ResidentSelector(
  initialValue: selectedResident,
  onChanged: (resident) {
    setState(() {
      selectedResident = resident;
    });
  },
),

              const SizedBox(height: 16),

              /// Visitor Name
              TextFormField(
                controller: nameController,
                decoration:
                    decoration("Visitor Name"),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Visitor name is required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    decoration("Phone Number"),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Phone number is required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Visitor Type
              DropdownButtonFormField<String>(
                initialValue: visitorType,
                decoration:
                    decoration("Visitor Type"),
                items: const [
                  DropdownMenuItem(
                    value: "Guest",
                    child: Text("Guest"),
                  ),
                  DropdownMenuItem(
                    value: "Delivery",
                    child: Text("Delivery"),
                  ),
                  DropdownMenuItem(
                    value: "Family",
                    child: Text("Family"),
                  ),
                  DropdownMenuItem(
                    value: "Service",
                    child: Text("Service"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    visitorType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              /// Purpose
              TextFormField(
                controller: purposeController,
                decoration:
                    decoration("Purpose"),
              ),

              const SizedBox(height: 16),

              /// Vehicle
              TextFormField(
                controller: vehicleController,
                decoration:
                    decoration("Vehicle Number"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: loading
                      ? null
                      : createWalkInVisitor,
                  icon: const Icon(Icons.badge),
                  label: loading
                      ? const CircularProgressIndicator()
                      : const Text(
                          "Register Walk-In Visitor",
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