import 'package:delivery_app_mvvm/domain/entities/earning.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Make sure you have this import for DateFormat

// Assuming your DailyEarning model looks like this:
// lib/model/daily_earning_model.dart (or domain/entities/daily_earning.dart)
// class DailyEarning {
//   final String date; // This is the String that needs parsing
//   final double amount;
//   DailyEarning({required this.date, required this.amount});
// }

class EarningChart extends StatelessWidget {
  final List<DailyEarning> dailyEarnings;

  const EarningChart({super.key, required this.dailyEarnings});

  @override
  Widget build(BuildContext context) {
    if (dailyEarnings.isEmpty) {
      return const Center(child: Text('No hay datos para el gráfico.'));
    }

    // --- Prepare BarChartGroupData ---
    // Ensure that dailyEarnings are sorted by date ascending for correct chart display
    dailyEarnings.sort((a, b) => DateTime.parse(a.date.toString()).compareTo(DateTime.parse(b.date.toString())));

    // Create a map to store BarChartGroupData, using a numerical x-value (e.g., 0, 1, 2...)
    // This makes mapping back to dates for titles easier and more robust than `day.toInt()`
    // which can lead to collisions if your chart spans across month boundaries or has missing days.
    List<BarChartGroupData> barGroups = [];
    // We'll also build a map from the x-index back to the actual date for titles
    Map<int, DateTime> indexToDateMap = {};

    for (int i = 0; i < dailyEarnings.length; i++) {
      final DailyEarning earning = dailyEarnings[i];

      // **** THIS IS THE CRUCIAL LINE FOR PARSING THE DATE STRING ****
      // Ensure earning.date (which is a String) is converted to DateTime
      final DateTime chartDate = DateTime.parse(earning.date.toString()); // FIX: Parse the string to DateTime

      // Use the index 'i' as the x-value for each bar.
      // fl_chart's x-values should ideally be continuous integers for simple bar charts.
      final int xValue = i;

      barGroups.add(
        BarChartGroupData(
          x: xValue, // X-axis value (should be an int or a double representing int)
          barRods: [
            BarChartRodData(
              toY: earning.amount, // Y-axis value (the earnings amount)
              color: Colors.blue, // Example color
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      indexToDateMap[xValue] = chartDate; // Store the mapping for titles
    }

    // --- Determine max Y value for the chart ---
    double maxY = dailyEarnings.map((e) => e.amount).fold(0.0, (prev, current) => prev > current ? prev : current);
    // Add some padding to the max Y value for better visual. Make sure it's at least 1.
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 100) maxY = 100; // Ensure a minimum scale for small earnings


    return AspectRatio(
      aspectRatio: 1.6, // Adjust aspect ratio as needed
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          maxY: maxY, // Set calculated max Y value
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // **** THIS IS THE OTHER CRITICAL PART FOR LABELS ****
                  // 'value' here is the x-value (our index 'i').
                  // We use the map to get the actual DateTime for that index.
                  final int index = value.toInt(); // Cast the double 'value' from fl_chart to int
                  final DateTime? date = indexToDateMap[index];

                  if (date == null) {
                    return const SizedBox.shrink(); // No date found for this index
                  }

                  // Format the date for the label (e.g., Mon, Tue, etc. or day number)
                  // Use 'EEE' for short day name (e.g., 'Mon'), or 'dd' for day number
                  String dayLabel = DateFormat('EEE', 'es_ES').format(date); // 'es_ES' for Spanish days

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    angle: -45 * (3.1415926535 / 180), // Tilt labels to prevent overlap
                    child: Text(
                      dayLabel,
                      style: const TextStyle(color: Colors.black, fontSize: 10),
                    ),
                  );
                },
                reservedSize: 40, // Space for labels
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Format Y-axis labels
                  return Text(
                    '\$${value.toInt()}', // Display as integer amount
                    style: const TextStyle(color: Colors.black, fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false, // Usually no vertical grid lines for bar charts
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final DateTime? date = indexToDateMap[group.x];
                if (date == null) return null;
                return BarTooltipItem(
                  '${DateFormat('MMM dd, yyyy', 'es_ES').format(date)}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '\$${rod.toY.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}