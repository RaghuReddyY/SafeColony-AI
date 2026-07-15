import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VisitorChart extends StatelessWidget {
  const VisitorChart({super.key});

  @override
  Widget build(BuildContext context) {
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
              "Weekly Visitor Trend",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),

                  borderData: FlBorderData(
                    show: false,
                  ),

                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget:
                            (value, meta) {

                          const days = [
                            "Mon",
                            "Tue",
                            "Wed",
                            "Thu",
                            "Fri",
                            "Sat",
                            "Sun"
                          ];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                                    top: 8),
                            child: Text(
                              days[value.toInt()],
                              style:
                                  const TextStyle(
                                fontSize: 12,
                              ),
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

                      dotData:
                          const FlDotData(
                        show: true,
                      ),

                      belowBarData:
                          BarAreaData(
                        show: true,
                        color: Colors.indigo
                            .withValues(alpha: .15),
                      ),

                      spots: const [

                        FlSpot(0, 4),
                        FlSpot(1, 8),
                        FlSpot(2, 6),
                        FlSpot(3, 12),
                        FlSpot(4, 10),
                        FlSpot(5, 14),
                        FlSpot(6, 11),
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