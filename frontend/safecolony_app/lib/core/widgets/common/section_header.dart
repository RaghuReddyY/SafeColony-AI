import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {

  final String title;

  final String? actionText;

  final VoidCallback? onPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (actionText != null)

          TextButton(
            onPressed: onPressed,
            child: Text(actionText!),
          ),
      ],
    );
  }
}