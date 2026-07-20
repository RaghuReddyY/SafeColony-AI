import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_primary_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(
                Icons.cloud_off,
                size: 40,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),

              AppPrimaryButton(
                text: "Retry",
                onPressed: onRetry!,
              ),
            ]
          ],
        ),
      ),
    );
  }
}