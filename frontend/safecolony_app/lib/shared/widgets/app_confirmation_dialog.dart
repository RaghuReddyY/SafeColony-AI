import 'package:flutter/material.dart';

class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = "Confirm",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),

      content: Text(message),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),

        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}