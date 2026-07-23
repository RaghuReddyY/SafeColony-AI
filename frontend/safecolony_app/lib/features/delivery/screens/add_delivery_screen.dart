import 'package:flutter/material.dart';

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

  List<dynamic> residents = [];

  int? residentId;

  String category = "PACKAGE";

  String priority = "NORMAL";

  bool loading = true;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    loadResidents();
  }

  Future<void> loadResidents() async {
    try {
      residents =
          await _service.getResidents();

      if (residents.isNotEmpty) {
        residentId = residents.first["id"];
      }
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> registerDelivery() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await _service.createDelivery(
        residentId: residentId!,
        courierName:
            _courierController.text.trim(),
        deliveryCategory: category,
        trackingNumber:
            _trackingController.text.trim(),
        priority: priority,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              "Delivery Registered"),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Register Delivery")),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller:
                        _courierController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Courier Name",
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty
                            ? "Required"
                            : null,
                  ),
                  const SizedBox(
                      height: 20),
                  DropdownButtonFormField<int>(
                    initialValue: residentId,
                    decoration:
                        const InputDecoration(
                      labelText: "Resident",
                      border:
                          OutlineInputBorder(),
                    ),
                    items: residents
                        .map<
                            DropdownMenuItem<
                                int>>(
                      (e) =>
                          DropdownMenuItem<
                              int>(
                        value: e["id"],
                        child: Text(
                          "${e["name"]} (${e["flat"]})",
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        residentId = v;
                      });
                    },
                  ),
                  const SizedBox(
                      height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Category",
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "PACKAGE",
                        child: Text(
                            "Package"),
                      ),
                      DropdownMenuItem(
                        value: "FOOD",
                        child:
                            Text("Food"),
                      ),
                      DropdownMenuItem(
                        value: "MEDICINE",
                        child: Text(
                            "Medicine"),
                      ),
                      DropdownMenuItem(
                        value: "OTHER",
                        child:
                            Text("Other"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        category = v!;
                      });
                    },
                  ),
                  const SizedBox(
                      height: 20),
                  TextFormField(
                    controller:
                        _trackingController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Tracking Number",
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(
                      height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Priority",
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "NORMAL",
                        child:
                            Text("Normal"),
                      ),
                      DropdownMenuItem(
                        value: "HIGH",
                        child:
                            Text("High"),
                      ),
                      DropdownMenuItem(
                        value: "URGENT",
                        child:
                            Text("Urgent"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        priority = v!;
                      });
                    },
                  ),
                  const SizedBox(
                      height: 35),
                  SizedBox(
                    height: 55,
                    child:
                        ElevatedButton.icon(
                      onPressed: saving
                          ? null
                          : registerDelivery,
                      icon: const Icon(
                          Icons.save),
                      label: saving
                          ? const CircularProgressIndicator()
                          : const Text(
                              "Register Delivery"),
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