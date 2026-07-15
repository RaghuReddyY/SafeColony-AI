import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String resident;
  final String unit;
  final int score;

  const DashboardHeader({
    super.key,
    required this.resident,
    required this.unit,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff4F46E5),
            Color(0xff2563EB),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work,
              size: 34,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Good Morning 👋",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resident,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Unit $unit",
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.shield,
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: 8),
                Text(
                  "$score%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  "Security",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}