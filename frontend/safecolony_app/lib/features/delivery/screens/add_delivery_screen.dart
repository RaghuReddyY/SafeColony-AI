import 'package:flutter/material.dart';

import '../models/delivery.dart';
import '../services/delivery_service.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() =>
      _AddDeliveryScreenState();
}

class _AddDeliveryScreenState
    extends State<AddDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _courierController =
      TextEditingController();

  final _trackingController =
      TextEditingController();

  final DeliveryService _service =
      DeliveryService();

  String? _propertyName;
  String? _sectionName;
  String? _unitNumber;

  String _category = "PACKAGE";
  String _priority = "NORMAL";

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadResidentContext();
  }

  Future<void> _loadResidentContext() async {
    try {
      final profile =
          await _service.getMyResidentProfile();

      if (!mounted) return;

      setState(() {
        _propertyName = profile["property_name"];
        _sectionName = profile["section_name"];
        _unitNumber = profile["unit_number"];
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _registerDelivery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Delivery delivery =
          await _service.createDelivery(
        courierName:
            _courierController.text.trim(),
        deliveryCategory: _category,
        trackingNumber:
            _trackingController.text.trim().isEmpty
                ? null
                : _trackingController.text.trim(),
        priority: _priority,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Delivery registered. OTP: ${delivery.otp ?? 'available in Delivery Details'}",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to create delivery: $e",
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Register Delivery"),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Unable to load your delivery context.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadResidentContext,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "Register Delivery",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Register a delivery for your residence.",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // The resident is determined from the logged-in
                      // account. Show the resolved property/section/unit
                      // as read-only context instead of a resident dropdown.
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.home_outlined),
                                  SizedBox(width: 10),
                                  Text(
                                    "Delivery For",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                [
                                  if (_propertyName?.isNotEmpty == true)
                                    _propertyName!,
                                  if (_sectionName?.isNotEmpty == true)
                                    _sectionName!,
                                  if (_unitNumber?.isNotEmpty == true)
                                    "Unit $_unitNumber",
                                ].join("  •  "),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _courierController,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: "Courier Name",
                          hintText: "e.g. Amazon / Zomato",
                          prefixIcon:
                              Icon(Icons.delivery_dining),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return "Enter courier name.";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          prefixIcon:
                              Icon(Icons.inventory_2),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "PACKAGE",
                            child: Text("Package"),
                          ),
                          DropdownMenuItem(
                            value: "FOOD",
                            child: Text("Food"),
                          ),
                          DropdownMenuItem(
                            value: "GROCERY",
                            child: Text("Grocery"),
                          ),
                          DropdownMenuItem(
                            value: "MEDICINE",
                            child: Text("Medicine"),
                          ),
                          DropdownMenuItem(
                            value: "OTHER",
                            child: Text("Other"),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _category = value;
                                });
                              },
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _trackingController,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: "Tracking Number",
                          hintText: "Optional",
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: "Priority",
                          prefixIcon:
                              Icon(Icons.priority_high),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "NORMAL",
                            child: Text("Normal"),
                          ),
                          DropdownMenuItem(
                            value: "HIGH",
                            child: Text("High"),
                          ),
                          DropdownMenuItem(
                            value: "URGENT",
                            child: Text("Urgent"),
                          ),
                          DropdownMenuItem(
                            value: "MEDICINE",
                            child: Text("Medicine"),
                          ),
                          DropdownMenuItem(
                            value: "PERISHABLE",
                            child: Text("Perishable"),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _priority = value;
                                });
                              },
                      ),

                      const SizedBox(height: 35),

                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed:
                              _saving ? null : _registerDelivery,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _saving
                                ? "Registering..."
                                : "Register Delivery",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _courierController.dispose();
    _trackingController.dispose();
    super.dispose();
  }
}
