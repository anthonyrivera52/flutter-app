import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningChart extends StatelessWidget {
  final List<DailyEarning> dailyEarnings;

  const EarningChart({super.key, required this.dailyEarnings});

  @override
  Widget build(BuildContext context) {
    if (dailyEarnings.isEmpty) {
      return Container();
    }

    // Determine min/max Y for chart scaling
    double maxY = dailyEarnings.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    maxY = (maxY * 1.2).ceilToDouble(); // Add some padding
    if (maxY == 0) maxY = 100; // Prevent division by zero if all earnings are zero

    // Create BarChartGroupData for each day
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < dailyEarnings.length; i++) {
      final dailyEarning = dailyEarnings[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyEarning.amount,
              color: Theme.of(context).primaryColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dailyEarnings.length) {
                    final date = dailyEarnings[index].date;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4.0,
                      child: Text(
                        DateFormat('EEE').format(date), // Day of week (e.g., Mon, Tue)
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(), // Show integer values for Y-axis
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
                interval: (maxY / 4).ceilToDouble(), // Dynamic interval
                reservedSize: 28,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dailyEarning = dailyEarnings[group.x];
                return BarTooltipItem(
                  '${DateFormat('MMM dd').format(dailyEarning.date)}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: '\$${rod.toY.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          maxY: maxY,
        ),
      ),
    );
  }
}