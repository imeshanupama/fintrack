import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SpendingBarChart extends StatelessWidget {
  final Map<int, double> spending;
  final Color? color;
  final String period; // 'week', 'month', 'year'

  const SpendingBarChart({
    super.key, 
    required this.spending, 
    this.color,
    this.period = 'week',
  });

  @override
  Widget build(BuildContext context) {
    // Determine chart configuration
    int itemCount;
    double Function(int) getKey; // Maps index (0..N) to spending key
    String Function(int) getLabel;
    
    if (period == 'year') {
      itemCount = 12; // 12 Months
      getKey = (index) => (index + 1).toDouble(); // Key is 1..12
      getLabel = (index) => DateFormat('MMM').format(DateTime(2024, index + 1, 1))[0];
    } else if (period == 'month') {
      itemCount = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
      getKey = (index) => (index + 1).toDouble(); // Key is 1..31
      getLabel = (index) => (index + 1).toString();
    } else {
      // Week (Default)
      itemCount = 7;
      getKey = (index) => (6 - index).toDouble(); // Key is 6..0 (days ago)
      getLabel = (index) {
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        return DateFormat('E').format(date)[0];
      };
    }

    // Find max for Y axis
    double maxY = 100;
    if (spending.isNotEmpty) {
      final max = spending.values.fold(0.0, (prev, curr) => curr > prev ? curr : prev);
      if (max > maxY) maxY = max * 1.2;
    }

    return AspectRatio(
      aspectRatio: period == 'month' ? 1.2 : 1.7, // Taller for month (many bars)
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
               getTooltipColor: (_) => Colors.blueGrey,
               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                   '\$${rod.toY.toStringAsFixed(0)}',
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 );
               },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= itemCount) return const SizedBox.shrink();
                  
                  // Optimize labels for Month (show every 5th)
                  if (period == 'month' && (index + 1) % 5 != 0) {
                     return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      getLabel(index),
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(itemCount, (index) {
             final key = getKey(index).toInt();
             return BarChartGroupData(
               x: index,
               barRods: [
                   BarChartRodData(
                   toY: spending[key] ?? 0,
                   color: color ?? Theme.of(context).primaryColor,
                   width: period == 'month' ? 4 : 16, // Thinner bars for month
                   borderRadius: BorderRadius.circular(period == 'month' ? 2 : 4),
                   backDrawRodData: BackgroundBarChartRodData(
                     show: true,
                     toY: maxY,
                     color: Colors.grey.withOpacity(0.1),
                   ),
                 ),
               ],
             );
          }),
        ),
      ),
    );
  }
}
