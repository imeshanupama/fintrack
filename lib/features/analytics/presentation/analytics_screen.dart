import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../categories/presentation/category_provider.dart';
import 'analytics_provider.dart';
import 'widgets/spending_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _showIncome = false;
  String _period = 'week'; // 'week', 'month', 'year'

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    final primaryColor = Theme.of(context).primaryColor;

    // Define colors
    final incomeColor = Colors.green;
    final expenseColor = Colors.redAccent;
    final activeColor = _showIncome ? incomeColor : expenseColor;

    // Use dynamic maps based on period and type
    Map<String, double> breakdownData;
    Map<int, double> chartData;
    
    // Select Data Source
    if (_showIncome) {
      if (_period == 'year') {
        breakdownData = analytics.incomeYearlyCategory;
        chartData = analytics.incomeYearlyChart;
      } else if (_period == 'month') {
        breakdownData = analytics.incomeMonthlyCategory;
        chartData = analytics.incomeMonthlyChart;
      } else {
        breakdownData = analytics.incomeWeeklyCategory;
        chartData = analytics.incomeWeeklyChart;
      }
    } else {
      if (_period == 'year') {
        breakdownData = analytics.yearlyCategorySpending;
        chartData = analytics.yearlyChartData;
      } else if (_period == 'month') {
        breakdownData = analytics.monthlyCategorySpending;
        chartData = analytics.monthlyChartData;
      } else {
        breakdownData = analytics.weeklyCategorySpending;
        chartData = analytics.weeklyChartData;
      }
    }

    final title = _showIncome ? 'Income' : 'Expense';
    String periodTitle = 'Weekly';
    if (_period == 'month') periodTitle = 'Monthly';
    if (_period == 'year') periodTitle = 'Yearly';

    // Pie Chart Palettes
    final expenseColors = [
      Colors.red, Colors.orange, Colors.amber, Colors.deepOrange, 
      Colors.brown, Colors.pink, Colors.purpleAccent, Colors.redAccent
    ];
    final incomeColors = [
      Colors.green, Colors.teal, Colors.lightGreen, Colors.lime, 
      Colors.cyan, Colors.blue, Colors.indigo, Colors.greenAccent
    ];
    final currentPieColors = _showIncome ? incomeColors : expenseColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.push('/calendar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showIncome ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_showIncome ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Expense',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: !_showIncome ? expenseColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showIncome ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _showIncome ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Income',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: _showIncome ? incomeColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 16),
              // Time Period Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodChip('Week', 'week'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Month', 'month'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Year', 'year'),
                ],
              ),
              const SizedBox(height: 24),
            
            Text(
              '$periodTitle $title',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SpendingBarChart(spending: chartData, color: activeColor, period: _period),
            const SizedBox(height: 40),
            Text(
              '$title Breakdown',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (breakdownData.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No data currently available"),
              ))
            else
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: breakdownData.entries.map((e) {
                      // Lookup Category
                      final allCategories = ref.watch(categoryProvider);
                      final category = allCategories.firstWhere(
                        (c) => c.id == e.key, 
                        orElse: () => allCategories.firstWhere((c) => c.name == 'Others', orElse: () => allCategories.first),
                      );

                      return PieChartSectionData(
                        color: Color(category.colorValue),
                        value: e.value,
                        title: '${category.name}\n\$${e.value.toStringAsFixed(0)}',
                        radius: 50,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
