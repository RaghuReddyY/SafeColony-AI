import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String resident;
  final String unit;
  final String? block;
  final String? organizationName;
  final String? organizationCode;
  final int score;

  const DashboardHeader({
    super.key,
    required this.resident,
    required this.unit,
    this.block,
    this.organizationName,
    this.organizationCode,
    required this.score,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

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
          colors: [Color(0xff4F46E5), Color(0xff2563EB)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final identity = Row(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()} 👋',
                      style: const TextStyle(
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
                    if (organizationName != null && organizationName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        organizationName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (block != null && block!.trim().isNotEmpty) block!,
                        'Unit $unit',
                      ].join(' • '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (organizationCode != null && organizationCode!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'ORG: ${organizationCode!}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final scoreWidget = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shield,
                  color: score >= 80
                      ? Colors.greenAccent
                      : Colors.amberAccent,
                ),
                const SizedBox(height: 8),
                Text(
                  '$score%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  'Security',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: scoreWidget,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              scoreWidget,
            ],
          );
        },
      ),
    );
  }
}
