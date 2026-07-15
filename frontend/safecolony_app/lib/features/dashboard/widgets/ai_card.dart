import 'package:flutter/material.dart';

class AICard extends StatelessWidget {
  const AICard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff4F46E5),
            Color(0xff2563EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.indigo,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "SafeColony AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _info(
              Icons.people,
              "2 Visitors waiting for approval",
            ),

            const SizedBox(height: 15),

            _info(
              Icons.inventory_2,
              "1 Delivery expected today",
            ),

            const SizedBox(height: 15),

            _info(
              Icons.shield,
              "Security Score : 92%",
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "Recommendation\n\nApprove today's pending visitor before 6:00 PM for a smoother entry experience.",
                style: TextStyle(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Divider(
              color: Colors.white30,
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Colors.amber,
                ),
                SizedBox(width: 10),
                Text(
                  "29°C  •  Bangalore",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                ),
                SizedBox(width: 10),
                Text(
                  "Community Status : Secure",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}