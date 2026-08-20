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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff4F46E5), Color(0xff2563EB)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final nameSize = compact ? 24.0 : 28.0;

          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: compact ? 58 : 72,
                width: compact ? 58 : 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_work,
                  size: compact ? 28 : 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()} 👋',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: compact ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resident,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: nameSize,
                        height: 1.1,
                      ),
                    ),
                    if (organizationName != null && organizationName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        organizationName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : 15,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: compact ? 13 : 14,
                      ),
                    ),
                    if (organizationCode != null && organizationCode!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ORG: ${organizationCode!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: compact ? 11 : 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final scoreWidget = Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield,
                  color: score >= 80 ? Colors.greenAccent : Colors.amberAccent,
                  size: compact ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$score%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 18 : 20,
                      ),
                    ),
                    const Text(
                      'Security',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: scoreWidget),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 18),
              scoreWidget,
            ],
          );
        },
      ),
    );
  }
}
