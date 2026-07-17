import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {

  final String title;

  final String subtitle;

  const EmptyView({
    super.key,
    required this.title,
    required this.subtitle,
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
              Icons.inbox_outlined,
              size: 70,
              color: Colors.grey,
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}