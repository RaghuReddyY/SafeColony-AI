import 'package:flutter/material.dart';

import '../services/delivery_service.dart';

class OTPDialog extends StatefulWidget {
  final int deliveryId;

  const OTPDialog({
    super.key,
    required this.deliveryId,
  });

  @override
  State<OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<OTPDialog> {
  final _otpController = TextEditingController();

  final DeliveryService _service = DeliveryService();

  bool loading = false;

  Future<void> verify() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter OTP"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await _service.verifyOtp(
        deliveryId: widget.deliveryId,
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Package collected successfully",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Invalid OTP",
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Verify OTP"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Ask the resident for the 6-digit OTP.",
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: "OTP",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: loading
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text("Cancel"),
        ),

        ElevatedButton.icon(
          onPressed: loading ? null : verify,
          icon: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle),
          label: const Text("Verify"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}