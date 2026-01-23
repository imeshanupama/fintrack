import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MonthlyComparisonChart extends StatelessWidget {
  final Map<int, double> currentPeriod;
  final Map<int, double> previousPeriod;
  final String period; // 'week', 'month', 'year'
  final Color currentColor;
  final Color previousColor;

  const MonthlyComparisonChart({
    super.key,
    required this.currentPeriod,
    required this.previousPeriod,
    this.period = 'month',
    this.currentColor = Colors.blue,
    this.previousColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    // Determine chart configuration
    int itemCount;
    String Function(int) getLabel;

    if (period == 'year') {
      itemCount = 12;
      getLabel = (index) => DateFormat('MMM').format(DateTime(2024, index + 1, 1))[0];
    } else if (period == 'month') {
      itemCount = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
      getLabel = (index) => (index + 1).toString();
    } else {
      // Week (Default)
      itemCount = 7;
      getLabel = (index) {
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        return DateFormat('E').format(date)[0];
      };
    }

    // Find max for Y axis
    double maxY = 100;
    final allValues = [
      ...currentPeriod.values,
      ...previousPeriod.values,
    ];
    if (allValues.isNotEmpty) {
      final max = allValues.fold(0.0, (prev, curr) => curr > prev ? curr : prev);
      if (max > maxY) maxY = max * 1.2;
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Current', currentColor),
            const SizedBox(width: 20),
            _buildLegendItem('Previous', previousColor),
          ],
        ),
        const SizedBox(height: 20),
        
        // Chart
        AspectRatio(
          aspectRatio: period == 'month' ? 1.0 : 1.5,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Current' : 'Previous';
                    return BarTooltipItem(
                      '$label\n\$${rod.toY.toStringAsFixed(0)}',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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
                            fontSize: 11,
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
                final key = index + 1;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    // Current period bar
                    BarChartRodData(
                      toY: currentPeriod[key] ?? 0,
                      color: currentColor,
                      width: period == 'month' ? 3 : 12,
                      borderRadius: BorderRadius.circular(period == 'month' ? 2 : 4),
                    ),
                    // Previous period bar
                    BarChartRodData(
                      toY: previousPeriod[key] ?? 0,
                      color: previousColor,
                      width: period == 'month' ? 3 : 12,
                      borderRadius: BorderRadius.circular(period == 'month' ? 2 : 4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
