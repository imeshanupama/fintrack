import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../categories/presentation/category_provider.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  final Map<String, double> categoryData;
  final bool isDonut;
  final bool showLegend;
  final List<Color> colors;

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    this.isDonut = true,
    this.showLegend = true,
    this.colors = const [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.deepOrange,
      Colors.brown,
      Colors.pink,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.blue,
      Colors.teal,
    ],
  });

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    final allCategories = ref.watch(categoryProvider);
    final total = widget.categoryData.values.fold(0.0, (sum, val) => sum + val);

    // Sort by value descending
    final sortedEntries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Pie Chart
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: widget.isDonut ? 50 : 0,
              sections: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final isTouched = index == touchedIndex;
                final radius = isTouched ? 60.0 : 50.0;
                final fontSize = isTouched ? 14.0 : 12.0;

                // Lookup Category
                final category = allCategories.firstWhere(
                  (c) => c.id == data.key,
                  orElse: () => allCategories.firstWhere(
                    (c) => c.name == 'Others',
                    orElse: () => allCategories.first,
                  ),
                );

                final percentage = (data.value / total * 100).toStringAsFixed(1);

                return PieChartSectionData(
                  color: Color(category.colorValue),
                  value: data.value,
                  title: isTouched ? '$percentage%' : '',
                  radius: radius,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Legend
        if (widget.showLegend) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;

              final category = allCategories.firstWhere(
                (c) => c.id == data.key,
                orElse: () => allCategories.firstWhere(
                  (c) => c.name == 'Others',
                  orElse: () => allCategories.first,
                ),
              );

              final percentage = (data.value / total * 100).toStringAsFixed(1);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    touchedIndex = touchedIndex == index ? -1 : index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: touchedIndex == index
                        ? Color(category.colorValue).withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: touchedIndex == index
                          ? Color(category.colorValue)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(category.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.name,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: touchedIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($percentage%)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: touchedIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
