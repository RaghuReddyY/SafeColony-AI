import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {

  final String message;

  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {

    return Center(

      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),

            const SizedBox(height: 20),

            Text(
              message,
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[

              const SizedBox(height: 20),

              FilledButton(
                onPressed: onRetry,
                child: const Text("Retry"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}