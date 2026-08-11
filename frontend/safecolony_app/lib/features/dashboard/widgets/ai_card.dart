import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';

class AICard extends StatelessWidget {
  final DashboardSummary dashboard;

  const AICard({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final temperature = dashboard.weatherTemperature;
    final weather = temperature == null
        ? 'Weather unavailable'
        : '${temperature.toStringAsFixed(0)}°C${dashboard.weatherCity == null ? '' : ' • ${dashboard.weatherCity}'}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff4F46E5), Color(0xff2563EB)],
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
            const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.auto_awesome, color: Colors.indigo),
                ),
                SizedBox(width: 12),
                Text(
                  'SafeColony AI',
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
              '${dashboard.pendingVisitors} visitor${dashboard.pendingVisitors == 1 ? '' : 's'} waiting for approval',
            ),
            const SizedBox(height: 15),
            _info(
              Icons.inventory_2,
              '${dashboard.pendingDeliveries} delivery${dashboard.pendingDeliveries == 1 ? '' : 'ies'} waiting at the gate',
            ),
            const SizedBox(height: 15),
            _info(
              Icons.shield,
              'Security Score: ${dashboard.securityScore}%',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Recommendation\n\n${dashboard.recommendation}',
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white30),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dashboard.weatherDescription == null
                        ? weather
                        : '$weather • ${dashboard.weatherDescription}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: dashboard.communityStatus == 'Secure'
                      ? Colors.greenAccent
                      : Colors.amberAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  'Community Status: ${dashboard.communityStatus}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
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
