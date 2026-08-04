import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vacation_create_request.dart';
import '../providers/vacation_provider.dart';

class AddVacationScreen extends ConsumerStatefulWidget {
  const AddVacationScreen({super.key});

  @override
  ConsumerState<AddVacationScreen> createState() =>
      _AddVacationScreenState();
}

class _AddVacationScreenState
    extends ConsumerState<AddVacationScreen> {

  DateTime? startDate;
  DateTime? endDate;

  final reasonController = TextEditingController();
  final emergencyController = TextEditingController();

  String visitorPolicy = "REJECT_ALL";
  String deliveryPolicy = "ALLOW";

  bool notifySecurity = true;
  bool monitoringEnabled = true;

  bool loading = false;

  Future<void> pickStartDate() async {

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        startDate = date;
      });
    }
  }

  Future<void> pickEndDate() async {

    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        endDate = date;
      });
    }
  }

  Future<void> submit() async {

    if (startDate == null || endDate == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select vacation dates"),
        ),
      );

      return;
    }

   
    final request = VacationCreateRequest(

      startDate: startDate!,

      endDate: endDate!,

      reason: reasonController.text,

      emergencyContact: emergencyController.text,

      visitorPolicy: visitorPolicy,

      deliveryPolicy: deliveryPolicy,

      notifySecurity: notifySecurity,

      monitoringEnabled: monitoringEnabled,

    );

    setState(() {
      loading = true;
    });

    try {

      await ref
          .read(vacationProvider)
          .enableVacation(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vacation Enabled Successfully"),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Enable Vacation Mode"),
      ),

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          ElevatedButton(
            onPressed: pickStartDate,
            child: Text(
              startDate == null
                  ? "Select Start Date"
                  : startDate.toString().split(" ").first,
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: pickEndDate,
            child: Text(
              endDate == null
                  ? "Select End Date"
                  : endDate.toString().split(" ").first,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: "Reason",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: emergencyController,
            decoration: const InputDecoration(
              labelText: "Emergency Contact",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: visitorPolicy,
            decoration: const InputDecoration(
              labelText: "Visitor Policy",
              border: OutlineInputBorder(),
            ),
            items: const [

              DropdownMenuItem(
                value: "REJECT_ALL",
                child: Text("Reject All"),
              ),

              DropdownMenuItem(
                value: "ALLOW_ALL",
                child: Text("Allow All"),
              ),

            ],
            onChanged: (v) {
              visitorPolicy = v!;
            },
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: deliveryPolicy,
            decoration: const InputDecoration(
              labelText: "Delivery Policy",
              border: OutlineInputBorder(),
            ),
            items: const [

              DropdownMenuItem(
                value: "ALLOW",
                child: Text("Allow"),

              ),

              DropdownMenuItem(
                value: "HOLD",
                child: Text("Hold"),

              ),

            ],
            onChanged: (v) {
              deliveryPolicy = v!;
            },
          ),

          const SizedBox(height: 20),

          SwitchListTile(

            value: notifySecurity,

            title: const Text("Notify Security"),

            onChanged: (v) {

              setState(() {

                notifySecurity = v;

              });

            },

          ),

          SwitchListTile(

            value: monitoringEnabled,

            title: const Text("Enable Monitoring"),

            onChanged: (v) {

              setState(() {

                monitoringEnabled = v;

              });

            },

          ),

          const SizedBox(height: 30),

          SizedBox(

            height: 50,

            child: ElevatedButton(

              onPressed: loading ? null : submit,

              child: loading

                  ? const CircularProgressIndicator()

                  : const Text("Enable Vacation"),

            ),

          ),

        ],

      ),

    );

  }

}