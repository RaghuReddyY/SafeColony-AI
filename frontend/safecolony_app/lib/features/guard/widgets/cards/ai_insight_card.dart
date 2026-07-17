import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';

class AIInsightCard extends StatelessWidget {
  final String message;

  const AIInsightCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.deepPurple,
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "AI Insight",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}