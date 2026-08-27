import 'package:flutter/material.dart';

import '../models/delivery.dart';
import '../services/delivery_service.dart';
import '../widgets/delivery_status_chip.dart';
import '../widgets/otp_dialog.dart';

import '../../../shared/widgets/selectors/property_selector.dart';
import '../../../shared/widgets/selectors/section_selector.dart';
import '../../../shared/widgets/selectors/unit_selector.dart';
import '../../../shared/widgets/selectors/resident_selector.dart';

import '../../guard/models/guard_property.dart';
import '../../guard/models/guard_section.dart';
import '../../guard/models/guard_unit.dart';
import '../../guard/models/guard_resident.dart';

class GuardDeliveryScreen extends StatefulWidget {
  const GuardDeliveryScreen({super.key});

  @override
  State<GuardDeliveryScreen> createState() =>
      _GuardDeliveryScreenState();
}

class _GuardDeliveryScreenState
    extends State<GuardDeliveryScreen> {
  final DeliveryService _service = DeliveryService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _courierController =
      TextEditingController();
  final TextEditingController _trackingController =
      TextEditingController();

  GuardProperty? selectedProperty;
  GuardSection? selectedSection;
  GuardUnit? selectedUnit;
  GuardResident? selectedResident;

  String _category = "PACKAGE";
  String _priority = "NORMAL";

  bool _creating = false;
  bool _loadingPending = true;
  String? _pendingError;
  List<Delivery> _pendingDeliveries = [];

  @override
  void initState() {
    super.initState();
    _loadPendingDeliveries();
  }

  @override
  void dispose() {
    _courierController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingDeliveries() async {
    setState(() {
      _loadingPending = true;
      _pendingError = null;
    });

    try {
      final deliveries =
          await _service.getGuardPendingDeliveries();

      if (!mounted) return;

      setState(() {
        _pendingDeliveries = deliveries;
        _loadingPending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingPending = false;
        _pendingError = e.toString();
      });
    }
  }

  Future<void> _createDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedProperty == null) {
      _showMessage("Please select property.");
      return;
    }

    if (selectedSection == null) {
      _showMessage("Please select section.");
      return;
    }

    if (selectedUnit == null) {
      _showMessage("Please select unit.");
      return;
    }

    if (selectedResident == null) {
      _showMessage("Please select resident.");
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      await _service.createGuardDelivery(
        residentId: selectedResident!.id,
        courierName: _courierController.text.trim(),
        deliveryCategory: _category,
        trackingNumber:
            _trackingController.text.trim().isEmpty
                ? null
                : _trackingController.text.trim(),
        priority: _priority,
      );

      if (!mounted) return;

      _courierController.clear();
      _trackingController.clear();

      setState(() {
        selectedProperty = null;
        selectedSection = null;
        selectedUnit = null;
        selectedResident = null;
        _category = "PACKAGE";
        _priority = "NORMAL";
      });

      _showMessage(
        "Delivery created successfully. Resident has been notified.",
        success: true,
      );

      await _loadPendingDeliveries();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        "Failed to create delivery: $e",
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  Future<void> _receiveDelivery(Delivery delivery) async {
    try {
      // The guard confirms physical receipt first. This is intentionally
      // separate from resident collection/OTP verification so the resident
      // gets a clear "received at gate" notification immediately.
      final result = await _service.receiveDelivery(
        deliveryId: delivery.id,
        guardName: "Security Guard",
      );

      if (!mounted) return;

      _showMessage(
        "Delivery received at gate. Resident has been notified.",
        success: true,
      );

      // Refresh so the card changes to "Collect with Resident OTP".
      await _loadPendingDeliveries();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        "Unable to receive delivery: $e",
        success: false,
      );
    }
  }

  Future<void> _collectDelivery(Delivery delivery) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OTPDialog(
        deliveryId: delivery.id,
      ),
    );

    if (result == true && mounted) {
      await _loadPendingDeliveries();
    }
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            success ? Colors.green : Colors.red,
        content: Text(message),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPendingDeliveries() {
    if (_loadingPending) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_pendingError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                _pendingError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadPendingDeliveries,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingDeliveries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: const [
              Icon(
                Icons.inventory_2_outlined,
                size: 46,
                color: Colors.grey,
              ),
              SizedBox(height: 10),
              Text(
                "No pending deliveries",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Packages waiting for resident collection will appear here.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _pendingDeliveries.map((delivery) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.inventory_2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            delivery.courierName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(delivery.deliveryCategory),
                        ],
                      ),
                    ),
                    DeliveryStatusChip(
                      status: delivery.status,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Tracking: ${delivery.trackingNumber ?? '-'}",
                ),
                const SizedBox(height: 4),
                Text(
                  "Priority: ${delivery.priority}",
                ),
                if (delivery.receivedBy != null &&
                    delivery.receivedBy!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Received at gate by: ${delivery.receivedBy}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: delivery.receivedBy == null ||
                          delivery.receivedBy!.trim().isEmpty
                      ? ElevatedButton.icon(
                          onPressed: () =>
                              _receiveDelivery(delivery),
                          icon: const Icon(Icons.inventory_2),
                          label: const Text(
                            "Receive at Security Gate",
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () =>
                              _collectDelivery(delivery),
                          icon: const Icon(Icons.lock_open),
                          label: const Text(
                            "Collect with Resident OTP",
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Guard Deliveries"),
        actions: [
          IconButton(
            onPressed: _loadPendingDeliveries,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingDeliveries,
        child: ListView(
          padding: const EdgeInsets.all(24),
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
              "Register a package received at the security gate.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                    controller: _courierController,
                    enabled: !_creating,
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
                      labelText: "Delivery Category",
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
                    onChanged: _creating
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
                    enabled: !_creating,
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
                    onChanged: _creating
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _priority = value;
                            });
                          },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          _creating ? null : _createDelivery,
                      icon: _creating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_box),
                      label: Text(
                        _creating
                            ? "Creating..."
                            : "Register Delivery",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Divider(height: 1),
            const SizedBox(height: 28),
            _sectionTitle("Pending Deliveries"),
            _buildPendingDeliveries(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
