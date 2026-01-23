import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SpendingLineChart extends StatelessWidget {
  final Map<int, double> spending;
  final Color? color;
  final String period; // 'week', 'month', 'year'
  final bool showGradient;
  final Map<int, double>? comparisonData; // Optional second line for comparison

  const SpendingLineChart({
    super.key,
    required this.spending,
    this.color,
    this.period = 'week',
    this.showGradient = true,
    this.comparisonData,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;

    // Determine chart configuration
    int itemCount;
    double Function(int) getKey;
    String Function(int) getLabel;

    if (period == 'year') {
      itemCount = 12;
      getKey = (index) => (index + 1).toDouble();
      getLabel = (index) => DateFormat('MMM').format(DateTime(2024, index + 1, 1));
    } else if (period == 'month') {
      itemCount = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
      getKey = (index) => (index + 1).toDouble();
      getLabel = (index) => (index + 1).toString();
    } else {
      // Week (Default)
      itemCount = 7;
      getKey = (index) => (6 - index).toDouble();
      getLabel = (index) {
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        return DateFormat('E').format(date);
      };
    }

    // Find max for Y axis
    double maxY = 100;
    final allValues = [
      ...spending.values,
      if (comparisonData != null) ...comparisonData!.values,
    ];
    if (allValues.isNotEmpty) {
      final max = allValues.fold(0.0, (prev, curr) => curr > prev ? curr : prev);
      if (max > maxY) maxY = max * 1.2;
    }

    // Create spots for main line
    final spots = List.generate(itemCount, (index) {
      final key = getKey(index).toInt();
      return FlSpot(index.toDouble(), spending[key] ?? 0);
    });

    // Create spots for comparison line if provided
    final comparisonSpots = comparisonData != null
        ? List.generate(itemCount, (index) {
            final key = getKey(index).toInt();
            return FlSpot(index.toDouble(), comparisonData![key] ?? 0);
          })
        : null;

    return AspectRatio(
      aspectRatio: period == 'month' ? 1.2 : 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= itemCount) return const SizedBox.shrink();

                  // Optimize labels for Month (show every 5th)
                  if (period == 'month' && (index + 1) % 5 != 0) {
                    return const SizedBox.shrink();
                  }

                  // Optimize labels for Year (show every other month)
                  if (period == 'year' && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      getLabel(index),
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 5,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '\$${value.toInt()}',
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (itemCount - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final label = barSpot.barIndex == 0 ? 'Current' : 'Previous';
                  return LineTooltipItem(
                    '$label\n\$${barSpot.y.toStringAsFixed(0)}',
                    GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Main line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: showGradient
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    )
                  : BarAreaData(show: false),
            ),
            // Comparison line (if provided)
            if (comparisonSpots != null)
              LineChartBarData(
                spots: comparisonSpots,
                isCurved: true,
                color: Colors.grey.shade400,
                barWidth: 2,
                isStrokeCapRound: true,
                dashArray: [5, 5],
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: Colors.grey.shade400,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}
