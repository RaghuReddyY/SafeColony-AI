import 'package:flutter/material.dart';

class ResidentApprovalScreen extends StatelessWidget {
  const ResidentApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resident Approvals"),
      ),
      body: const Center(
        child: Text(
          "Pending Residents",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}