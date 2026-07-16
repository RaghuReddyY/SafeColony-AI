import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';

class AddVisitorScreen extends ConsumerStatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  ConsumerState<AddVisitorScreen> createState() =>
      _AddVisitorScreenState();
}

class _AddVisitorScreenState
    extends ConsumerState<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final purposeController = TextEditingController();
  final vehicleController = TextEditingController();

  String visitorType = "Guest";

  bool loading = false;

  Future<void> saveVisitor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final visitor = Visitor(
        id: 0,
        residentId: 2,
        visitorName: nameController.text,
        phone: phoneController.text,
        visitorType: visitorType,
        purpose: purposeController.text,
        vehicleNumber: vehicleController.text,
        status: "PENDING",
        qrToken: null,
        qrCode: null,
        approvedAt: null,
      );

      await ref
          .read(visitorProvider)
          .createVisitor(visitor);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Visitor"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Visitor Name",
                ),
                validator: (v) =>
                    v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone",
                ),
                validator: (v) =>
                    v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: visitorType,
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
                ],
                onChanged: (value) {
                  visitorType = value!;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: "Purpose",
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: vehicleController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      loading ? null : saveVisitor,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Create Visitor"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}