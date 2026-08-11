import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VisitorChart extends StatelessWidget {
  final List<int> weeklyVisitors;

  const VisitorChart({
    super.key,
    required this.weeklyVisitors,
  });

  @override
  Widget build(BuildContext context) {
    final values = weeklyVisitors.length >= 7
        ? weeklyVisitors.take(7).toList()
        : [...weeklyVisitors, ...List<int>.filled(7 - weeklyVisitors.length, 0)];

    final maxValue = values.fold<int>(0, (max, value) => value > max ? value : max);
    final maxY = maxValue == 0 ? 5.0 : (maxValue + 2).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Visitor Trend',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Actual visitor activity for the current week',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigo.withValues(alpha: .15),
                      ),
                      spots: [
                        for (var i = 0; i < 7; i++)
                          FlSpot(i.toDouble(), values[i].toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
