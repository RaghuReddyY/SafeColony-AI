import 'package:flutter/material.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}