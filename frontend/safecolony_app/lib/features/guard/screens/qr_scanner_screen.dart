import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/guard_provider.dart';
import 'guard_scan_result_screen.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() =>
      _QRScannerScreenState();
}

class _QRScannerScreenState
    extends ConsumerState<QRScannerScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateQR() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(guardProvider.notifier)
        .validateQR(_controller.text.trim());

    if (!mounted) return;

    final state = ref.read(guardProvider);

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
        ),
      );
      return;
    }

    if (state.visitor != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuardScanResultScreen(
            visitor: state.visitor!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Validate Visitor QR"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(
                Icons.qr_code,
                size: 90,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "QR Token",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Enter QR token";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      state.isLoading ? null : _validateQR,
                  child: state.isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Validate QR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}